import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

class AppSnack {
  AppSnack._();

  static void success(String message) => _show(
        'Done',
        message,
        AppColors.success,
        Icons.check_circle_outline_rounded,
      );

  static void error(String message) => _show(
        'Something went wrong',
        message,
        AppColors.danger,
        Icons.error_outline_rounded,
      );

  static void _show(String title, String message, Color color, IconData icon) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      icon: Icon(icon, color: Colors.white),
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 450),
      forwardAnimationCurve: Curves.easeOutCubic,
    );
  }
}
