import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/services/session_service.dart';
import '../../core/base/base_view_model.dart';
import '../../core/utils/app_snack.dart';
import '../../data/repositories/auth_repository.dart';

class AuthViewModel extends BaseViewModel {
  AuthViewModel(this._auth, this._session);

  final AuthRepository _auth;
  final SessionService _session;

  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  final isLogin = true.obs;
  final obscure = true.obs;

  void toggleMode() => isLogin.toggle();

  void toggleObscure() => obscure.toggle();

  Future<void> submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(formKey.currentState?.validate() ?? false)) return;

    await run(() async {
      final email = emailCtrl.text.trim();

      if (isLogin.value) {
        await _auth.signIn(email: email, password: passwordCtrl.text);
      } else {
        final signedIn = await _auth.signUp(
          fullName: nameCtrl.text.trim(),
          email: email,
          password: passwordCtrl.text,
        );
        if (!signedIn) {
          AppSnack.success('Account created. Please confirm your email, then sign in.');
          isLogin.value = true;
          return;
        }
      }

      await _session.loadProfile();
      Get.offAllNamed(_session.homeRoute);
    });
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
