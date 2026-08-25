// Real-network smoke test: connect to the public broker, publish a retained
// message on a throw-away topic and read it back. Skipped automatically
// when offline. Run with: flutter test test/broker_connectivity_test.dart
@Tags(['network'])
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jackaroo/data/net/net_config.dart';
import 'package:jackaroo/data/net/room_service.dart';

void main() {
  test('public MQTT broker round-trip', () async {
    final net = RoomService();
    final ok = await net.connect();
    if (!ok) {
      markTestSkipped('broker unreachable (offline?)');
      return;
    }
    final topic = '${NetConfig.topicRoot}/_selftest/${net.clientId}';
    final got = Completer<Map<String, dynamic>>();
    net.subscribe(topic, (j) {
      if (!got.isCompleted) got.complete(j);
    });
    await Future.delayed(const Duration(milliseconds: 300));
    net.publish(topic, {'hello': 'jackaroo', 'n': 42}, retain: true);
    final j = await got.future.timeout(const Duration(seconds: 10));
    expect(j['hello'], 'jackaroo');
    expect(j['n'], 42);
    net.clearRetained(topic);
    net.disconnect();
  }, timeout: const Timeout(Duration(seconds: 40)));
}
