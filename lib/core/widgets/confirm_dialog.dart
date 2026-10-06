import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

class ConfirmDialog {
  ConfirmDialog._();

  static Future<bool> show({
    required String title,
    required String message,
    String confirmLabel = 'Yes',
    bool destructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: destructive ? AppColors.danger : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
