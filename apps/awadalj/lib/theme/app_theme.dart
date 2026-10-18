import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryTeal = Color(0xFF00C896);
  static const Color primaryTealDark = Color(0xFF00897B);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF151D2F);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primaryTealDark,
      onPrimary: Colors.white,
      secondary: Color(0xFF0288D1),
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      surface: Color(0xFFF8FAFC),
      onSurface: Color(0xFF0F172A),
    ),
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryTealDark,
      unselectedLabelColor: Colors.blueGrey,
      indicatorColor: primaryTealDark,
      dividerColor: Colors.transparent,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryTealDark,
      thumbColor: primaryTealDark,
      overlayColor: primaryTealDark.withValues(alpha: 0.15),
      inactiveTrackColor: const Color(0xFFCBD5E1),
      trackHeight: 4,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryTeal,
      onPrimary: Color(0xFF0B0F19),
      secondary: accentCyan,
      onSecondary: Color(0xFF0B0F19),
      error: Colors.redAccent,
      onError: Colors.white,
      surface: darkSurface,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 2,
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkBorder),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryTeal,
      unselectedLabelColor: Colors.white60,
      indicatorColor: primaryTeal,
      dividerColor: Colors.transparent,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryTeal,
      thumbColor: primaryTeal,
      overlayColor: primaryTeal.withValues(alpha: 0.2),
      inactiveTrackColor: Colors.white24,
      trackHeight: 4,
    ),
  );
}
