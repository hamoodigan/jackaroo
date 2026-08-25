import 'dart:math';

import '../../core/config/game_config.dart';
import '../entities/card.dart';
import '../entities/game_state.dart';
import '../entities/move.dart';
import '../entities/position.dart';

/// Pure rules engine: builds the list of legal moves for a seat and applies
/// one, mutating [state]. No I/O, no timers, no Flutter — fully testable
/// and ready to be driven by a network layer later.
class JackarooEngine {
  final GameState state;
  final Random rng;

  JackarooEngine(this.state, {int? seed}) : rng = Random(seed);

  /// Side effect of the last applied move (10 / Queen powers), for the UI.
  CardEffect? lastEffect;

  int nextSeat(int seat) => (seat + 1) % GameConfig.seats;

  static const _track = GameConfig.trackLength;
  static const _homeSize = GameConfig.homeSize;

  // ── Dealing ────────────────────────────────────────────────────────────

  void startGame() {
    state.deck = PlayingCard.fullDeck()..shuffle(rng);
    state.discard = [];
    state.round = 0;
    deal();
  }

  bool get handsEmpty => state.hands.every((h) => h.isEmpty);

  /// Deals [GameConfig.handSize] cards to every seat, reshuffling the
  /// discard pile back in when the deck runs low.
  void deal() {
    final need = GameConfig.handSize * GameConfig.seats;
    if (state.deck.length < need) {
      state.deck.addAll(state.discard..shuffle(rng));
      state.discard = [];
      if (state.deck.length < need) {
        // Should never happen with a 52-card deck, but stay safe.
        state.deck = PlayingCard.fullDeck()..shuffle(rng);
      }
      state.deck.shuffle(rng);
    }
    for (var s = 0; s < GameConfig.seats; s++) {
      state.hands[s] = state.deck.sublist(0, GameConfig.handSize);
      state.deck = state.deck.sublist(GameConfig.handSize);
    }
    state.round++;
  }

  // ── Legal moves ────────────────────────────────────────────────────────

  /// Every legal move for [seat]. When nothing can be played the list
  /// contains one discard per card instead (the player must burn one).
  List<Move> legalMoves(int seat) {
    if (state.isOver) return const [];
    final moves = <Move>[];
    for (final card in state.hands[seat]) {
      moves.addAll(movesForCard(seat, card));
    }
    if (moves.isEmpty) {
      for (final card in state.hands[seat]) {
        moves.add(Move(seat: seat, cardId: card, kind: MoveKind.discard));
      }
    }
    return moves;
  }

  List<Move> movesForCard(int seat, int cardId) {
    final rank = PlayingCard(cardId).rank;
    final m = state.marbles;
    final out = <Move>[];
    final own = _controlled(seat);

    void add(Move? mv) {
      if (mv != null) out.add(mv);
    }

    switch (rank) {
      case 1: // Ace: exit, 1 or 11
        add(_exit(seat, cardId, m));
        for (final r in own) {
          add(_advance(seat, cardId, r, 1, m));
          add(_advance(seat, cardId, r, 11, m));
        }
      case 13: // King: exit or 13
        add(_exit(seat, cardId, m));
        for (final r in own) {
          add(_advance(seat, cardId, r, 13, m));
        }
      case 11: // Jack: swap
        out.addAll(_swaps(seat, cardId));
      case 4: // back 4
        for (final r in own) {
          add(_back(seat, cardId, r, 4, m));
        }
      case 5:
        for (final r in own) {
          add(_advance(seat, cardId, r, 5, m));
        }
        if (state.rules.fiveMovesAny) {
          for (var s = 0; s < GameConfig.seats; s++) {
            if (s == _controlledSeat(seat)) continue;
            for (var i = 0; i < GameConfig.marblesPerPlayer; i++) {
              if (Pos.isTrack(m[s][i])) {
                add(_advance(seat, cardId, MarbleRef(s, i), 5, m));
              }
            }
          }
        }
      case 7:
        for (final r in own) {
          add(_advance(seat, cardId, r, 7, m));
        }
        if (state.rules.sevenSplit) out.addAll(_splits(seat, cardId, own));
      case 10:
        for (final r in own) {
          add(_advance(seat, cardId, r, 10, m));
        }
        if (state.rules.tenSkip && state.hands[nextSeat(seat)].isNotEmpty) {
          out.add(Move(seat: seat, cardId: cardId, kind: MoveKind.forceDiscard));
        }
      case 12:
        for (final r in own) {
          add(_advance(seat, cardId, r, 12, m));
        }
        if (state.rules.queenSteal && state.hands[nextSeat(seat)].isNotEmpty) {
          out.add(Move(seat: seat, cardId: cardId, kind: MoveKind.steal));
        }
      default:
        final n = rank == 12 ? 12 : rank;
        for (final r in own) {
          add(_advance(seat, cardId, r, n, m));
        }
    }
    return out;
  }

