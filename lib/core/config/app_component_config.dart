import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppComponentConfig {
  const AppComponentConfig({
    required this.appName,
    required this.defaultCurrency,
    required this.supportedLanguages,
    required this.standardSheetHeightFactor,
    required this.confirmationSheetHeightFactor,
    required this.cardRadius,
    required this.fieldRadius,
    required this.contentPadding,
  });

  final String appName;
  final String defaultCurrency;
  final List<String> supportedLanguages;
  final double standardSheetHeightFactor;
  final double confirmationSheetHeightFactor;
  final double cardRadius;
  final double fieldRadius;
  final double contentPadding;

  factory AppComponentConfig.fromJson(Map<String, dynamic> json) {
    final components = json['components'] as Map<String, dynamic>? ?? const {};
    double number(String key, double fallback) =>
        (components[key] as num?)?.toDouble() ?? fallback;
    return AppComponentConfig(
      appName: json['appName']?.toString() ?? 'openIMIS',
      defaultCurrency: json['defaultCurrency']?.toString() ?? 'USD',
      supportedLanguages:
          (json['supportedLanguages'] as List?)
              ?.map((value) => value.toString())
              .toList(growable: false) ??
          const ['en'],
      standardSheetHeightFactor: number('standardSheetHeightFactor', 0.62),
      confirmationSheetHeightFactor: number(
        'confirmationSheetHeightFactor',
        0.5,
      ),
      cardRadius: number('cardRadius', 14),
      fieldRadius: number('fieldRadius', 14),
      contentPadding: number('contentPadding', 16),
    );
  }

  static Future<AppComponentConfig> load() async {
    final source = await rootBundle.loadString('assets/config/default.json');
    return AppComponentConfig.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }
}

final appComponentConfigProvider = FutureProvider<AppComponentConfig>(
  (ref) => AppComponentConfig.load(),
);
