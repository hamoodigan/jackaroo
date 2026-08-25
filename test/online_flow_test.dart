// Host ↔ client protocol over an in-memory broker: the two GameControllers
// stay in lock-step, clients can only act on their own turn, the host
// validates intents, and bots run on the host only.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jackaroo/data/net/online_session.dart';
import 'package:jackaroo/data/net/room_service.dart';
import 'package:jackaroo/domain/entities/move.dart';
import 'package:jackaroo/domain/entities/player.dart';
import 'package:jackaroo/domain/entities/position.dart';
import 'package:jackaroo/domain/entities/rules.dart';
import 'package:jackaroo/presentation/controllers/game_controller.dart';

/// In-memory pub/sub with retained messages, shared by all fakes.
class FakeBroker {
  final _subs = <String, List<void Function(Map<String, dynamic>)>>{};
  final retained = <String, Map<String, dynamic>>{};
  final log = <(String, Map<String, dynamic>)>[];

  void publish(String topic, Map<String, dynamic> json, bool retain) {
    log.add((topic, json));
    if (retain) retained[topic] = json;
    // Deliver asynchronously like a real network.
    for (final h in List.of(_subs[topic] ?? const [])) {
      scheduleMicrotask(() => h(json));
    }
  }

  void subscribe(String topic, void Function(Map<String, dynamic>) h) {
    _subs.putIfAbsent(topic, () => []).add(h);
    final r = retained[topic];
    if (r != null) scheduleMicrotask(() => h(r));
  }
}

class FakeRoomService extends RoomService {
  final FakeBroker broker;
  FakeRoomService(this.broker);

  @override
  bool get isConnected => true;

  @override
  Future<bool> connect() async => true;

  @override
  void subscribe(String topic, void Function(Map<String, dynamic>) handler) =>
      broker.subscribe(topic, handler);

  @override
  void publish(String topic, Map<String, dynamic> json, {bool retain = false}) =>
      broker.publish(topic, json, retain);

  @override
  void unsubscribe(String topic) {}
}

List<PlayerSlot> slots() => const [
      PlayerSlot(seat: 0, name: 'Host'),
      PlayerSlot(seat: 1, name: 'Guest'),
      PlayerSlot(seat: 2, name: 'Bot 3', isBot: true),
      PlayerSlot(seat: 3, name: 'Bot 4', isBot: true),
    ];

Future<void> pump([int ms = 30]) => Future.delayed(Duration(milliseconds: ms));

