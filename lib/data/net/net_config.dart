/// Public MQTT broker used for online rooms. Free, no account, no setup.
/// Swap the host here to move to another broker (e.g. your own Mosquitto).
class NetConfig {
  NetConfig._();

  static const String brokerHost = 'broker.hivemq.com';
  static const int tcpPort = 1883;
  static const String wssUrl = 'wss://broker.hivemq.com/mqtt';
  static const int wssPort = 8884; // path /mqtt is appended by the client
  static const String topicRoot = 'jackaroo-hg/v1';

  /// Unambiguous letters for room codes (no O/0, I/1).
  static const String codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const int codeLength = 4;
}
