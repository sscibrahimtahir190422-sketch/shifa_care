import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandLogo(size: 104)
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(
                  begin: const Offset(0.6, 0.6),
                  duration: 800.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 28),
            const Text(
              AppConfig.appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ).animate(delay: 450.ms).fadeIn(duration: 600.ms).slideY(begin: 0.3),
            const SizedBox(height: 8),
            const Text(
              AppConfig.tagline,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ).animate(delay: 800.ms).fadeIn(duration: 600.ms),
            const SizedBox(height: 56),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            ).animate(delay: 1100.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}
