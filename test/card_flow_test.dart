// Drives every card through the REAL tap flow (card → marble → target),
// exactly as the board and hand widgets call the controller.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jackaroo/core/config/game_config.dart';
import 'package:jackaroo/domain/entities/move.dart';
import 'package:jackaroo/domain/entities/player.dart';
import 'package:jackaroo/domain/entities/position.dart';
import 'package:jackaroo/domain/entities/rules.dart';
import 'package:jackaroo/presentation/controllers/game_controller.dart';

// Spades ids: rank r → id r-1.
int card(int rank) => rank - 1;

GameController make({RuleSet rules = const RuleSet()}) {
  final c = GameController(
    players: List.generate(4, (i) => PlayerSlot(seat: i, name: 'P$i')),
    rules: rules,
    hideHands: false,
  );
  c.onInit();
  return c;
}

/// Puts seat 0 on turn with [hand] and the given marble positions.
void arrange(GameController c, List<int> hand,
    {Map<(int, int), int> marbles = const {}}) {
  for (var s = 0; s < 4; s++) {
    for (var i = 0; i < 4; i++) {
      c.state.marbles[s][i] = Pos.base;
    }
    c.state.hands[s] = [card(2)];
  }
  marbles.forEach((k, v) => c.state.marbles[k.$1][k.$2] = v);
  c.state.hands[0] = List.of(hand);
  c.state.turn = 0;
  c.refreshTurn();
}

