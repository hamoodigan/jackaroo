import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over SharedPreferences for settings and the last setup.
class LocalStorage {
  final SharedPreferences _p;
  LocalStorage(this._p);

  static Future<LocalStorage> open() async =>
      LocalStorage(await SharedPreferences.getInstance());

  String get locale => _p.getString('locale') ?? 'en';
  set locale(String v) => _p.setString('locale', v);

  bool get sfx => _p.getBool('sfx') ?? true;
  set sfx(bool v) => _p.setBool('sfx', v);

  bool get music => _p.getBool('music') ?? false;
  set music(bool v) => _p.setBool('music', v);

  /// Stable identity across reloads so a player can rejoin their seat.
  String get playerId => _p.getString('playerId') ?? '';
  set playerId(String v) => _p.setString('playerId', v);

  /// Last online room (code) this device was in, for "Rejoin".
  String? get lastRoom => _p.getString('lastRoom');
  set lastRoom(String? v) =>
      v == null ? _p.remove('lastRoom') : _p.setString('lastRoom', v);

  String get playerName => _p.getString('playerName') ?? '';
  set playerName(String v) => _p.setString('playerName', v);

  /// 1.0 relaxed, 0.55 normal, 0.25 fast — multiplies every bot delay.
  double get botPace => _p.getDouble('botPace') ?? 1.0;
  set botPace(double v) => _p.setDouble('botPace', v);

  bool get hideHands => _p.getBool('hideHands') ?? true;
  set hideHands(bool v) => _p.setBool('hideHands', v);

  Map<String, dynamic>? get lastSetup {
    final s = _p.getString('lastSetup');
    return s == null ? null : jsonDecode(s) as Map<String, dynamic>;
  }

  set lastSetup(Map<String, dynamic>? v) => v == null
      ? _p.remove('lastSetup')
      : _p.setString('lastSetup', jsonEncode(v));
}
