import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import '../../core/config/game_config.dart';
import '../../data/audio_service.dart';
import '../../data/net/online_session.dart';
import '../../domain/engine/bot_engine.dart';
import '../../domain/engine/jackaroo_engine.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/move.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/position.dart';
import '../../domain/entities/rules.dart';

enum Phase {
  cover, // "pass the device" screen between human turns
  pickCard,
  pickMarble,
  pickTarget,
  pickSecondMarble,
  pickSecondTarget,
  animating,
  botTurn,
  over,
}

/// A highlighted destination: the owner seat + encoded position, so the
/// board can place it with the same geometry used for marbles.
class Target {
  final int seat;
  final int pos;
  const Target(this.seat, this.pos);

  @override
  bool operator ==(Object other) => other is Target && other.seat == seat && other.pos == pos;
  @override
  int get hashCode => seat * 1000 + pos;
}

/// Drives one match: owns the engine, exposes reactive UI state, and turns
/// taps on cards / marbles / cells into engine moves.
class GameController extends GetxController {
  final List<PlayerSlot> players;
  final RuleSet rules;
  final bool hideHands;
  final AudioService? audio;

  /// Non-null when this match is played over the network.
  final OnlineSession? online;

  late GameState state;
  late JackarooEngine engine;
  late BotEngine bot;

  GameController({
    required this.players,
    required this.rules,
    required this.hideHands,
    this.audio,
    this.online,
  });

  // ── reactive UI state ─────────────────────────────────────────────────
  final phase = Phase.pickCard.obs;
  final tick = 0.obs; // bumped whenever board/hand should repaint
  final selectedCard = RxnInt();
  final selectedMarble = Rxn<MarbleRef>();
  final highlightMarbles = <MarbleRef>{}.obs;
  final targets = <Target>[].obs;

  /// Absolute track holes lit in the mover's colour for the current options.
  final pathCells = <int>{}.obs;
  final lastPlayed = RxnInt();
  final message = ''.obs;

  /// Transient banner (card powers), cleared automatically.
  final notice = ''.obs;

  /// The 10 / Queen power available for the selected card, if any.
  final specialMove = Rxn<Move>();

  /// Marbles moved by the last bot / remote move, ringed until the next move.
  final lastMoved = <MarbleRef>{}.obs;
  final winnerTeam = RxnInt();

  /// Where each marble is drawn (lags the engine during animations).
  final Map<MarbleRef, int> displayPos = {};

  List<Move> _moves = [];
  List<Move> _splitPending = [];
  bool _swapMode = false;
  bool _disposed = false;

  int get turn => state.turn;
  PlayerSlot get current => players[turn];
  bool get isOnline => online != null;
  bool get isHost => online?.isHost ?? true;

  /// Seat whose cards this device shows: mine online, the current one offline.
  int get viewSeat => online?.mySeat ?? turn;

  /// Whether taps from this device may act for [seat].
  bool isLocalSeat(int seat) =>
      online == null ? !players[seat].isBot : seat == online!.mySeat;

  int _seq = 0;
  bool get mustDiscard =>
      _moves.isNotEmpty && _moves.every((m) => m.kind == MoveKind.discard);
  int get humanCount => players.where((p) => !p.isBot).length;

  bool get selecting =>
      phase.value == Phase.pickCard ||
      phase.value == Phase.pickMarble ||
      phase.value == Phase.pickTarget ||
      phase.value == Phase.pickSecondMarble ||
      phase.value == Phase.pickSecondTarget;

  Set<int> get playableCards =>
      _moves.where((m) => m.kind != MoveKind.discard).map((m) => m.cardId).toSet();

  @override
  void onInit() {
    super.onInit();
    newGame();
    final o = online;
    if (o != null) {
      if (o.isHost) {
        o.onIntents(_onIntent);
      } else {
        o.onMoves(_onRemoteMove);
      }
    }
  }

  @override
  void onClose() {
    _disposed = true;
    online?.dispose();
    super.onClose();
  }