  int _controlledSeat(int seat) => state.controlledSeat(seat);

  List<MarbleRef> _controlled(int seat) {
    final s = _controlledSeat(seat);
    return List.generate(
        GameConfig.marblesPerPlayer, (i) => MarbleRef(s, i));
  }

  bool _sameTeam(int a, int b) => a % 2 == b % 2;

  /// Whether a marble of [owner] may land on absolute [cell]. Returns the
  /// captured marble (if any) via [capture]; false when illegal.
  bool _canLand(int owner, int cell, List<List<int>> m,
      {void Function(MarbleRef)? capture}) {
    final occ = _occupant(cell, m);
    if (occ == null) return true;
    if (occ.seat == owner) return false; // own marble
    if (m[occ.seat][occ.idx] == 0) return false; // safe on its own entry
    if (!state.rules.canBurnPartner && _sameTeam(occ.seat, owner)) {
      return false;
    }
    capture?.call(occ);
    return true;
  }

  MarbleRef? _occupant(int cell, List<List<int>> m) {
    for (var s = 0; s < GameConfig.seats; s++) {
      for (var i = 0; i < GameConfig.marblesPerPlayer; i++) {
        final p = m[s][i];
        if (Pos.isTrack(p) && Pos.abs(s, p) == cell) return MarbleRef(s, i);
      }
    }
    return null;
  }

  /// True when any marble on the given absolute cells sits on its own
  /// entry cell (a "safe" marble can never be jumped over).
  bool _blocked(Iterable<int> cells, List<List<int>> m) {
    for (final c in cells) {
      final occ = _occupant(c, m);
      if (occ != null && m[occ.seat][occ.idx] == 0) return true;
    }
    return false;
  }

  Iterable<int> _forwardPath(int owner, int fromRel, int toRel) sync* {
    for (var r = fromRel + 1; r < toRel; r++) {
      yield Pos.abs(owner, r);
    }
  }

  Move? _exit(int seat, int cardId, List<List<int>> m) {
    final owner = _controlledSeat(seat);
    final idx = m[owner].indexOf(Pos.base);
    if (idx < 0) return null;
    if (!_canLand(owner, Pos.entryCell(owner), m)) return null;
    return Move(
      seat: seat,
      cardId: cardId,
      kind: MoveKind.exitBase,
      marble: MarbleRef(owner, idx),
      to: 0,
    );
  }

  Move? _advance(
      int seat, int cardId, MarbleRef ref, int n, List<List<int>> m) {
    final p = m[ref.seat][ref.idx];
    final owner = ref.seat;
    if (Pos.isBase(p)) return null;

    if (Pos.isHome(p)) {
      if (!_sameTeam(seat, owner)) return null;
      final h = Pos.homeIndex(p);
      final nh = h + n;
      if (nh >= _homeSize) return null;
      for (var k = h + 1; k <= nh; k++) {
        if (m[owner].contains(Pos.home(k))) return null;
      }
      return Move(
          seat: seat,
          cardId: cardId,
          kind: MoveKind.advance,
          marble: ref,
          steps: n,
          to: Pos.home(nh));
    }

    final r = p;
    final nr = r + n;
    if (nr < _track) {
      if (_blocked(_forwardPath(owner, r, nr), m)) return null;
      if (!_canLand(owner, Pos.abs(owner, nr), m)) return null;
      return Move(
          seat: seat,
          cardId: cardId,
          kind: MoveKind.advance,
          marble: ref,
          steps: n,
          to: nr);
    }
    // Entering the home lane.
    if (!_sameTeam(seat, owner)) return null;
    final h = nr - _track;
    if (h >= _homeSize) return null;
    if (_blocked(_forwardPath(owner, r, _track), m)) return null;
    for (var k = 0; k <= h; k++) {
      if (m[owner].contains(Pos.home(k))) return null;
    }
    return Move(
        seat: seat,
        cardId: cardId,
        kind: MoveKind.advance,
        marble: ref,
        steps: n,
        to: Pos.home(h));
  }

