import 'package:flutter/material.dart';

/// Calm, minimalist color palette designed for low visual fatigue.
class AppColors {
  AppColors._();

  // Light Palette
  static const Color lightBg = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightGridBg = Color(0xFFE9ECF0);
  static const Color lightCellEmpty = Color(0xFFDFE4EA);
  static const Color lightTextPrimary = Color(0xFF2D3748);
  static const Color lightTextSecondary = Color(0xFF718096);

  // Dark Palette
  static const Color darkBg = Color(0xFF13151A);
  static const Color darkSurface = Color(0xFF1D2028);
  static const Color darkGridBg = Color(0xFF252934);
  static const Color darkCellEmpty = Color(0xFF2C313E);
  static const Color darkTextPrimary = Color(0xFFF7FAFC);
  static const Color darkTextSecondary = Color(0xFFA0AEC0);

  // Muted Accent Tones
  static const Color primarySage = Color(0xFF4A8072);
  static const Color primarySageLight = Color(0xFFD4E5DF);
  static const Color heartRed = Color(0xFFE53E3E);
  static const Color hintGold = Color(0xFFD69E2E);
  static const Color guidanceGreen = Color(0xFF38A169);
  static const Color blockerRed = Color(0xFFE53E3E);

  // Arrow Color Variants (harmonious calm tones)
  static const List<Color> lightArrowVariants = [
    Color(0xFF4A8072), // Calm Sage
    Color(0xFF4A6B82), // Slate Blue
    Color(0xFF7A6B8C), // Muted Amethyst
    Color(0xFF8B6B58), // Warm Terracotta
    Color(0xFF5A7B85), // Teal Fog
  ];

  static const List<Color> darkArrowVariants = [
    Color(0xFF68B29E), // Luminous Sage
    Color(0xFF6CA0C2), // Soft Blue
    Color(0xFFA590BD), // Lavender Frost
    Color(0xFFBA9077), // Warm Clay
    Color(0xFF7AB2BF), // Cyan Frost
  ];

  static Color getArrowColor(int variant, bool isDark) {
    final list = isDark ? darkArrowVariants : lightArrowVariants;
    return list[variant % list.length];
  }
}