  void newGame() {
    final snap = online?.initialState;
    if (snap != null && snap.isNotEmpty) {
      state = GameState.fromJson(snap);
      engine = JackarooEngine(state);
      bot = BotEngine(engine);
      _seq = online!.initialSeq;
    } else {
      state = GameState.fresh(players, rules);
      engine = JackarooEngine(state);
      bot = BotEngine(engine);
      engine.startGame();
      _seq = 0;
      if (online?.isHost ?? false) {
        online!.publishState({'seq': _seq, 'state': state.toJson()});
      }
    }
    for (var s = 0; s < GameConfig.seats; s++) {
      for (var i = 0; i < GameConfig.marblesPerPlayer; i++) {
        displayPos[MarbleRef(s, i)] = Pos.base;
      }
    }
    winnerTeam.value = null;
    lastPlayed.value = null;
    audio?.play(Sfx.deal);
    _beginTurn();
  }

  // ── turn flow ─────────────────────────────────────────────────────────

  void _beginTurn() {
    if (_disposed) return;
    _resetSelection();
    if (state.isOver) {
      winnerTeam.value = state.winnerTeam;
      phase.value = Phase.over;
      audio?.play(Sfx.win);
      return;
    }
    _moves = engine.legalMoves(turn);
    tick.value++;
    if (current.isBot) {
      phase.value = Phase.botTurn;
      message.value = 'bot_thinking'.trParams({'name': current.name});
      if (isHost) Future.delayed(GameConfig.botThink * GameConfig.botSlow, _botPlay);
    } else if (!isLocalSeat(turn)) {
      phase.value = Phase.botTurn; // remote human: just wait
      message.value = 'waiting_for'.trParams({'name': current.name});
    } else if (hideHands && !isOnline && humanCount > 1) {
      phase.value = Phase.cover;
      message.value = '';
    } else {
      _startHumanTurn();
    }
  }

  void reveal() {
    if (phase.value == Phase.cover) _startHumanTurn();
  }

  void _startHumanTurn() {
    phase.value = Phase.pickCard;
    message.value = mustDiscard
        ? 'no_moves'.tr
        : 'your_turn'.trParams({'name': current.name});
  }

  void _botPlay() {
    if (_disposed || state.isOver) return;
    final mv = bot.choose(turn, current.level);
    _apply(mv);
  }

  void _resetSelection() {
    pathCells.clear();
    specialMove.value = null;
    selectedCard.value = null;
    selectedMarble.value = null;
    highlightMarbles.clear();
    targets.clear();
    _splitPending = [];
    _swapMode = false;
  }

  void cancelSelection() {
    if (!selecting) return;
    _resetSelection();
    _startHumanTurn();
  }

  // ── taps ──────────────────────────────────────────────────────────────

  /// First tap selects the card and lights every option on the board;
  /// a second tap on the same card plays it when it has exactly one option
  /// (or burns it when nothing can be played).
  void tapCard(int cardId) {
    if (!selecting) return;
    final forCard = _moves.where((m) => m.cardId == cardId).toList();
    if (forCard.isEmpty) return;
    if (selectedCard.value == cardId) {
      if (mustDiscard) {
        message.value = 'discarded'.trParams({'name': current.name});
        _apply(forCard.first);
      } else if (forCard.length == 1 && forCard.first.kind != MoveKind.split) {
        _apply(forCard.first);
      } else if (specialMove.value != null && highlightMarbles.isEmpty) {
        _apply(specialMove.value!);
      } else {
        message.value = 'pick_target'.tr;
      }
      return;
    }
    audio?.play(Sfx.card);
    _resetSelection();
    selectedCard.value = cardId;
    if (mustDiscard) {
      phase.value = Phase.pickMarble;
      message.value = 'tap_again_discard'.tr;
      return;
    }
    highlightMarbles.assignAll(
        forCard.where((m) => m.marble != null).map((m) => m.marble!));
    specialMove.value = forCard.firstWhereOrNull(
        (m) => m.kind == MoveKind.forceDiscard || m.kind == MoveKind.steal);
    // Light every reachable destination and the paths to them.
    targets.assignAll(forCard
        .where((m) => m.marble != null && m.kind != MoveKind.swap)
        .map((m) => Target(m.marble!.seat, m.to))
        .toSet());
    pathCells.addAll(forCard.expand(engine.pathCells));
    phase.value = Phase.pickMarble;
    final single = forCard.length == 1 && forCard.first.kind != MoveKind.split;
    message.value = single
        ? 'tap_again_play'.tr
        : specialMove.value == null
            ? 'pick_target'.tr
            : (highlightMarbles.isEmpty ? 'pick_power'.tr : 'pick_action'.tr);
  }

