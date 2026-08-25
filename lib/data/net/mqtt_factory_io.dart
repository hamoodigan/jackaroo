import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'net_config.dart';

/// Android / iOS / desktop: plain TCP to the public broker.
MqttClient createClient(String clientId) {
  final c = MqttServerClient.withPort(NetConfig.brokerHost, clientId, NetConfig.tcpPort);
  c.secure = false;
  return c;
}