  Move? _back(int seat, int cardId, MarbleRef ref, int n, List<List<int>> m) {
    final p = m[ref.seat][ref.idx];
    if (!Pos.isTrack(p)) return null;
    final owner = ref.seat;
    final nr = (p - n + _track) % _track;
    final path = [for (var k = 1; k < n; k++) Pos.abs(owner, (p - k + _track) % _track)];
    if (_blocked(path, m)) return null;
    if (!_canLand(owner, Pos.abs(owner, nr), m)) return null;
    return Move(
        seat: seat,
        cardId: cardId,
        kind: MoveKind.back,
        marble: ref,
        steps: n,
        to: nr);
  }

  List<Move> _swaps(int seat, int cardId) {
    final m = state.marbles;
    final mine = _controlledSeat(seat);
    final onTrack = <MarbleRef>[];
    for (var s = 0; s < GameConfig.seats; s++) {
      for (var i = 0; i < GameConfig.marblesPerPlayer; i++) {
        final p = m[s][i];
        // Marbles on their own entry cell are protected from swaps.
        if (Pos.isTrack(p) && p != 0) onTrack.add(MarbleRef(s, i));
      }
    }
    final out = <Move>[];
    for (final a in onTrack) {
      if (!state.rules.jackSwapAny && a.seat != mine) continue;
      for (final b in onTrack) {
        if (a == b || a.seat == b.seat) continue;
        if (!state.rules.jackSwapAny && b.seat == mine) continue;
        final aAbs = Pos.abs(a.seat, m[a.seat][a.idx]);
        final bAbs = Pos.abs(b.seat, m[b.seat][b.idx]);
        out.add(Move(
          seat: seat,
          cardId: cardId,
          kind: MoveKind.swap,
          marble: a,
          to: Pos.rel(a.seat, bAbs),
          marble2: b,
          to2: Pos.rel(b.seat, aAbs),
        ));
      }
    }
    return out;
  }

  List<Move> _splits(int seat, int cardId, List<MarbleRef> own) {
    final out = <Move>[];
    for (final a in own) {
      for (var k = 1; k < 7; k++) {
        final first = _advance(seat, cardId, a, k, state.marbles);
        if (first == null) continue;
        final sim = _copy(state.marbles);
        _applyMovement(first, sim, null);
        for (final b in own) {
          if (a == b) continue;
          final second = _advance(seat, cardId, b, 7 - k, sim);
          if (second == null) continue;
          out.add(Move(
            seat: seat,
            cardId: cardId,
            kind: MoveKind.split,
            marble: a,
            steps: k,
            to: first.to,
            marble2: b,
            steps2: 7 - k,
            to2: second.to,
          ));
        }
      }
    }
    return out;
  }

  List<List<int>> _copy(List<List<int>> m) =>
      m.map((r) => List<int>.from(r)).toList();

  // ── Applying ───────────────────────────────────────────────────────────

  /// Applies [move], advances the turn and deals a new round when every
  /// hand is empty. Returns the events to animate.
  List<MoveEvent> apply(Move move) {
    final events = <MoveEvent>[];
    final s = move.seat;
    lastEffect = null;
    state.hands[s].remove(move.cardId);
    state.discard.add(move.cardId);

    if (move.kind == MoveKind.forceDiscard || move.kind == MoveKind.steal) {
      final victim = nextSeat(s);
      final hand = state.hands[victim];
      int? taken;
      if (hand.isNotEmpty) {
        taken = hand.removeAt(rng.nextInt(hand.length));
        if (move.kind == MoveKind.steal) {
          state.hands[s].add(taken);
        } else {
          state.discard.add(taken);
        }
      }
      lastEffect = CardEffect(move.kind, s, victim, taken);
      state.movesPlayed[s]++;
      _advanceTurn(s, 2); // victim loses the turn
      return events;
    }

    if (move.kind != MoveKind.discard) {
      final captures = <MarbleRef>[];
      _applyMovement(move, state.marbles, events, captures: captures);
      state.captures[s] += captures.length;
      state.movesPlayed[s]++;
      final team = state.teamOf(s);
      if (state.teamFinished(team)) state.winnerTeam = team;
    }

    if (!state.isOver) _advanceTurn(s, 1);
    return events;
  }

