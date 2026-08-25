import 'dart:math';

import '../../core/config/game_config.dart';
import '../entities/card.dart';
import '../entities/game_state.dart';
import '../entities/move.dart';
import '../entities/player.dart';
import '../entities/position.dart';
import 'jackaroo_engine.dart';

/// Heuristic computer player. Scores every legal move and picks the best
/// (with noise on the easier levels).
class BotEngine {
  final JackarooEngine engine;
  final Random rng;

  BotEngine(this.engine, {int? seed}) : rng = Random(seed);

  GameState get s => engine.state;

  Move choose(int seat, BotLevel level) {
    final moves = engine.legalMoves(seat);
    assert(moves.isNotEmpty);
    if (level == BotLevel.easy && rng.nextDouble() < 0.5) {
      return moves[rng.nextInt(moves.length)];
    }
    Move? best;
    var bestScore = double.negativeInfinity;
    for (final m in moves) {
      var sc = score(seat, m, level);
      if (level != BotLevel.hard) sc += rng.nextDouble() * 6;
      if (sc > bestScore) {
        bestScore = sc;
        best = m;
      }
    }
    return best!;
  }

  static int progress(int pos) {
    if (Pos.isBase(pos)) return 0;
    if (Pos.isHome(pos)) return GameConfig.trackLength + Pos.homeIndex(pos) + 4;
    return pos + 1;
  }

  double score(int seat, Move m, BotLevel level) {
    final team = seat % 2;
    if (m.kind == MoveKind.forceDiscard) {
      // Costs the victim a card and a turn; better when they hold few cards.
      return 9.0 + (4 - s.hands[(seat + 1) % 4].length) * 2;
    }
    if (m.kind == MoveKind.steal) return 12.0;
    if (m.kind == MoveKind.discard) {
      // Keep the flexible cards; burn plain numbers first.
      const keep = {1: 8, 13: 8, 11: 5, 7: 4, 5: 3, 4: 3};
      return -100.0 - (keep[PlayingCard(m.cardId).rank] ?? 0);
    }

    // Simulate to compare team progress before / after.
    final before = _copy(s.marbles);
    final sim = GameState(
      players: s.players,
      rules: s.rules,
      marbles: _copy(s.marbles),
      hands: s.hands.map((h) => List<int>.from(h)).toList(),
      deck: List<int>.from(s.deck),
      discard: List<int>.from(s.discard),
      turn: s.turn,
    );
    final simEngine = JackarooEngine(sim);
    final events = simEngine.apply(m);

    double sc = 0;
    for (final e in events) {
      if (e.captured) {
        sc += e.marble.seat % 2 == team ? -28 : 32;
      }
    }
    for (var st = 0; st < GameConfig.seats; st++) {
      final sign = st % 2 == team ? 1.0 : -0.7;
      for (var i = 0; i < GameConfig.marblesPerPlayer; i++) {
        final b = before[st][i], a = sim.marbles[st][i];
        if (b == a) continue;
        sc += sign * (progress(a) - progress(b)) * 0.6;
        if (st % 2 == team) {
          if (Pos.isHome(a) && !Pos.isHome(b)) sc += 22;
          if (Pos.isBase(b) && a == 0) sc += 18;
          if (a == 0) sc += 4; // resting on own entry = safe
          if (b == 0 && a != 0) sc -= 3;
          if (level == BotLevel.hard && Pos.isTrack(a)) {
            sc -= _threat(sim, st, i) * 6;
          }
        }
      }
    }
    if (m.kind == MoveKind.swap) sc += 2;
    return sc;
  }

  /// Number of enemy marbles sitting 1–13 cells behind this marble.
  int _threat(GameState g, int seat, int idx) {
    final abs = Pos.abs(seat, g.marbles[seat][idx]);
    var n = 0;
    for (var st = 0; st < GameConfig.seats; st++) {
      if (st % 2 == seat % 2) continue;
      for (var i = 0; i < GameConfig.marblesPerPlayer; i++) {
        final p = g.marbles[st][i];
        if (!Pos.isTrack(p)) continue;
        final d = (abs - Pos.abs(st, p) + GameConfig.trackLength) %
            GameConfig.trackLength;
        if (d >= 1 && d <= 13) n++;
      }
    }
    return n;
  }

  static List<List<int>> _copy(List<List<int>> m) =>
      m.map((r) => List<int>.from(r)).toList();
}