Future<void> settle(GameController c) async {
  await c.settle();
  await Future.delayed(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() => Get.testMode = true);

  test('Ace: exit from base via tap flow', () async {
    final c = make();
    arrange(c, [card(1)]);
    c.tapCard(card(1));
    expect(c.phase.value, Phase.pickMarble);
    expect(c.highlightMarbles.length, 1); // engine offers one exit move
    c.tapMarble(const MarbleRef(0, 0));
    await settle(c);
    expect(c.state.marbles[0][0], 0);
    expect(c.state.turn, 1);
  });

  test('Ace: choose 11 over 1 via target tap', () async {
    final c = make();
    arrange(c, [card(1)], marbles: {(0, 0): 5});
    c.tapCard(card(1));
    c.tapMarble(const MarbleRef(0, 0));
    expect(c.phase.value, Phase.pickTarget);
    expect(c.targets.map((t) => t.pos).toSet(), {6, 16});
    c.tapTarget(const Target(0, 16));
    await settle(c);
    expect(c.state.marbles[0][0], 16);
  });

  test('King: moves 13 and burns marbles on the path', () async {
    final c = make();
    arrange(c, [card(13)], marbles: {
      (0, 0): 10,
      (1, 0): Pos.rel(1, Pos.abs(0, 15)),
    });
    c.tapCard(card(13));
    c.tapMarble(const MarbleRef(0, 0));
    await settle(c);
    expect(c.state.marbles[0][0], 23);
    expect(c.state.marbles[1][0], Pos.base);
    expect(c.state.captures[0], 1);
  });

  for (final rank in [2, 3, 6, 8, 9, 10, 12]) {
    test('$rank moves ${rank == 12 ? 12 : rank} steps', () async {
      final c = make();
      arrange(c, [card(rank)], marbles: {(0, 0): 0});
      c.tapCard(card(rank));
      c.tapMarble(const MarbleRef(0, 0));
      await settle(c);
      expect(c.state.marbles[0][0], rank == 12 ? 12 : rank);
    });
  }

  test('7: split 3 + 4 between two marbles', () async {
    final c = make();
    arrange(c, [card(7)], marbles: {(0, 0): 2, (0, 1): 20});
    c.tapCard(card(7));
    c.tapMarble(const MarbleRef(0, 0));
    expect(c.targets.map((t) => t.pos).toSet(), {3, 4, 5, 6, 7, 8, 9});
    c.tapTarget(const Target(0, 5));
    expect(c.phase.value, Phase.pickSecondMarble);
    expect(c.highlightMarbles, {const MarbleRef(0, 1)});
    c.tapMarble(const MarbleRef(0, 1));
    await settle(c);
    expect(c.state.marbles[0][0], 5);
    expect(c.state.marbles[0][1], 24);
  });

  test('7: full 7 on one marble', () async {
    final c = make();
    arrange(c, [card(7)], marbles: {(0, 0): 2, (0, 1): 20});
    c.tapCard(card(7));
    c.tapMarble(const MarbleRef(0, 0));
    c.tapTarget(const Target(0, 9));
    await settle(c);
    expect(c.state.marbles[0][0], 9);
    expect(c.state.marbles[0][1], 20);
  });

  test('5: moves an opponent marble 5 forward', () async {
    final c = make();
    arrange(c, [card(5)], marbles: {(1, 0): 5});
    c.tapCard(card(5));
    expect(c.highlightMarbles, {const MarbleRef(1, 0)});
    c.tapMarble(const MarbleRef(1, 0));
    await settle(c);
    expect(c.state.marbles[1][0], 10);
  });

  test('4: moves backward, wrapping behind the entry', () async {
    final c = make();
    arrange(c, [card(4)], marbles: {(0, 0): 0});
    c.tapCard(card(4));
    c.tapMarble(const MarbleRef(0, 0));
    await settle(c);
    expect(c.state.marbles[0][0], GameConfig.trackLength - 4);
  });

  test('Jack: swap own marble with an opponent (tap both)', () async {
    final c = make();
    arrange(c, [card(11)], marbles: {(0, 0): 2, (1, 0): 5});
    final a = Pos.abs(0, 2), b = Pos.abs(1, 5);
    c.tapCard(card(11));
    expect(c.highlightMarbles, {const MarbleRef(0, 0), const MarbleRef(1, 0)});
    c.tapMarble(const MarbleRef(0, 0));
    expect(c.phase.value, Phase.pickTarget);
    expect(c.highlightMarbles, {const MarbleRef(1, 0)});
    c.tapMarble(const MarbleRef(1, 0));
    await settle(c);
    expect(Pos.abs(0, c.state.marbles[0][0]), b);
    expect(Pos.abs(1, c.state.marbles[1][0]), a);
  });

  test('Jack (board rule): swap two OTHER players\' marbles', () async {
    final c = make();
    arrange(c, [card(11)], marbles: {(1, 0): 5, (3, 0): 9});
    c.tapCard(card(11));
    c.tapMarble(const MarbleRef(1, 0));
    c.tapMarble(const MarbleRef(3, 0));
    await settle(c);
    expect(Pos.abs(1, c.state.marbles[1][0]), Pos.abs(3, 9));
    expect(Pos.abs(3, c.state.marbles[3][0]), Pos.abs(1, 5));
  });

  test('Jack (app rule): cannot pick an opponent first', () async {
    final c = make(rules: const RuleSet(jackSwapAny: false));
    arrange(c, [card(11)], marbles: {(0, 0): 2, (1, 0): 5, (3, 0): 9});
    c.tapCard(card(11));
    expect(c.highlightMarbles, {const MarbleRef(0, 0)});
  });

  test('capture by tapping the enemy marble on the target cell', () async {
    final c = make();
    arrange(c, [card(1)], marbles: {
      (0, 0): 3,
      (1, 0): Pos.rel(1, Pos.abs(0, 4)),
    });
    c.tapCard(card(1));
    c.tapMarble(const MarbleRef(0, 0));
    expect(c.targets.map((t) => t.pos).toSet(), {4, 14});
    c.tapMarble(const MarbleRef(1, 0)); // sits on target 4
    await settle(c);
    expect(c.state.marbles[0][0], 4);
    expect(c.state.marbles[1][0], Pos.base);
  });

  test('no legal move: tapping a card discards it', () async {
    final c = make();
    arrange(c, [card(2), card(3)]);
    expect(c.mustDiscard, isTrue);
    c.tapCard(card(3));
    await settle(c);
    expect(c.state.hands[0], [card(2)]);
    expect(c.state.discard.contains(card(3)), isTrue);
    expect(c.state.turn, 1);
  });

  test('tapping the selected card again cancels the selection', () async {
    final c = make();
    arrange(c, [card(1)]);
    c.tapCard(card(1));
    c.tapCard(card(1));
    expect(c.phase.value, Phase.pickCard);
    expect(c.highlightMarbles, isEmpty);
  });
}
