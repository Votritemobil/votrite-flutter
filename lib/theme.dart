import 'package:flutter/material.dart';

class VotRiteTheme {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color accentGold = Color(0xFFFFB300);
  static const Color white = Colors.white;
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF424242);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color errorRed = Color(0xFFC62828);

  static const Color a11yBg = Color(0xFF000000);
  static const Color a11yText = Color(0xFFFFFF00);
  static const Color a11yHighlight = Color(0xFF00FF00);
  static const Color a11yButton = Color(0xFF1565C0);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: accentGold,
      ),
      scaffoldBackgroundColor: white,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkBlue),
        headlineMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlue),
        bodyLarge: TextStyle(fontSize: 14, color: darkGray),
        bodyMedium: TextStyle(fontSize: 13, color: darkGray),
      ),
    );
  }

  static Widget footer({Color color = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Text(
        'VotRite',
        style: TextStyle(
          fontSize: 10,
          color: color.withValues(alpha: 0.5),
          letterSpacing: 2,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  static ThemeData get accessibilityTheme {
    return ThemeData(
      primaryColor: a11yButton,
      colorScheme: ColorScheme.fromSeed(
        seedColor: a11yButton,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: a11yBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111111),
        foregroundColor: a11yText,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: a11yText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: a11yButton,
          foregroundColor: a11yText,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: a11yText, width: 2),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: a11yText),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: a11yText),
        bodyLarge: TextStyle(fontSize: 22, color: a11yText),
        bodyMedium: TextStyle(fontSize: 20, color: a11yText),
      ),
    );
  }
}
