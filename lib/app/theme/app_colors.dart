import 'package:flutter/material.dart';

/// Central color palette for Habit Mastery League.
/// All colors are defined here — never hardcode hex values elsewhere.
class AppColors {
  AppColors._();

  // --- Primary brand ---
  static const Color primaryPurple = Color(0xFF6C3DE8);
  static const Color primaryPurpleLight = Color(0xFF9B6EFF);
  static const Color primaryPurpleDark = Color(0xFF4A1FC8);

  // --- Accent / gamification ---
  static const Color accentGold = Color(0xFFFFB800);
  static const Color accentGoldLight = Color(0xFFFFD54F);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentRed = Color(0xFFE74C3C);
  static const Color accentBlue = Color(0xFF3498DB);

  // --- Streak & reward colors ---
  static const Color streakFire = Color(0xFFFF6B35);
  static const Color shieldBlue = Color(0xFF2980B9);
  static const Color badgeGold = Color(0xFFFFD700);
  static const Color badgeSilver = Color(0xFFC0C0C0);
  static const Color badgeBronze = Color(0xFFCD7F32);

  // --- Light theme surfaces ---
  static const Color lightBackground = Color(0xFFF8F6FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0EBFF);
  static const Color lightDivider = Color(0xFFE0D8F8);

  // --- Dark theme surfaces ---
  static const Color darkBackground = Color(0xFF0F0A1E);
  static const Color darkSurface = Color(0xFF1A1030);
  static const Color darkCard = Color(0xFF231845);
  static const Color darkDivider = Color(0xFF352860);

  // --- Text ---
  static const Color textDark = Color(0xFF1A1030);
  static const Color textMedium = Color(0xFF5A4E7C);
  static const Color textLight = Color(0xFF9B8EC4);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // --- Difficulty level indicators ---
  static const Color difficultyEasy = Color(0xFF2ECC71);
  static const Color difficultyMedium = Color(0xFFFFB800);
  static const Color difficultyHard = Color(0xFFE74C3C);

  /// Color options for habit category tags (indexed by Habit.colorIndex).
  static const List<Color> categoryColors = [
    Color(0xFF6C3DE8), // purple (default)
    Color(0xFF2ECC71), // health green
    Color(0xFF3498DB), // blue
    Color(0xFFFF6B35), // orange
    Color(0xFFE74C3C), // red
    Color(0xFF9B59B6), // violet
    Color(0xFF1ABC9C), // teal
    Color(0xFFF39C12), // yellow
  ];
}
