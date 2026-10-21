// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

/// Full palette from openimis-profile-app
class CustomColors {
  // --- BRAND COLORS ---
  // Legacy names retained so feature screens inherit the JobsFlutterApp theme.
  static const Color BrandPurple = Color(0xFF1DA1F2);
  static const Color BrandGreen = Color.fromRGBO(
    97,
    166,
    41,
    1,
  ); // #61A629 openIMIS Brand Green
  static const Color NavRed = Color(0xFFFB4747);
  static const Color SuccessGreen = Color(
    0xFF439927,
  ); // #439927 Success/remaining
  static const Color ExpiryOrange = Color(
    0xFFD44F16,
  ); // #D44F16 Expiry background/warning

  // --- NEUTRAL & BACKGROUND COLORS ---
  static const Color GreyBackground = Color(0xFFF5F8FA);
  static const Color GreyBorder = Color(0xFFE4E5E7);

  static const Color LightGreen = Color.fromRGBO(41, 127, 141, 1);
  static const Color LightGreen1 = Color.fromRGBO(126, 174, 183, 1);
  static const Color LightGreen2 = Color.fromRGBO(176, 206, 212, 1);

  static const Color GreenLight = Color.fromRGBO(93, 230, 26, 1);
  static const Color GreenDark = Color.fromRGBO(57, 170, 2, 1);
  static const Color GreenIcon = Color.fromRGBO(30, 209, 2, 1);
  static const Color GreenAccent = Color.fromRGBO(30, 209, 2, 1);
  static const Color GreenShadow = Color.fromRGBO(30, 209, 2, 0.24);
  static const Color GreenBackground = Color.fromRGBO(181, 255, 155, 0.36);

  static const Color OrangeIcon = Color.fromRGBO(236, 108, 11, 1);
  static const Color OrangeBackground = Color.fromRGBO(255, 208, 155, 0.36);

  static const Color PurpleLight = Color.fromRGBO(248, 87, 195, 1);
  static const Color PurpleDark = Color.fromRGBO(224, 19, 156, 1);
  static const Color PurpleIcon = Color.fromRGBO(209, 2, 99, 1);
  static const Color PurpleAccent = Color.fromRGBO(209, 2, 99, 1);
  static const Color PurpleShadow = Color.fromRGBO(209, 2, 99, 0.27);
  static const Color PurpleBackground = Color.fromRGBO(255, 155, 205, 0.36);

  static const Color DeeppurlpleIcon = Color.fromRGBO(191, 0, 128, 1);
  static const Color DeeppurlpleBackground = Color.fromRGBO(
    245,
    155,
    255,
    0.36,
  );

  static const Color BlueLight = Color.fromRGBO(126, 182, 255, 1);
  static const Color BlueDark = Color.fromRGBO(95, 135, 231, 1);
  static const Color BlueIcon = Color.fromRGBO(9, 172, 206, 1);
  static const Color BlueBackground = Color.fromRGBO(155, 255, 248, 0.36);
  static const Color BlueShadow = Color.fromRGBO(104, 148, 238, 1);

  static const Color HeaderBlueLight = Color.fromRGBO(129, 199, 245, 1);
  static const Color HeaderBlueDark = Color.fromRGBO(56, 103, 213, 1);
  static const Color HeaderGreyLight = Color.fromRGBO(225, 255, 255, 0.31);

  static const Color YellowIcon = Color.fromRGBO(249, 194, 41, 1);
  static const Color YellowBell = Color.fromRGBO(225, 220, 0, 1);
  static const Color YellowAccent = Color.fromRGBO(255, 213, 6, 1);
  static const Color YellowShadow = Color.fromRGBO(243, 230, 37, 0.27);
  static const Color YellowBackground = Color.fromRGBO(255, 238, 155, 0.36);

  static const Color PinkLight = Color.fromRGBO(242, 250, 251, 1);

  static const Color BellGrey = Color.fromRGBO(217, 217, 217, 1);
  static const Color BellYellow = Color.fromRGBO(255, 220, 0, 1);

