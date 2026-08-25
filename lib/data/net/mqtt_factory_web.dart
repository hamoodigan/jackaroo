import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'net_config.dart';

/// Browser: secure WebSocket (GitHub Pages is https, so wss is required).
MqttClient createClient(String clientId) {
  final c = MqttBrowserClient.withPort(NetConfig.wssUrl, clientId, NetConfig.wssPort);
  c.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
  return c;
}
