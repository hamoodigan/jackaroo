import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'core/localization/app_translations.dart';
import 'core/theme/app_theme.dart';
import 'presentation/controllers/settings_controller.dart';
import 'presentation/screens/game_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/rules_screen.dart';
import 'presentation/screens/setup_screen.dart';

class JackarooApp extends StatelessWidget {
  const JackarooApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return GetMaterialApp(
      title: 'Jackaroo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.data,
      translations: AppTranslations(),
      locale: Locale(settings.locale.value),
      fallbackLocale: const Locale('en'),
      supportedLocales: AppTranslations.supported.map(Locale.new).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      defaultTransition: Transition.fadeIn,
      getPages: [
        GetPage(name: '/', page: () => const HomeScreen()),
        GetPage(name: '/setup', page: () => const SetupScreen()),
        GetPage(name: '/game', page: () => const GameScreen()),
        GetPage(name: '/rules', page: () => const RulesScreen()),
      ],
    );
  }
}
