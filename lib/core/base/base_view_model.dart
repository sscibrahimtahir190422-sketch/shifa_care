import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../utils/app_snack.dart';
import '../utils/error_handler.dart';


abstract class BaseViewModel extends GetxController {
  final isLoading = false.obs;

  Future<T?> guard<T>(
    Future<T> Function() action, {
    bool showLoader = true,
    bool showError = true,
  }) async {
    if (showLoader) isLoading.value = true;
    try {
      return await action();
    } catch (e, st) {
      debugPrint('$runtimeType error: $e\n$st');
      if (showError) AppSnack.error(friendlyError(e));
      return null;
    } finally {
      if (showLoader) isLoading.value = false;
    }
  }

  Future<bool> run(
    Future<void> Function() action, {
    bool showLoader = true,
    bool showError = true,
  }) async {
    final result = await guard<bool>(
      () async {
        await action();
        return true;
      },
      showLoader: showLoader,
      showError: showError,
    );
    return result ?? false;
  }
}
