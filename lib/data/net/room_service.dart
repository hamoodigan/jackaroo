import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_factory_stub.dart'
    if (dart.library.js_interop) 'mqtt_factory_web.dart'
    if (dart.library.io) 'mqtt_factory_io.dart';
import 'net_config.dart';

/// Thin pub/sub wrapper over a public MQTT broker. Rooms are just topic
/// prefixes (`jackaroo-hg/v1/<CODE>/…`); retained messages let late
/// subscribers pick up the lobby and the latest game snapshot.
class RoomService extends GetxService {
  MqttClient? _client;
  final _handlers = <String, List<void Function(Map<String, dynamic>)>>{};
  StreamSubscription? _sub;

  final connected = false.obs;

  late final String clientId =
      'jk-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-${Random().nextInt(1 << 20).toRadixString(36)}';

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<bool> connect() async {
    if (isConnected) return true;
    final c = createClient(clientId);
    c.logging(on: false);
    c.keepAlivePeriod = 30;
    c.setProtocolV311();
    c.connectionMessage =
        MqttConnectMessage().withClientIdentifier(clientId).startClean();
    c.onDisconnected = () => connected.value = false;
    try {
      await c.connect().timeout(const Duration(seconds: 12));
    } catch (_) {
      c.disconnect();
      return false;
    }
    if (c.connectionStatus?.state != MqttConnectionState.connected) {
      c.disconnect();
      return false;
    }
    _client = c;
    _sub?.cancel();
    _sub = c.updates?.listen(_onUpdates);
    // Re-subscribe anything registered before the (re)connect.
    for (final t in _handlers.keys) {
      c.subscribe(t, MqttQos.atLeastOnce);
    }
    connected.value = true;
    return true;
  }

  void _onUpdates(List<MqttReceivedMessage<MqttMessage>> events) {
    for (final e in events) {
      final msg = e.payload;
      if (msg is! MqttPublishMessage) continue;
      final text = utf8.decode(msg.payload.message, allowMalformed: true);
      Map<String, dynamic> json;
      try {
        json = Map<String, dynamic>.from(jsonDecode(text) as Map);
      } catch (_) {
        continue;
      }
      final hs = _handlers[e.topic];
      if (hs == null) continue;
      for (final h in List.of(hs)) {
        h(json);
      }
    }
  }

  void subscribe(String topic, void Function(Map<String, dynamic>) handler) {
    final list = _handlers.putIfAbsent(topic, () => []);
    if (list.isEmpty) _client?.subscribe(topic, MqttQos.atLeastOnce);
    list.add(handler);
  }

  void unsubscribe(String topic) {
    _handlers.remove(topic);
    if (isConnected) _client?.unsubscribe(topic);
  }

  void unsubscribePrefix(String prefix) {
    for (final t in _handlers.keys.where((t) => t.startsWith(prefix)).toList()) {
      unsubscribe(t);
    }
  }

  void publish(String topic, Map<String, dynamic> json, {bool retain = false}) {
    if (!isConnected) return;
    final b = MqttClientPayloadBuilder()..addUTF8String(jsonEncode(json));
    _client!.publishMessage(topic, MqttQos.atLeastOnce, b.payload!, retain: retain);
  }

  /// Clears a retained message.
  void clearRetained(String topic) {
    if (!isConnected) return;
    final b = MqttClientPayloadBuilder()..addString('');
    _client!.publishMessage(topic, MqttQos.atLeastOnce, b.payload!, retain: true);
  }

  static String newCode(Random rng) => List.generate(
        NetConfig.codeLength,
        (_) => NetConfig.codeAlphabet[rng.nextInt(NetConfig.codeAlphabet.length)],
      ).join();

  void disconnect() {
    _sub?.cancel();
    _client?.disconnect();
    _client = null;
    connected.value = false;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