  /// Tapping the felt (no marble / target) clears the selection.
  void tapBackground() {
    if (selectedCard.value != null) cancelSelection();
  }

  /// Plays the selected card's power (10 → force discard, Q → steal).
  void playSpecial() {
    final m = specialMove.value;
    if (m == null || !selecting) return;
    _apply(m);
  }

  Timer? _noticeTimer;

  void _showEffect(CardEffect e) {
    final who = players[e.seat].name, victim = players[e.victim].name;
    notice.value = e.kind == MoveKind.steal
        ? 'effect_steal'.trParams({'name': who, 'victim': victim})
        : 'effect_discard'.trParams({'name': who, 'victim': victim});
    audio?.play(Sfx.swap);
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(milliseconds: 3200), () {
      if (!_disposed) notice.value = '';
    });
  }

  List<Move> get _cardMoves =>
      _moves.where((m) => m.cardId == selectedCard.value).toList();

  void tapMarble(MarbleRef ref) {
    switch (phase.value) {
      case Phase.pickMarble:
        if (highlightMarbles.contains(ref)) _selectMarble(ref);
      case Phase.pickTarget:
        if (_swapMode) {
          if (highlightMarbles.contains(ref)) {
            final mv = _cardMoves.firstWhere((m) =>
                m.kind == MoveKind.swap &&
                m.marble == selectedMarble.value &&
                m.marble2 == ref);
            _apply(mv);
          }
          return;
        }
        // Tapping a marble that sits on a target cell = capture there.
        final t = _targetUnder(ref);
        if (t != null) {
          tapTarget(t);
        } else if (_cardMoves.any((m) => m.marble == ref)) {
          _selectMarble(ref);
        }
      case Phase.pickSecondMarble:
        if (highlightMarbles.contains(ref)) _selectSecondMarble(ref);
      case Phase.pickSecondTarget:
        final t = _targetUnder(ref);
        if (t != null) {
          tapTarget(t);
        } else if (_splitPending.any((m) => m.marble2 == ref)) {
          _selectSecondMarble(ref);
        }
      default:
        break;
    }
  }

  Target? _targetUnder(MarbleRef ref) {
    final p = displayPos[ref]!;
    if (!Pos.isTrack(p)) return null;
    final abs = Pos.abs(ref.seat, p);
    for (final t in targets) {
      if (Pos.isTrack(t.pos) && Pos.abs(t.seat, t.pos) == abs) return t;
    }
    return null;
  }

  void _selectMarble(MarbleRef ref) {
    selectedMarble.value = ref;
    final mine = _cardMoves.where((m) => m.marble == ref).toList();
    pathCells
      ..clear()
      ..addAll(mine.expand(engine.pathCells));
    if (mine.first.kind == MoveKind.swap) {
      _swapMode = true;
      highlightMarbles.assignAll(mine.map((m) => m.marble2!));
      targets.clear();
      phase.value = Phase.pickTarget;
      message.value = 'pick_swap_target'.tr;
      return;
    }
    _swapMode = false;
    final ts = mine.map((m) => Target(ref.seat, m.to)).toSet().toList();
    if (ts.length == 1 && mine.every((m) => m.kind != MoveKind.split)) {
      _apply(mine.first);
      return;
    }
    highlightMarbles
      ..clear()
      ..addAll(_cardMoves.map((m) => m.marble!));
    targets.assignAll(ts);
    phase.value = Phase.pickTarget;
    message.value = 'pick_target'.tr;
  }

  void tapTarget(Target t) {
    if (phase.value == Phase.pickMarble && selectedMarble.value == null) {
      // Destination tapped straight after picking the card: resolve the
      // marble from the destination when it is unambiguous.
      final hits = _cardMoves
          .where((m) => m.marble != null && m.marble!.seat == t.seat && m.to == t.pos)
          .toList();
      final marbles = hits.map((m) => m.marble!).toSet();
      if (marbles.length != 1) {
        if (marbles.length > 1) message.value = 'pick_marble'.tr;
        return;
      }
      selectedMarble.value = marbles.first;
      pathCells
        ..clear()
        ..addAll(hits.expand(engine.pathCells));
      phase.value = Phase.pickTarget;
    }
    if (phase.value == Phase.pickTarget) {
      final ref = selectedMarble.value;
      if (ref == null) return;
      final hits = _cardMoves
          .where((m) => m.marble == ref && m.to == t.pos)
          .toList();
      if (hits.isEmpty) return;
      final direct = hits.where((m) => m.kind != MoveKind.split).toList();
      if (direct.isNotEmpty) {
        _apply(direct.first);
        return;
      }
      _splitPending = hits;
      final remaining = hits.first.steps2;
      highlightMarbles.assignAll(hits.map((m) => m.marble2!));
      targets.clear();
      phase.value = Phase.pickSecondMarble;
      message.value = 'pick_second_marble'.trParams({'n': '$remaining'});
    } else if (phase.value == Phase.pickSecondTarget) {
      final hit = _splitPending.where((m) => m.to2 == t.pos).toList();
      if (hit.isNotEmpty) _apply(hit.first);
    }
  }

  void _selectSecondMarble(MarbleRef ref) {
    final mine = _splitPending.where((m) => m.marble2 == ref).toList();
    if (mine.isEmpty) return;
    if (mine.length == 1) {
      _apply(mine.first);
      return;
    }
    _splitPending = mine;
    targets.assignAll(mine.map((m) => Target(ref.seat, m.to2)).toSet());
    highlightMarbles
      ..clear()
      ..add(ref);
    phase.value = Phase.pickSecondTarget;
    message.value = 'pick_second_target'.tr;
  }

  // ── applying + animation ──────────────────────────────────────────────

  Future<void> _busy = Future.value();

  /// Completes when the current move (animation included) has finished.
  /// Used by tests and by the online layer.
  Future<void> settle() => _busy;

  /// Recomputes the current turn from [state] (after an external change).
  void refreshTurn() {
    for (var s = 0; s < GameConfig.seats; s++) {
      for (var i = 0; i < GameConfig.marblesPerPlayer; i++) {
        displayPos[MarbleRef(s, i)] = state.marbles[s][i];
      }
    }
    _beginTurn();
  }

  void _apply(Move mv) {
    final o = online;
    if (o != null && !o.isHost) {
      // Client: ask the host; the move comes back on the moves topic.
      phase.value = Phase.animating;
      highlightMarbles.clear();
      targets.clear();
      o.sendIntent({'seq': _seq, 'move': mv.toJson()});
      return;
    }
    _busy = _run(mv);
  }

  /// Host: a remote player wants to play [json['move']] — validate and apply.
  void _onIntent(Map<String, dynamic> json) {
    if (_disposed || state.isOver) return;
    if (json['seq'] != _seq) return; // stale
    if (phase.value == Phase.animating) return;
    if (isLocalSeat(turn) || current.isBot) return; // not their turn
    final wanted = jsonEncode(json['move']);
    for (final m in engine.legalMoves(turn)) {
      if (jsonEncode(m.toJson()) == wanted) {
        _busy = _run(m);
        return;
      }
    }
  }

  /// Client: the host applied a move — replay it, then sync to its snapshot.
  void _onRemoteMove(Map<String, dynamic> json) {
    if (_disposed) return;
    final seq = json['seq'] as int? ?? 0;
    final snapshot = Map<String, dynamic>.from(json['state'] ?? {});
    if (seq <= _seq) return; // duplicate
    if (seq != _seq + 1 || _pendingRemote) {
      _loadSnapshot(snapshot, seq);
      return;
    }
    _seq = seq;
    _pendingRemote = true;
    _busy = _run(Move.fromJson(Map<String, dynamic>.from(json['move'])),
        snapshot: snapshot);
  }

  bool _pendingRemote = false;

  void _loadSnapshot(Map<String, dynamic> snapshot, int seq) {
    if (snapshot.isEmpty) return;
    _pendingRemote = false;
    state = GameState.fromJson(snapshot);
    engine = JackarooEngine(state);
    bot = BotEngine(engine);
    _seq = seq;
    lastPlayed.value = state.discard.isEmpty ? null : state.discard.last;
    refreshTurn();
  }

  Future<void> _run(Move mv, {Map<String, dynamic>? snapshot}) async {
    phase.value = Phase.animating;
    highlightMarbles.clear();
    targets.clear();
    lastPlayed.value = mv.cardId;
    if (mv.kind != MoveKind.discard) audio?.play(Sfx.card);
    final events = engine.apply(mv);
    final effect = engine.lastEffect;
    if (effect != null) _showEffect(effect);
    lastMoved.clear();
    tick.value++;
    final slow = isLocalSeat(mv.seat) ? 1.0 : GameConfig.botSlow;
    await _animate(mv, events, slow);
    if (_disposed) return;
    if (!isLocalSeat(mv.seat)) {
      lastMoved.addAll(events.where((e) => !e.captured).map((e) => e.marble));
    }
    if (mv.kind == MoveKind.discard) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (engine.state.round > 1 && state.hands.every((h) => h.length == 4)) {
      audio?.play(Sfx.deal);
    }
    final o = online;
    if (o != null && o.isHost) {
      _seq++;
      final snap = state.toJson();
      o.publishMove({'seq': _seq, 'move': mv.toJson(), 'state': snap});
      o.publishState({'seq': _seq, 'state': snap});
    }
    if (snapshot != null && snapshot.isNotEmpty) {
      // Client: adopt the host's exact state (covers reshuffles).
      _pendingRemote = false;
      state = GameState.fromJson(snapshot);
      engine = JackarooEngine(state);
      bot = BotEngine(engine);
      for (final e in displayPos.keys.toList()) {
        displayPos[e] = state.marbles[e.seat][e.idx];
      }
    }
    _beginTurn();
  }

  Future<void> _animate(Move mv, List<MoveEvent> events, double slow) async {
    final hop = GameConfig.marbleHop * slow;
    final step = GameConfig.marbleStep * slow;
    if (mv.kind == MoveKind.swap) {
      audio?.play(Sfx.swap);
      for (final e in events) {
        displayPos[e.marble] = e.to;
      }
      tick.value++;
      await Future.delayed(hop);
      return;
    }
    for (final e in events) {
      if (_disposed) return;
      if (e.captured) {
        displayPos[e.marble] = Pos.base;
        audio?.play(Sfx.capture);
        tick.value++;
        await Future.delayed(hop);
        continue;
      }
      if (e.path.isNotEmpty) {
        final owner = e.marble.seat;
        for (final cell in e.path) {
          displayPos[e.marble] = Pos.rel(owner, cell);
          audio?.play(Sfx.move);
          tick.value++;
          await Future.delayed(step);
        }
      }
      displayPos[e.marble] = e.to;
      if (Pos.isHome(e.to)) audio?.play(Sfx.home);
      if (Pos.isBase(e.from)) audio?.play(Sfx.move);
      tick.value++;
      await Future.delayed(hop);
    }
  }

  // ── helpers for the UI ────────────────────────────────────────────────

  List<int> handOf(int seat) => state.hands[seat];
  PlayingCard card(int id) => PlayingCard(id);
  int teamOf(int seat) => seat % 2;
  String teamName(int team) => team == 0 ? 'team_a'.tr : 'team_b'.tr;
}