void main() {
  setUpAll(() => Get.testMode = true);

  test('host and client stay in sync through human and bot turns', () async {
    final broker = FakeBroker();
    final net = FakeRoomService(broker);
    const base = 'jackaroo-hg/v1/TEST';

    // Host creates the game and publishes the initial snapshot.
    final host = GameController(
      players: slots(),
      rules: const RuleSet(),
      hideHands: false,
      online: OnlineSession(net: net, base: base, mySeat: 0, isHost: true),
    )..onInit();
    await pump();
    final snap = broker.retained['$base/state']!;
    expect(snap['seq'], 0);

    // Client boots from that snapshot.
    final client = GameController(
      players: slots(),
      rules: const RuleSet(),
      hideHands: false,
      online: OnlineSession(
        net: net,
        base: base,
        mySeat: 1,
        isHost: false,
        initialState: Map<String, dynamic>.from(snap['state']),
        initialSeq: 0,
      ),
    )..onInit();
    await pump();
    expect(client.state.hands[0], host.state.hands[0]);
    expect(client.viewSeat, 1);
    expect(client.isLocalSeat(0), isFalse);
    expect(client.phase.value, Phase.botTurn); // waiting for host

    // Force a known position: host has an Ace, guest has a 2 and a marble out.
    for (final c in [host, client]) {
      c.state.hands[0] = [0]; // A♠
      c.state.hands[1] = [1, 2]; // 2♠ 3♠
      c.state.marbles[1][0] = 0;
      c.state.turn = 0;
      c.refreshTurn();
    }
    // Client must not be able to act for the host.
    client.tapCard(0);
    expect(client.phase.value, Phase.botTurn);

    // Host exits a marble → move + snapshot broadcast.
    host.tapCard(0);
    host.tapMarble(const MarbleRef(0, 0));
    await host.settle();
    await pump();
    await client.settle();
    await pump();
    expect(host.state.marbles[0][0], 0);
    expect(client.state.marbles[0][0], 0);
    expect(client.state.turn, 1);
    expect(client.phase.value, Phase.pickCard); // my turn now
    expect(host.phase.value, Phase.botTurn); // host waits for guest

    // Guest plays 2: intent → host validates → broadcast → both apply.
    client.tapCard(1);
    client.tapMarble(const MarbleRef(1, 0));
    expect(client.phase.value, Phase.animating); // waiting for host
    await pump();
    await host.settle();
    await pump();
    await client.settle();
    await pump();
    expect(host.state.marbles[1][0], 2);
    expect(client.state.marbles[1][0], 2);
    expect(client.state.hands[1], [2]);

    // Bots (seats 2, 3) run on the host only and the client follows.
    // Relaxed pace: ~2.2s think + slow animation + 1.5s pause per bot.
    for (var i = 0; i < 100; i++) {
      await pump(200);
      if ((broker.retained['$base/state']!['seq'] as int) >= 3) break;
    }
    await host.settle();
    // The client replays remote moves at the slow bot pace; let it catch up.
    for (var i = 0; i < 100; i++) {
      await client.settle();
      await pump(200);
      if (client.state.turn == host.state.turn && client.phase.value != Phase.animating) break;
    }
    expect(host.state.turn, client.state.turn);
    expect(host.state.marbles, client.state.marbles);
    expect(host.state.hands, client.state.hands);
    expect(broker.retained['$base/state']!['seq'], greaterThanOrEqualTo(3));
  });

  test('host ignores an illegal intent', () async {
    final broker = FakeBroker();
    final net = FakeRoomService(broker);
    const base = 'jackaroo-hg/v1/BAD';
    final host = GameController(
      players: slots(),
      rules: const RuleSet(),
      hideHands: false,
      online: OnlineSession(net: net, base: base, mySeat: 0, isHost: true),
    )..onInit();
    await pump();
    host.state.hands[1] = [1];
    host.state.marbles[1][0] = Pos.base; // no marble out → 2 is unplayable
    host.state.turn = 1;
    host.refreshTurn();
    // Forge an "advance 2" that the engine never offered.
    net.publish('$base/intent', {
      'seq': 0,
      'move': const Move(
        seat: 1,
        cardId: 1,
        kind: MoveKind.advance,
        marble: MarbleRef(1, 0),
        steps: 2,
        to: 2,
      ).toJson(),
    });
    await pump(100);
    expect(host.state.marbles[1][0], Pos.base);
    expect(host.state.turn, 1);
  });

  test('rejoin: a fresh client resumes from the retained snapshot', () async {
    final broker = FakeBroker();
    final net = FakeRoomService(broker);
    const base = 'jackaroo-hg/v1/REJN';
    final host = GameController(
      players: slots(),
      rules: const RuleSet(),
      hideHands: false,
      online: OnlineSession(net: net, base: base, mySeat: 0, isHost: true),
    )..onInit();
    await pump();
    // Host plays a couple of moves (forced discards to keep it deterministic).
    host.state.hands[0] = [1]; // 2 with nothing out → discard
    host.state.turn = 0;
    host.refreshTurn();
    host.tapCard(1); // select
    host.tapCard(1); // confirm the burn
    await host.settle();
    await pump(700);
    final snap = broker.retained['$base/state']!;
    expect(snap['seq'], 1);

    // The guest's page reloads: a brand-new controller boots from the
    // retained snapshot with its seq, exactly what OnlineController.rejoin does.
    final rejoined = GameController(
      players: slots(),
      rules: const RuleSet(),
      hideHands: false,
      online: OnlineSession(
        net: net,
        base: base,
        mySeat: 1,
        isHost: false,
        initialState: Map<String, dynamic>.from(snap['state']),
        initialSeq: snap['seq'],
      ),
    )..onInit();
    await pump();
    expect(rejoined.state.turn, host.state.turn);
    expect(rejoined.state.hands, host.state.hands);

    // Guest acts on its turn (it is seat 1's turn now) and the host accepts.
    for (final c in [host, rejoined]) {
      c.state.hands[1] = [1];
      c.state.marbles[1][0] = 0;
      c.state.turn = 1;
      c.refreshTurn();
    }
    rejoined.tapCard(1);
    rejoined.tapMarble(const MarbleRef(1, 0));
    await pump();
    await host.settle();
    await pump();
    await rejoined.settle();
    await pump();
    expect(host.state.marbles[1][0], 2);
    expect(rejoined.state.marbles[1][0], 2);
    expect(broker.retained['$base/state']!['seq'], 2);
  });
}
