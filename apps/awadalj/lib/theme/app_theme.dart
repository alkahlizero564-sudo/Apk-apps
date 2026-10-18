import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryTeal = Color(0xFF00C896);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF334155);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF00897B),
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
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Color(0xFF00897B),
      unselectedLabelColor: Colors.blueGrey,
      indicatorColor: Color(0xFF00897B),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Color(0xFF00897B),
      thumbColor: Color(0xFF00897B),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryTeal,
      onPrimary: Color(0xFF0F172A),
      secondary: accentCyan,
      onSecondary: Color(0xFF0F172A),
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
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryTeal,
      unselectedLabelColor: Colors.white60,
      indicatorColor: primaryTeal,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: primaryTeal,
      thumbColor: primaryTeal,
    ),
  );
}
