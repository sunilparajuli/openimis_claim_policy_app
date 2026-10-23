import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/core/localization/locale_provider.dart';

/// An interactive language toggle button supporting English and French.
class LanguageSelectorButton extends ConsumerWidget {
  final bool showLabel;
  final Color? foregroundColor;

  const LanguageSelectorButton({
    super.key,
    this.showLabel = true,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(appLocaleProvider);
    final isFrench = currentLocale.languageCode == 'fr';
    final color = foregroundColor ?? Colors.white;

    return PopupMenuButton<String>(
      tooltip: isFrench ? 'Changer de langue' : 'Switch Language',
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language, size: 20, color: color),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              isFrench ? 'FR' : 'EN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ],
      ),
      initialValue: currentLocale.languageCode,
      onSelected: (langCode) {
        ref.read(appLocaleProvider.notifier).setLocale(Locale(langCode));
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem<String>(
          value: 'en',
          checked: !isFrench,
          child: const Row(children: [Text('🇺🇸  English')]),
        ),
        CheckedPopupMenuItem<String>(
          value: 'fr',
          checked: isFrench,
          child: const Row(children: [Text('🇫🇷  Français')]),
        ),
      ],
    );
  }
}
