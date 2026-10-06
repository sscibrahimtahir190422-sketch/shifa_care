import 'package:flutter/material.dart';


class AppColors {
  AppColors._();

  static const primary = Color(0xFF008FD7);
  static const primaryDark = Color(0xFF005F99);
  static const primaryLight = Color(0xFFE5F4FC);
  static const sky = Color(0xFF8CCEEE);
  static const brandRed = Color(0xFFF12921);

  static const background = Color(0xFFF4F9FC);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF242021);
  static const textSecondary = Color(0xFF6B7A86);
  static const border = Color(0xFFDDEAF3);

  static const success = Color(0xFF1FA971);
  static const warning = Color(0xFFF5A524);
  static const danger = brandRed;

  static const heroGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: primaryDark.withAlpha(22),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
}