  static const Color TrashRed = Color.fromRGBO(251, 54, 54, 1);
  static const Color TrashRedBackground = Color.fromRGBO(255, 207, 207, 1);

  // --- TYPOGRAPHY COLORS ---
  static const Color TextHeader = Color(0xFF14171A);
  static const Color TextHeaderGrey = Color(0xFF657786);
  static const Color TextSubHeaderGrey = Color(0xFFAAB8C2);
  static const Color TextSubHeader = Color.fromRGBO(
    139,
    135,
    179,
    1,
  ); // #8B87B3
  static const Color TextBody = Color(0xFF657786);
  static const Color TextGrey = Color.fromRGBO(198, 198, 200, 1); // #C6C6C8
  static const Color TextWhite = Color.fromRGBO(243, 243, 243, 1); // #F3F3F3
  static const Color HeaderCircle = Color.fromRGBO(255, 255, 255, 0.17);
}

/// App colors adhering to openIMIS Profile App theme specification
class AppColor {
  const AppColor({
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.gray,
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.cardBackground,
    required this.primaryColor,
    required this.accentColor,
    required this.successColor,
    required this.errorColor,
    required this.warningColor,
    required this.surfaceColor,
  });

  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color gray;
  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color cardBackground;
  final Color primaryColor;
  final Color accentColor;
  final Color successColor;
  final Color errorColor;
  final Color warningColor;
  final Color surfaceColor;

  // Convenient static shortcuts matching openimis-profile-app
  static const Color brandPurple = CustomColors.BrandPurple;
  static const Color brandGreen = CustomColors.BrandGreen;
  static const Color navRed = CustomColors.NavRed;
  static const Color successGreen = CustomColors.SuccessGreen;
  static const Color expiryOrange = CustomColors.ExpiryOrange;
  static const Color greyBackground = CustomColors.GreyBackground;
  static const Color greyBorder = CustomColors.GreyBorder;

  // Light theme - openIMIS official brand styling
  static const lightColor = AppColor(
    textPrimary: Color(0xFF14171A),
    textSecondary:
        CustomColors.TextHeaderGrey, // Clean grey for body/secondary text
    divider: CustomColors.GreyBorder, // #CFCFCF
    gray: CustomColors.TextSubHeaderGrey, // #A1A1A1
    backgroundPrimary: CustomColors.GreyBackground, // #F9FCFF
    backgroundSecondary: Color(0xFFF0F4F8),
    cardBackground: Colors.white,
    primaryColor: CustomColors.BrandPurple,
    accentColor: CustomColors.BrandGreen, // #61A629
    successColor: CustomColors.SuccessGreen, // #439927
    errorColor: CustomColors.NavRed, // #E51C23
    warningColor: CustomColors.ExpiryOrange, // #D44F16
    surfaceColor: Colors.white,
  );

  // Dark theme - openIMIS dark mode styling
  static const darkColor = AppColor(
    textPrimary: CustomColors.TextWhite, // #F3F3F3
    textSecondary: Color(0xFFB0B0B0),
    divider: Color(0xFF2C2C2C),
    gray: Color(0xFF7A7A7A),
    backgroundPrimary: Color(0xFF151515), // Dark surface from custom_theme.dart
    backgroundSecondary: Color(0xFF1E1E1E),
    cardBackground: Color(0xFF1E1E1E),
    primaryColor: Color(0xFFB388FF), // Elevated purple tint for dark contrast
    accentColor: CustomColors.BrandGreen, // #61A629
    successColor: Color(0xFF5DD39E),
    errorColor: Color(0xFFFF5252),
    warningColor: CustomColors.ExpiryOrange,
    surfaceColor: Color(0xFF1E1E1E),
  );
}

extension AppColorExtension on BuildContext {
  AppColor get color => _getColorByBrightness(Theme.of(this).brightness);

  AppColor _getColorByBrightness(Brightness brightness) {
    switch (brightness) {
      case Brightness.light:
        return AppColor.lightColor;
      case Brightness.dark:
        return AppColor.darkColor;
    }
  }
}
