import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../controllers/settings_controller.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const SettingsSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final s = Get.find<SettingsController>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('settings'.tr, style: AppTheme.display(22, color: AppTheme.gold)),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language_rounded, color: AppTheme.gold),
                  title: Text('language'.tr),
                  trailing: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'en', label: Text('English')),
                      ButtonSegment(value: 'ar', label: Text('العربية')),
                    ],
                    selected: {s.locale.value},
                    onSelectionChanged: (v) => s.locale.value = v.first,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.volume_up_rounded, color: AppTheme.gold),
                  title: Text('sound'.tr),
                  value: s.audio.sfxEnabled.value,
                  onChanged: (v) => s.audio.sfxEnabled.value = v,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.music_note_rounded, color: AppTheme.gold),
                  title: Text('music'.tr),
                  value: s.audio.musicEnabled.value,
                  onChanged: (v) => s.audio.musicEnabled.value = v,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.smart_toy_rounded, color: AppTheme.gold),
                  title: Text('bot_pace'.tr),
                  trailing: SegmentedButton<double>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 1.0, label: Text('pace_relaxed'.tr)),
                      ButtonSegment(value: 0.55, label: Text('pace_normal'.tr)),
                      ButtonSegment(value: 0.25, label: Text('pace_fast'.tr)),
                    ],
                    selected: {s.botPace.value},
                    onSelectionChanged: (v) => s.botPace.value = v.first,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.visibility_off_rounded, color: AppTheme.gold),
                  title: Text('hide_hands'.tr),
                  subtitle: Text('hide_hands_hint'.tr,
                      style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                  value: s.hideHands.value,
                  onChanged: (v) => s.hideHands.value = v,
                ),
              ],
            )),
      ),
    );
  }
}
