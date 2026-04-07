import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2F80ED);
  static const Color secondary = Color(0xFF27AE60);
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF111827);
  static const Color muted = Color(0xFF6B7280);
  static const Color border = Color(0x14000000); // 8% Black
  static const Color primary10 = Color(0xFFEAF2FF);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      fontFamily: 'Inter', // Nhớ thêm font Inter vào pubspec.yaml
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text, height: 36/28),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text, height: 26/18),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text, height: 24/16),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.text, height: 22/14),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.muted, height: 18/12),
      ),
    );
  }
}