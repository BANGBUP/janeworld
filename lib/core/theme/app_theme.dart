import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF6C63FF);
  static const _secondaryColor = Color(0xFFFF6B6B);
  static const _backgroundColor = Color(0xFFF8F9FF);
  static const _surfaceColor = Colors.white;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          primary: _primaryColor,
          secondary: _secondaryColor,
          surface: _surfaceColor,
        ),
        scaffoldBackgroundColor: _backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
          displayMedium: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3436),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3436),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF636E72),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF636E72),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.dark,
          primary: _primaryColor,
          secondary: _secondaryColor,
        ),
      );
}

class AppColors {
  static const primary = Color(0xFF6C63FF);
  static const secondary = Color(0xFFFF6B6B);
  static const success = Color(0xFF00B894);
  static const warning = Color(0xFFFDCB6E);
  static const error = Color(0xFFE17055);

  static const star = Color(0xFFFFD93D);
  static const starEmpty = Color(0xFFDFE6E9);

  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSecondary = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSuccess = LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF55EFC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
