import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:openimis_claim_policy_app/core/localization/locale_provider.dart';
import 'package:openimis_claim_policy_app/feature/shared/navigation/app_router.dart';
import 'package:openimis_claim_policy_app/feature/shared/utils/styles/app_theme.dart';

part 'my_app.g.dart';

// Theme mode provider for app-wide theme switching
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({required this.launchTitle, super.key});
  final String launchTitle;

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final brightness = themeMode == ThemeMode.light
        ? Brightness.light
        : (themeMode == ThemeMode.dark
              ? Brightness.dark
              : MediaQuery.platformBrightnessOf(context));

    // Set system UI overlay style globally
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF151515),
        systemNavigationBarIconBrightness: brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );

    final currentLocale = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      title: widget.launchTitle,
      debugShowCheckedModeBanner: false, // Remove debug banner
      locale: currentLocale,
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Professional theme settings
      theme: AppThemes.appTheme(Brightness.light),
      darkTheme: AppThemes.appTheme(Brightness.dark),
      themeMode: themeMode,
      // Use auto router for navigation
      routerConfig: _appRouter.config(),
    );
  }
}
