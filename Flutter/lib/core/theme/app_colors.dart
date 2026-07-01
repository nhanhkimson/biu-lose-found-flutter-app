import 'package:flutter/material.dart';

/// Semantic colors aligned with biu-lost-found `globals.css`.
abstract final class AppColors {
  // Brand
  static const Color primaryLight = Color(0xFFC9970C);
  static const Color primaryHoverLight = Color(0xFFA87408);
  static const Color primaryDark = Color(0xFFE5B82E);
  static const Color navyLight = Color(0xFF1B2540);
  static const Color navyDark = Color(0xFFEEF2FF);

  // Surfaces — light
  static const Color backgroundLight = Color(0xFFF3F6FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMutedLight = Color(0xFFE9EEF7);
  static const Color borderLight = Color(0xFFD4DCE9);

  // Surfaces — dark
  static const Color backgroundDark = Color(0xFF0B1020);
  static const Color surfaceDark = Color(0xFF131B2E);
  static const Color surfaceMutedDark = Color(0xFF1A243C);
  static const Color borderDark = Color(0xFF2A3654);

  // Text
  static const Color foregroundLight = Color(0xFF1B2540);
  static const Color mutedForegroundLight = Color(0xFF5C677F);
  static const Color foregroundDark = Color(0xFFEEF2FF);
  static const Color mutedForegroundDark = Color(0xFF9AA8C4);

  // Lost / found badges
  static const Color lost = Color(0xFFC0392B);
  static const Color lostMutedLight = Color(0xFFFDECEA);
  static const Color lostForegroundLight = Color(0xFF922B21);
  static const Color lostDark = Color(0xFFF87171);
  static const Color lostMutedDark = Color(0x24F87171);

  static const Color found = Color(0xFF0F766E);
  static const Color foundMutedLight = Color(0xFFE0F5F2);
  static const Color foundForegroundLight = Color(0xFF115E59);
  static const Color foundDark = Color(0xFF2DD4BF);
  static const Color foundMutedDark = Color(0x242DD4BF);

  static const Color success = Color(0xFF15803D);
  static const Color danger = Color(0xFFB91C1C);

  static ColorScheme lightScheme() {
    return const ColorScheme.light(
      primary: primaryLight,
      onPrimary: Colors.white,
      secondary: found,
      surface: surfaceLight,
      onSurface: foregroundLight,
      error: danger,
    );
  }

  static ColorScheme darkScheme() {
    return const ColorScheme.dark(
      primary: primaryDark,
      onPrimary: backgroundDark,
      secondary: foundDark,
      surface: surfaceDark,
      onSurface: foregroundDark,
      error: danger,
    );
  }
}
