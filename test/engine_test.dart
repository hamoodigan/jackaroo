import 'package:flutter_test/flutter_test.dart';
import 'package:jackaroo/core/config/game_config.dart';
import 'package:jackaroo/domain/engine/bot_engine.dart';
import 'package:jackaroo/domain/engine/jackaroo_engine.dart';
import 'package:jackaroo/domain/entities/game_state.dart';
import 'package:jackaroo/domain/entities/move.dart';
import 'package:jackaroo/domain/entities/player.dart';
import 'package:jackaroo/domain/entities/position.dart';
import 'package:jackaroo/domain/entities/rules.dart';

// Card ids: rank = id % 13 + 1 (spades suit for id < 13).
const ace = 0, two = 1, four = 3, five = 4, six = 5, seven = 6, ten = 9, jack = 10, queen = 11, king = 12;

GameState fresh({RuleSet rules = const RuleSet()}) => GameState.fresh(
      List.generate(4, (i) => PlayerSlot(seat: i, name: 'P$i')),
      rules,
    );

JackarooEngine engineWith(GameState s) => JackarooEngine(s, seed: 1);

void main() {
  test('geometry: abs/rel round-trip and entry cells are distinct', () {
    final entries = List.generate(4, Pos.entryCell).toSet();
    expect(entries.length, 4);
    for (var s = 0; s < 4; s++) {
      for (var r = 0; r < GameConfig.trackLength; r++) {
        expect(Pos.rel(s, Pos.abs(s, r)), r);
      }
    }
  });

  test('startGame deals 4 cards each from a 52-card deck', () {
    final s = fresh();
    engineWith(s).startGame();
    expect(s.hands.every((h) => h.length == 4), isTrue);
    expect(s.deck.length, 52 - 16);
    expect(s.round, 1);
  });

  test('ace and king exit a marble; numbers cannot', () {
    final s = fresh();
    s.hands[0] = [ace, king, two];
    final moves = engineWith(s).legalMoves(0);
    final exits = moves.where((m) => m.kind == MoveKind.exitBase).toList();
    expect(exits.length, 2);
    expect(moves.where((m) => m.cardId == two), isEmpty);
  });

  test('no legal move → discard options for every card', () {
    final s = fresh();
    s.hands[0] = [two, four];
    final moves = engineWith(s).legalMoves(0);
    expect(moves.length, 2);
    expect(moves.every((m) => m.kind == MoveKind.discard), isTrue);
  });

  test('advance captures an opponent and sends it to base', () {
    final s = fresh();
    s.marbles[0][0] = 3;
    s.marbles[1][0] = Pos.rel(1, Pos.abs(0, 5)); // opponent 2 cells ahead
    s.hands[0] = [two];
    final e = engineWith(s);
    final mv = e.legalMoves(0).single;
    final events = e.apply(mv);
    expect(s.marbles[0][0], 5);
    expect(s.marbles[1][0], Pos.base);
    expect(events.any((ev) => ev.captured), isTrue);
    expect(s.captures[0], 1);
    expect(s.turn, 1);
  });

  test('cannot land on own marble or pass a marble on its own entry', () {
    final s = fresh();
    s.marbles[0][0] = 3;
    s.marbles[0][1] = 5;
    s.hands[0] = [two];
    var moves = engineWith(s).movesForCard(0, two);
    // marble 0 → 5 blocked (own), marble 1 → 7 fine
    expect(moves.length, 1);
    expect(moves.single.marble, const MarbleRef(0, 1));

    // Opponent sitting on its own entry cell blocks the way.
    final s2 = fresh();
    s2.marbles[1][0] = 0; // seat 1 on its own entry (abs 28)
    s2.marbles[0][0] = Pos.rel(0, Pos.entryCell(1)) - 1; // just behind it
    s2.hands[0] = [two];
    expect(engineWith(s2).movesForCard(0, two), isEmpty);
  });

  test('back 4 from entry then forward enters home (classic trick)', () {
    final s = fresh();
    s.marbles[0][0] = 0;
    s.hands[0] = [four];
    final e = engineWith(s);
    final back = e.legalMoves(0).single;
    expect(back.kind, MoveKind.back);
    e.apply(back);
    expect(s.marbles[0][0], GameConfig.trackLength - 4);
    s.turn = 0;
    s.hands[0] = [six];
    final mv = e
        .movesForCard(0, six)
        .firstWhere((m) => Pos.isHome(m.to));
    expect(mv.to, Pos.home(3));
    e.apply(mv);
    expect(Pos.isHome(s.marbles[0][0]), isTrue);
  });

  test('home lane: exact fit, no passing own marbles', () {
    final s = fresh();
    s.marbles[0][0] = Pos.home(2);
    s.marbles[0][1] = GameConfig.homeBranch; // on the branch hole
    s.hands[0] = [five, two];
    final e = engineWith(s);
    // 5 → home index 4 does not exist; only the trip around the loop remains.
    final f = e.movesForCard(0, five);
    expect(f.single.to, 3);
    // 2 → home index 1, or continue past the base to hole 0 (own base).
    final m = e.movesForCard(0, two);
    expect(m.map((x) => x.to).toSet(), {Pos.home(1), 0});
  });

  test('jack: board rule swaps any two marbles, app rule needs own', () {
    final s = fresh();
    s.marbles[1][0] = 5;
    s.marbles[3][0] = 9;
    s.marbles[0][0] = 2;
    s.hands[0] = [jack];
    final any = engineWith(s).movesForCard(0, jack);
    // pairs (ordered): 0-1,0-3,1-0,1-3,3-0,3-1 = 6
    expect(any.length, 6);
    expect(
        any.any((m) => m.marble!.seat == 1 && m.marble2!.seat == 3), isTrue);

    final s2 = fresh(rules: const RuleSet(jackSwapAny: false));
    s2.marbles[1][0] = 5;
    s2.marbles[3][0] = 9;
    s2.marbles[0][0] = 2;
    s2.hands[0] = [jack];
    final own = engineWith(s2).movesForCard(0, jack);
    expect(own.length, 2);
    expect(own.every((m) => m.marble!.seat == 0), isTrue);
  });

  test('jack swap moves both marbles to each other\'s cells', () {
    final s = fresh();
    s.marbles[0][0] = 2;
    s.marbles[1][0] = 5;
    s.hands[0] = [jack];
    final e = engineWith(s);
    final mv = e.movesForCard(0, jack).firstWhere((m) => m.marble!.seat == 0);
    final aCell = Pos.abs(0, 2), bCell = Pos.abs(1, 5);
    e.apply(mv);
    expect(Pos.abs(0, s.marbles[0][0]), bCell);
    expect(Pos.abs(1, s.marbles[1][0]), aCell);
  });

  test('marble on its own entry cannot be swapped', () {
    final s = fresh();
    s.marbles[0][0] = 2;
    s.marbles[1][0] = 0;
    s.hands[0] = [jack];
    expect(engineWith(s).movesForCard(0, jack), isEmpty);
  });

  test('five can move an opponent marble when the rule is on', () {
    final s = fresh();
    s.marbles[1][0] = 5;
    s.hands[0] = [five];
    final on = engineWith(s).movesForCard(0, five);
    expect(on.length, 1);
    expect(on.single.marble, const MarbleRef(1, 0));
    final s2 = fresh(rules: const RuleSet(fiveMovesAny: false));
    s2.marbles[1][0] = 5;
    s2.hands[0] = [five];
    expect(engineWith(s2).movesForCard(0, five), isEmpty);
  });

  test('seven splits between two marbles', () {
    final s = fresh();
    s.marbles[0][0] = 2;
    s.marbles[0][1] = 20;
    s.hands[0] = [seven];
    final e = engineWith(s);
    final moves = e.movesForCard(0, seven);
    final splits = moves.where((m) => m.kind == MoveKind.split).toList();
    expect(splits.length, 12); // 6 splits × 2 orders
    final mv = splits.firstWhere((m) => m.steps == 3 && m.marble!.idx == 0);
    e.apply(mv);
    expect(s.marbles[0][0], 5);
    expect(s.marbles[0][1], 24);
  });

  test('king burns every marble on its path', () {
    final s = fresh();
    s.marbles[0][0] = 10;
    s.marbles[1][0] = Pos.rel(1, Pos.abs(0, 14));
    s.marbles[3][0] = Pos.rel(3, Pos.abs(0, 20));
    s.hands[0] = [king];
    final e = engineWith(s);
    final mv = e.movesForCard(0, king).firstWhere((m) => m.kind == MoveKind.advance);
    e.apply(mv);
    expect(s.marbles[0][0], 23);
    expect(s.marbles[1][0], Pos.base);
    expect(s.marbles[3][0], Pos.base);
    expect(s.captures[0], 2);
  });

  test('finished player controls partner marbles', () {
    final s = fresh();
    for (var i = 0; i < 4; i++) {
      s.marbles[0][i] = Pos.home(i);
    }
    s.marbles[2][0] = 3;
    s.hands[0] = [two];
    final mv = engineWith(s).legalMoves(0).single;
    expect(mv.marble, const MarbleRef(2, 0));
    expect(mv.to, 5);
  });

  test('team wins when all eight marbles are home', () {
    final s = fresh();
    for (var i = 0; i < 4; i++) {
      s.marbles[0][i] = Pos.home(i);
    }
    for (var i = 1; i < 4; i++) {
      s.marbles[2][i] = Pos.home(i);
    }
    s.marbles[2][0] = GameConfig.homeBranch;
    s.hands[0] = [ace];
    final e = engineWith(s);
    final mv = e.movesForCard(0, ace).firstWhere((m) => m.to == Pos.home(0));
    e.apply(mv);
    expect(s.winnerTeam, 0);
    expect(s.isOver, isTrue);
  });

  test('new round is dealt when all hands are empty', () {
    final s = fresh();
    final e = engineWith(s);
    e.startGame();
    for (var t = 0; t < 16; t++) {
      final seat = s.turn;
      final mv = e.legalMoves(seat).first;
      e.apply(mv);
    }
    expect(s.round, 2);
    expect(s.hands.every((h) => h.length == 4), isTrue);
  });

  test('json round-trip', () {
    final s = fresh();
    engineWith(s).startGame();
    s.marbles[0][0] = 7;
    final back = GameState.fromJson(s.toJson());
    expect(back.marbles[0][0], 7);
    expect(back.hands[2], s.hands[2]);
    expect(back.rules.jackSwapAny, isTrue);
  });

  test('bots can play a full game to the end', () {
    final s = GameState.fresh(
      List.generate(4, (i) => PlayerSlot(seat: i, name: 'B$i', isBot: true)),
      const RuleSet(),
    );
    final e = JackarooEngine(s, seed: 42);
    final bot = BotEngine(e, seed: 42);
    e.startGame();
    var guard = 0;
    while (!s.isOver && guard++ < 5000) {
      e.apply(bot.choose(s.turn, BotLevel.hard));
    }
    expect(s.isOver, isTrue, reason: 'game should finish within 5000 moves');
  });

  test('10: next player loses a random card and their turn', () {
    final s = fresh();
    s.hands[0] = [ten];
    s.hands[1] = [two, four, five];
    s.hands[2] = [two];
    s.hands[3] = [two];
    s.marbles[0][0] = 3;
    final e = engineWith(s);
    final moves = e.movesForCard(0, ten);
    expect(moves.any((m) => m.kind == MoveKind.advance), isTrue);
    final power = moves.singleWhere((m) => m.kind == MoveKind.forceDiscard);
    e.apply(power);
    expect(s.hands[1].length, 2);
    expect(s.discard.length, 2); // the 10 + the burned card
    expect(s.turn, 2); // seat 1 skipped
    expect(e.lastEffect!.victim, 1);
  });

  test('Queen: steals a random card and skips the next player', () {
    final s = fresh();
    s.hands[0] = [queen];
    s.hands[1] = [two, four];
    s.hands[2] = [five];
    s.hands[3] = [five];
    final e = engineWith(s);
    final power = e.movesForCard(0, queen).singleWhere((m) => m.kind == MoveKind.steal);
    e.apply(power);
    expect(s.hands[0].length, 1);
    expect(s.hands[1].length, 1);
    expect([two, four].contains(s.hands[0].single), isTrue);
    expect(s.turn, 2);
  });

  test('powers are unavailable when the next hand is empty or rule off', () {
    final s = fresh();
    s.hands[0] = [ten, queen];
    s.hands[1] = [];
    final e = engineWith(s);
    expect(e.movesForCard(0, ten).where((m) => m.kind == MoveKind.forceDiscard), isEmpty);
    expect(e.movesForCard(0, queen).where((m) => m.kind == MoveKind.steal), isEmpty);
    final s2 = fresh(rules: const RuleSet(tenSkip: false, queenSteal: false));
    s2.hands[0] = [ten, queen];
    s2.hands[1] = [two];
    final e2 = engineWith(s2);
    expect(e2.movesForCard(0, ten).where((m) => m.kind == MoveKind.forceDiscard), isEmpty);
    expect(e2.movesForCard(0, queen).where((m) => m.kind == MoveKind.steal), isEmpty);
  });

  test('a player left without cards is passed over', () {
    final s = fresh();
    s.hands[0] = [ten];
    s.hands[1] = [two];
    s.hands[2] = [];
    s.hands[3] = [two];
    final e = engineWith(s);
    e.apply(e.movesForCard(0, ten).singleWhere((m) => m.kind == MoveKind.forceDiscard));
    // seat 1 burned its only card and is skipped, seat 2 has none → seat 3
    expect(s.turn, 3);
  });

  test('at the branch hole you may enter home OR stay on the track', () {
    final s = fresh();
    s.marbles[0][0] = GameConfig.homeBranch;
    s.hands[0] = [ace];
    final moves = engineWith(s).movesForCard(0, ace);
    expect(moves.any((m) => m.to == Pos.home(0)), isTrue);
    expect(moves.any((m) => m.to == GameConfig.trackLength - 1), isTrue);
  });

  test('past the branch hole a marble goes around again', () {
    final s = fresh();
    s.marbles[0][0] = GameConfig.trackLength - 1;
    s.hands[0] = [two];
    final moves = engineWith(s).movesForCard(0, two);
    expect(moves.single.to, 1); // 75 → base (0) → 1, no lane on the way
  });

  test('40 full bot games: every move keeps the board consistent', () {
    for (var seed = 1; seed <= 40; seed++) {
      final s = GameState.fresh(
        List.generate(4, (i) => PlayerSlot(seat: i, name: 'B$i', isBot: true)),
        RuleSet(jackSwapAny: seed.isEven, canBurnPartner: seed % 3 != 0),
      );
      final e = JackarooEngine(s, seed: seed);
      final bot = BotEngine(e, seed: seed);
      e.startGame();
      var moves = 0;
      while (!s.isOver && moves < 6000) {
        final seat = s.turn;
        expect(s.hands[seat], isNotEmpty, reason: 'seed $seed: empty hand on turn');
        final legal = e.legalMoves(seat);
        final mv = bot.choose(seat, s.players[seat].level);
        expect(legal.any((m) => m.toJson().toString() == mv.toJson().toString()),
            isTrue, reason: 'seed $seed: bot chose an illegal move');
        e.apply(mv);
        moves++;
        // Invariants.
        final onTrack = <int, String>{};
        for (var st = 0; st < 4; st++) {
          expect(s.marbles[st].length, 4);
          final homes = <int>{};
          for (var i = 0; i < 4; i++) {
            final p = s.marbles[st][i];
            expect(Pos.isBase(p) || Pos.isTrack(p) || Pos.isHome(p), isTrue,
                reason: 'seed $seed move $moves: bad pos $p');
            if (Pos.isTrack(p)) {
              final cell = Pos.abs(st, p);
              expect(onTrack.containsKey(cell), isFalse,
                  reason: 'seed $seed move $moves: two marbles on hole $cell');
              onTrack[cell] = 'M$st.$i';
            }
            if (Pos.isHome(p)) {
              expect(homes.add(Pos.homeIndex(p)), isTrue,
                  reason: 'seed $seed: two marbles in one home slot');
              expect(Pos.homeIndex(p) < GameConfig.homeSize, isTrue);
            }
          }
        }
        final cards = s.deck.length +
            s.discard.length +
            s.hands.fold<int>(0, (a, h) => a + h.length);
        expect(cards, 52, reason: 'seed $seed move $moves: cards leaked');
        expect((s.deck + s.discard + s.hands.expand((h) => h).toList()).toSet().length,
            52, reason: 'seed $seed: duplicate card');
      }
      expect(s.isOver, isTrue, reason: 'seed $seed did not finish');
      final w = s.winnerTeam!;
      expect(s.allHome(w) && s.allHome(w + 2), isTrue);
    }
  });
}
