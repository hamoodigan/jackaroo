import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app.dart';
import 'data/audio_service.dart';
import 'data/local_storage.dart';
import 'data/net/room_service.dart';
import 'presentation/controllers/online_controller.dart';
import 'presentation/controllers/settings_controller.dart';
import 'presentation/controllers/setup_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  final store = await LocalStorage.open();
  final audio = await Get.putAsync(() => AudioService().init());
  Get.put(SettingsController(store, audio));
  Get.put(SetupController(store));
  final net = Get.put(RoomService());
  Get.put(OnlineController(net, store));
  runApp(const JackarooApp());
}
