import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2C3E50), // Dark blue-grey
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1A1A1A), // Very dark background
    );
  }

  // Common colors used throughout the app
  static const Color primaryColor = Color(0xFF2C3E50);
  static const Color backgroundColor = Color(0xFF1A1A1A);
  static const Color cardColor = Color(0xFF2C3E50);
  static const Color workColor = Color(0xFFE74C3C); // Red for work periods
  static const Color restColor = Color(0xFF27AE60); // Green for rest periods
}
