import 'dart:async';

import 'package:get/get.dart';

import '../../core/config/game_config.dart';
import '../../data/audio_service.dart';
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

  late GameState state;
  late JackarooEngine engine;
  late BotEngine bot;

  GameController({
    required this.players,
    required this.rules,
    required this.hideHands,
    this.audio,
  });

  // ── reactive UI state ─────────────────────────────────────────────────
  final phase = Phase.pickCard.obs;
  final tick = 0.obs; // bumped whenever board/hand should repaint
  final selectedCard = RxnInt();
  final selectedMarble = Rxn<MarbleRef>();
  final highlightMarbles = <MarbleRef>{}.obs;
  final targets = <Target>[].obs;
  final lastPlayed = RxnInt();
  final message = ''.obs;
  final winnerTeam = RxnInt();

  /// Where each marble is drawn (lags the engine during animations).
  final Map<MarbleRef, int> displayPos = {};

  List<Move> _moves = [];
  List<Move> _splitPending = [];
  bool _swapMode = false;
  bool _disposed = false;

  int get turn => state.turn;
  PlayerSlot get current => players[turn];
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
  }

  @override
  void onClose() {
    _disposed = true;
    super.onClose();
  }

  void newGame() {
    state = GameState.fresh(players, rules);
    engine = JackarooEngine(state);
    bot = BotEngine(engine);
    engine.startGame();
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
      Future.delayed(GameConfig.botThink, _botPlay);
    } else if (hideHands && humanCount > 1) {
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

  void tapCard(int cardId) {
    if (!selecting) return;
    if (selectedCard.value == cardId) {
      cancelSelection();
      return;
    }
    if (mustDiscard) {
      final mv = _moves.firstWhere((m) => m.cardId == cardId);
      message.value = 'discarded'.trParams({'name': current.name});
      _apply(mv);
      return;
    }
    final forCard = _moves.where((m) => m.cardId == cardId).toList();
    if (forCard.isEmpty) return;
    audio?.play(Sfx.card);
    _resetSelection();
    selectedCard.value = cardId;
    highlightMarbles.assignAll(forCard.map((m) => m.marble!));
    phase.value = Phase.pickMarble;
    message.value = 'pick_marble'.tr;
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

  Future<void> _apply(Move mv) async {
    phase.value = Phase.animating;
    highlightMarbles.clear();
    targets.clear();
    lastPlayed.value = mv.cardId;
    if (mv.kind != MoveKind.discard) audio?.play(Sfx.card);
    final events = engine.apply(mv);
    tick.value++;
    await _animate(mv, events);
    if (_disposed) return;
    if (mv.kind == MoveKind.discard) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (engine.state.round > 1 && state.hands.every((h) => h.length == 4)) {
      audio?.play(Sfx.deal);
    }
    _beginTurn();
  }

  Future<void> _animate(Move mv, List<MoveEvent> events) async {
    if (mv.kind == MoveKind.swap) {
      audio?.play(Sfx.swap);
      for (final e in events) {
        displayPos[e.marble] = e.to;
      }
      tick.value++;
      await Future.delayed(GameConfig.marbleHop);
      return;
    }
    for (final e in events) {
      if (_disposed) return;
      if (e.captured) {
        displayPos[e.marble] = Pos.base;
        audio?.play(Sfx.capture);
        tick.value++;
        await Future.delayed(GameConfig.marbleHop);
        continue;
      }
      if (e.path.isNotEmpty) {
        final owner = e.marble.seat;
        for (final cell in e.path) {
          displayPos[e.marble] = Pos.rel(owner, cell);
          audio?.play(Sfx.move);
          tick.value++;
          await Future.delayed(GameConfig.marbleStep);
        }
      }
      displayPos[e.marble] = e.to;
      if (Pos.isHome(e.to)) audio?.play(Sfx.home);
      if (Pos.isBase(e.from)) audio?.play(Sfx.move);
      tick.value++;
      await Future.delayed(GameConfig.marbleHop);
    }
  }

  // ── helpers for the UI ────────────────────────────────────────────────

  List<int> handOf(int seat) => state.hands[seat];
  PlayingCard card(int id) => PlayingCard(id);
  int teamOf(int seat) => seat % 2;
  String teamName(int team) => team == 0 ? 'team_a'.tr : 'team_b'.tr;
}
