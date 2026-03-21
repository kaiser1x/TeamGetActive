import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reusable text styles for Habit Mastery League.
/// Use these instead of inline TextStyle declarations.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textDark,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textDark,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textMedium,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textMedium,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textDark,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  // --- Gamification specific ---

  static const TextStyle xpPoints = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.accentGold,
    letterSpacing: 0.5,
  );

  static const TextStyle streakCount = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w900,
    color: AppColors.streakFire,
  );

  /// Used for level labels like "LEAGUE", "LV. 5", etc.
  static const TextStyle levelLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryPurple,
    letterSpacing: 1.0,
  );
}
