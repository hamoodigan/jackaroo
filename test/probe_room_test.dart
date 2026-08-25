// Debug probe: prints the retained lobby/state of a room on the public
// broker. Run: flutter test test/probe_room_test.dart --dart-define=ROOM=VLKS
@Tags(['network'])
library;


import 'package:flutter_test/flutter_test.dart';
import 'package:jackaroo/data/net/net_config.dart';
import 'package:jackaroo/data/net/room_service.dart';

void main() {
  test('probe room', () async {
    const room = String.fromEnvironment('ROOM', defaultValue: 'VLKS');
    final net = RoomService();
    expect(await net.connect(), isTrue);
    final base = '${NetConfig.topicRoot}/$room';
    final seen = <String>[];
    net.subscribe('$base/lobby', (j) => seen.add('lobby started=${j['started']} players=${(j['players'] as List).length}'));
    net.subscribe('$base/state', (j) => seen.add('state seq=${j['seq']} turn=${(j['state'] as Map)['turn']} discard=${(j['state'] as Map)['discard']}'));
    net.subscribe('$base/moves', (j) => seen.add('move seq=${j['seq']}'));
    await Future.delayed(const Duration(seconds: 4));
    // ignore: avoid_print
    print(seen.isEmpty ? 'NOTHING RETAINED' : seen.join('\n'));
    net.disconnect();
  }, timeout: const Timeout(Duration(seconds: 40)));
}