  /// Moves the turn [step] seats on, deals when every hand is empty, and
  /// passes over players who are out of cards (possible after a skip).
  void _advanceTurn(int from, int step) {
    state.turn = (from + step) % GameConfig.seats;
    if (handsEmpty) {
      deal();
      return;
    }
    var guard = 0;
    while (state.hands[state.turn].isEmpty && guard++ < GameConfig.seats) {
      state.turn = nextSeat(state.turn);
    }
  }

  /// Moves marbles inside [m] (either the real state or a simulation).
  void _applyMovement(Move move, List<List<int>> m, List<MoveEvent>? events,
      {List<MarbleRef>? captures}) {
    void burn(MarbleRef ref) {
      final from = m[ref.seat][ref.idx];
      m[ref.seat][ref.idx] = Pos.base;
      captures?.add(ref);
      events?.add(MoveEvent(ref, from, Pos.base, captured: true));
    }

    void place(MarbleRef ref, int to, {List<int> path = const []}) {
      final from = m[ref.seat][ref.idx];
      if (Pos.isTrack(to)) {
        final occ = _occupant(Pos.abs(ref.seat, to), m);
        if (occ != null && occ != ref) burn(occ);
      }
      m[ref.seat][ref.idx] = to;
      events?.add(MoveEvent(ref, from, to, path: path));
    }

    List<int> pathFor(MarbleRef ref, int from, int to, bool forward) {
      if (!Pos.isTrack(from)) return const [];
      final owner = ref.seat;
      final cells = <int>[];
      if (forward) {
        final end = Pos.isHome(to) ? _track - 1 : to;
        for (var r = from + 1; r <= end; r++) {
          cells.add(Pos.abs(owner, r));
        }
      } else {
        for (var k = 1; k <= move.steps; k++) {
          cells.add(Pos.abs(owner, (from - k + _track) % _track));
        }
      }
      return cells;
    }

    switch (move.kind) {
      case MoveKind.exitBase:
        place(move.marble!, 0);
      case MoveKind.advance:
        final ref = move.marble!;
        final from = m[ref.seat][ref.idx];
        final rank = PlayingCard(move.cardId).rank;
        if (rank == 13 && state.rules.kingBurnsPath && Pos.isTrack(from)) {
          final end = Pos.isHome(move.to) ? _track : move.to;
          for (final c in _forwardPath(ref.seat, from, end)) {
            final occ = _occupant(c, m);
            if (occ == null || occ.seat == ref.seat) continue;
            if (!state.rules.canBurnPartner &&
                _sameTeam(occ.seat, ref.seat)) {
              continue;
            }
            burn(occ);
          }
        }
        place(ref, move.to, path: pathFor(ref, from, move.to, true));
      case MoveKind.back:
        final ref = move.marble!;
        final from = m[ref.seat][ref.idx];
        place(ref, move.to, path: pathFor(ref, from, move.to, false));
      case MoveKind.swap:
        final a = move.marble!, b = move.marble2!;
        final fa = m[a.seat][a.idx], fb = m[b.seat][b.idx];
        m[a.seat][a.idx] = move.to;
        m[b.seat][b.idx] = move.to2;
        events?.add(MoveEvent(a, fa, move.to));
        events?.add(MoveEvent(b, fb, move.to2));
      case MoveKind.split:
        final a = move.marble!, b = move.marble2!;
        final fa = m[a.seat][a.idx];
        place(a, move.to, path: pathFor(a, fa, move.to, true));
        final fb = m[b.seat][b.idx];
        place(b, move.to2, path: pathFor(b, fb, move.to2, true));
      case MoveKind.discard:
      case MoveKind.forceDiscard:
      case MoveKind.steal:
        break;
    }
  }
}

/// What a 10 / Queen power did: who played it, who suffered, which card.
class CardEffect {
  final MoveKind kind;
  final int seat;
  final int victim;
  final int? card;
  const CardEffect(this.kind, this.seat, this.victim, this.card);
}
