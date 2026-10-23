import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

/// App-wide language/locale state notifier.
///
/// Defaults to English ('en') and supports French ('fr').
@Riverpod(keepAlive: true)
class AppLocaleNotifier extends _$AppLocaleNotifier {
  @override
  Locale build() => const Locale('en');

  /// Sets a specific locale (e.g. 'en' or 'fr').
  void setLocale(Locale newLocale) {
    if (state != newLocale) {
      state = newLocale;
    }
  }

  /// Toggles between English ('en') and French ('fr').
  void toggleLanguage() {
    state = state.languageCode == 'en'
        ? const Locale('fr')
        : const Locale('en');
  }

  bool get isFrench => state.languageCode == 'fr';
}
