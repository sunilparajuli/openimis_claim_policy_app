import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod_template/feature/shared/utils/styles/app_color.dart';

/// App theme mirroring openimis-profile-app styling
class AppThemes {
  static ThemeData appTheme(Brightness brightness) {
    final colors = brightness == Brightness.light
        ? AppColor.lightColor
        : AppColor.darkColor;

    final isLight = brightness == Brightness.light;
    final baseTextTheme = ThemeData(brightness: brightness).textTheme;
    final textTheme = baseTextTheme
        .copyWith(
          displayLarge: baseTextTheme.displayLarge?.copyWith(fontSize: 48),
          displayMedium: baseTextTheme.displayMedium?.copyWith(fontSize: 40),
          displaySmall: baseTextTheme.displaySmall?.copyWith(fontSize: 32),
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontSize: 28),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontSize: 24),
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontSize: 20),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          titleSmall: baseTextTheme.titleSmall?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 14),
          bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 12),
          labelLarge: baseTextTheme.labelLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: baseTextTheme.labelMedium?.copyWith(fontSize: 12),
          labelSmall: baseTextTheme.labelSmall?.copyWith(fontSize: 11),
        )
        .apply(
          fontFamily: 'Poppins',
          bodyColor: colors.textPrimary,
          displayColor: colors.textPrimary,
        );

    final SystemUiOverlayStyle overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Status bar icons should be light (white) on dark BrandPurple appbar
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Poppins',
      primaryColor: isLight ? CustomColors.BrandPurple : Colors.black,
      splashColor: CustomColors.BrandGreen.withValues(alpha: 0.2),
      scaffoldBackgroundColor: colors.backgroundPrimary,
      dividerTheme: DividerThemeData(color: colors.divider, thickness: 0.8),
      listTileTheme: ListTileThemeData(
        dense: true,
        minVerticalPadding: 8,
        titleTextStyle: textTheme.bodyMedium,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: colors.textSecondary,
      ),

      // App Bar - Matching openimis-profile-app with BrandPurple
      appBarTheme: AppBarTheme(
        backgroundColor: isLight
            ? CustomColors.BrandPurple
            : const Color(0xFF151515),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlay,
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: CustomColors.BrandPurple,
        brightness: brightness,
        surface: colors.cardBackground,
        primary: colors.primaryColor,
        secondary: CustomColors.BrandGreen,
        error: CustomColors.NavRed,
      ),

      // Card Theme - Rounded corners with subtle elevation
      cardTheme: CardThemeData(
        color: colors.cardBackground,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.divider),
        ),
      ),

      // Bottom Navigation - Matches openimis BrandPurple or NavRed
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isLight ? Colors.white : const Color(0xFF151515),
        selectedItemColor: colors.primaryColor,
        unselectedItemColor: colors.textSecondary,
        elevation: 2,
        type: BottomNavigationBarType.fixed,
      ),

      // TabBar Theme - Clean white tab headers matching BrandPurple app bars
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.normal,
          color: Colors.white70,
        ),
      ),

      // Dialog Theme - Rounded 18px dialogs with BrandPurple header
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? Colors.white : const Color(0xFF151515),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          color: isLight ? CustomColors.BrandPurple : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Button Theme
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        buttonColor: isLight
            ? CustomColors.BrandPurple
            : const Color(0xFFB388FF),
        colorScheme: isLight
            ? const ColorScheme.light()
            : const ColorScheme.dark(),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLight
              ? CustomColors.BrandPurple
              : const Color(0xFFB388FF),
          foregroundColor: Colors.white,
          elevation: 10,
          shadowColor: colors.primaryColor.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isLight
              ? CustomColors.BrandPurple
              : const Color(0xFFB388FF),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isLight
              ? CustomColors.BrandPurple
              : const Color(0xFFB388FF),
          side: BorderSide(
            color: isLight ? CustomColors.BrandPurple : const Color(0xFFB388FF),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E1E1E),
        foregroundColor: isLight ? CustomColors.BrandPurple : Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          color: colors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          color: colors.gray,
          fontSize: 14,
        ),
        filled: true,
        fillColor: colors.surfaceColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isLight ? CustomColors.BrandPurple : const Color(0xFFB388FF),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CustomColors.NavRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CustomColors.NavRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight
            ? CustomColors.BrandPurple
            : const Color(0xFF2C2C2C),
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        actionTextColor: CustomColors.BrandGreen,
      ),

      // Typography
      textTheme: textTheme,
    );
  }

  static Color appBackgroundColor(Brightness brightness) {
    return brightness == Brightness.light
        ? AppColor.lightColor.backgroundPrimary
        : AppColor.darkColor.backgroundPrimary;
  }
}
