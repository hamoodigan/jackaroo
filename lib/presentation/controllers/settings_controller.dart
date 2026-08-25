import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/audio_service.dart';
import '../../data/local_storage.dart';

class SettingsController extends GetxController {
  final LocalStorage store;
  final AudioService audio;
  SettingsController(this.store, this.audio);

  late final locale = store.locale.obs;
  late final hideHands = store.hideHands.obs;
  late final botPace = store.botPace.obs;

  @override
  void onInit() {
    super.onInit();
    audio.sfxEnabled.value = store.sfx;
    audio.musicEnabled.value = store.music;
    ever(audio.sfxEnabled, (v) => store.sfx = v);
    ever(audio.musicEnabled, (v) => store.music = v);
    ever(hideHands, (v) => store.hideHands = v);
    ever(botPace, (v) => store.botPace = v);
    ever(locale, (v) {
      store.locale = v;
      Get.updateLocale(Locale(v));
    });
  }

  bool get isArabic => locale.value == 'ar';
}
