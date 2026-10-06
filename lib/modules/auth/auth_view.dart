import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/gradient_header.dart';
import '../../core/widgets/primary_button.dart';
import 'auth_view_model.dart';

class AuthView extends GetView<AuthViewModel> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            GradientHeader(
              bottomRadius: 40,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 44),
              child: Obx(() => _Header(isLogin: controller.isLogin.value)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Form(
                key: controller.formKey,
                child: Column(
                  children: [
                    Obx(
                      () => AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        child: controller.isLogin.value
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: AppTextField(
                                  controller: controller.nameCtrl,
                                  label: 'Full name',
                                  icon: Icons.person_outline_rounded,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) => Validators.required(v, 'Name'),
                                ),
                              ),
                      ),
                    ),
                    AppTextField(
                      controller: controller.emailCtrl,
                      label: 'Email address',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => AppTextField(
                        controller: controller.passwordCtrl,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: controller.obscure.value,
                        textInputAction: TextInputAction.done,
                        validator: Validators.password,
                        onSubmitted: (_) => controller.submit(),
                        suffix: IconButton(
                          onPressed: controller.toggleObscure,
                          icon: Icon(
                            controller.obscure.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Obx(
                      () => PrimaryButton(
                        label: controller.isLogin.value ? 'Sign in' : 'Create account',
                        isLoading: controller.isLoading.value,
                        onPressed: controller.submit,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: controller.toggleMode,
                      child: Obx(
                        () => Text(
                          controller.isLogin.value
                              ? "New patient? Create an account"
                              : 'Already registered? Sign in',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 150.ms).slideY(
                  begin: 0.08,
                  curve: Curves.easeOutCubic,
                  duration: 600.ms,
                ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isLogin});

  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandLogo(size: 64)
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            isLogin ? 'Welcome back' : 'Create your account',
            key: ValueKey(isLogin),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isLogin
              ? 'Sign in to book visits and track your queue live.'
              : '${AppConfig.appName} makes hospital visits simple.',
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
      ],
    );
  }
}
