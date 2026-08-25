import 'package:mqtt_client/mqtt_client.dart';

/// Fallback used only when neither `dart:io` nor a browser is available.
MqttClient createClient(String clientId) =>
    throw UnsupportedError('No MQTT transport on this platform');
