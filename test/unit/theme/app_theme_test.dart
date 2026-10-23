import 'package:flutter/material.dart';
import 'package:openimis_claim_policy_app/feature/shared/utils/styles/app_color.dart';
import 'package:openimis_claim_policy_app/feature/shared/utils/styles/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('openIMIS Profile App Theme Tests', () {
    test('Light Theme uses JobsFlutterApp colors and Poppins typography', () {
      final lightTheme = AppThemes.appTheme(Brightness.light);

      expect(lightTheme.brightness, equals(Brightness.light));
      expect(lightTheme.primaryColor, equals(CustomColors.BrandPurple));
      expect(
        lightTheme.scaffoldBackgroundColor,
        equals(const Color(0xFFF5F8FA)),
      );
      expect(lightTheme.textTheme.bodyLarge?.fontFamily, equals('Poppins'));
      expect(
        lightTheme.appBarTheme.backgroundColor,
        equals(CustomColors.BrandPurple),
      );
      expect(lightTheme.appBarTheme.foregroundColor, equals(Colors.white));
      expect(lightTheme.colorScheme.secondary, equals(CustomColors.BrandGreen));
      expect(lightTheme.colorScheme.error, equals(CustomColors.NavRed));
    });

    test('Dark Theme has proper dark background and BrandGreen secondary', () {
      final darkTheme = AppThemes.appTheme(Brightness.dark);

      expect(darkTheme.brightness, equals(Brightness.dark));
      expect(
        darkTheme.scaffoldBackgroundColor,
        equals(const Color(0xFF151515)),
      );
      expect(darkTheme.textTheme.bodyLarge?.fontFamily, equals('Poppins'));
      expect(darkTheme.colorScheme.secondary, equals(CustomColors.BrandGreen));
    });

    test('Theme aliases match the JobsFlutterApp palette', () {
      expect(CustomColors.BrandPurple, equals(const Color(0xFF1DA1F2)));
      expect(
        CustomColors.BrandGreen,
        equals(const Color.fromRGBO(97, 166, 41, 1)),
      );
      expect(CustomColors.NavRed, equals(const Color(0xFFFB4747)));
      expect(CustomColors.SuccessGreen, equals(const Color(0xFF439927)));
      expect(CustomColors.ExpiryOrange, equals(const Color(0xFFD44F16)));
      expect(CustomColors.GreyBackground, equals(const Color(0xFFF5F8FA)));
    });
  });
}
