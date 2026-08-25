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
