import 'package:flutter/material.dart';

import '../theme/app_colors.dart';


class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.child,
    this.bottomRadius = 32,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
  });

  final Widget child;
  final double bottomRadius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
      ),
      child: Stack(
        children: [
          Positioned(right: -40, top: -50, child: _circle(180, 18)),
          Positioned(left: -50, bottom: -70, child: _circle(200, 12)),
          SafeArea(
            bottom: false,
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, int alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha(alpha),
        ),
      );
}
