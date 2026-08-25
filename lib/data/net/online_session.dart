import 'room_service.dart';

/// Everything the game controller needs to talk to one online room.
///
/// Protocol (host-authoritative):
///  - `<base>/intent`  client → host: {seq, move}
///  - `<base>/moves`   host → all:    {seq, move, state}
///  - `<base>/state`   host → all (retained): full snapshot {seq, state}
class OnlineSession {
  final RoomService net;
  final String base;
  final int mySeat;
  final bool isHost;

  /// Snapshot a client starts from (host publishes it at start).
  final Map<String, dynamic>? initialState;
  final int initialSeq;

  OnlineSession({
    required this.net,
    required this.base,
    required this.mySeat,
    required this.isHost,
    this.initialState,
    this.initialSeq = 0,
  });

  void publishMove(Map<String, dynamic> json) => net.publish('$base/moves', json);

  void publishState(Map<String, dynamic> json) =>
      net.publish('$base/state', json, retain: true);

  void sendIntent(Map<String, dynamic> json) => net.publish('$base/intent', json);

  void onMoves(void Function(Map<String, dynamic>) cb) =>
      net.subscribe('$base/moves', cb);

  void onIntents(void Function(Map<String, dynamic>) cb) =>
      net.subscribe('$base/intent', cb);

  void dispose() {
    net.unsubscribe('$base/moves');
    net.unsubscribe('$base/intent');
  }
}
