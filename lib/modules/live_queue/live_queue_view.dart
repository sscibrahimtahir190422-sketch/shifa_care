import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/animated_number.dart';
import '../../core/widgets/doctor_avatar.dart';
import '../../core/widgets/gradient_header.dart';
import '../../core/widgets/live_dot.dart';
import '../../data/models/appointment.dart';
import 'live_queue_view_model.dart';

class LiveQueueView extends GetView<LiveQueueViewModel> {
  const LiveQueueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.loadState,
        edgeOffset: 120,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            GradientHeader(
              bottomRadius: 40,
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 36),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      ),
                      const Expanded(
                        child: Text(
                          'Live queue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const _LivePill(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => _TokenRing(
                      token: controller.current.token,
                      progress: controller.progress,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        curve: Curves.easeOutBack,
                        duration: 700.ms,
                      ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _Details(controller: controller),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.06),
          ],
        ),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 12, 2),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(36),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiveDot(color: Colors.white, size: 8),
          SizedBox(width: 2),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenRing extends StatelessWidget {
  const _TokenRing({required this.token, required this.progress});

  final int token;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => SizedBox.expand(
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 12,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'YOUR TOKEN',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AnimatedNumber(
                value: token,
                prefix: '#',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 60,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.controller});

  final LiveQueueViewModel controller;

  Color _accent(AppointmentStatus status) => switch (status) {
        AppointmentStatus.waiting => AppColors.primary,
        AppointmentStatus.inProgress => AppColors.success,
        AppointmentStatus.completed => AppColors.success,
        AppointmentStatus.cancelled => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) => Obx(_content);

  Widget _content() {
    final status = controller.status;
    final accent = _accent(status);
    final doctor = controller.current.doctor;
    final serving = controller.nowServing.value;
    final showWait = status == AppointmentStatus.waiting && controller.isToday;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: accent.withAlpha(24),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withAlpha(90)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Text(
                  controller.headline,
                  key: ValueKey(controller.headline),
                  style: TextStyle(
                    color: accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                controller.subline,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.record_voice_over_rounded,
                label: 'Now serving',
                value: serving == 0
                    ? const Text('-', style: _valueStyle)
                    : AnimatedNumber(value: serving, prefix: '#', style: _valueStyle),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.timer_outlined,
                label: 'Est. wait',
                value: Text(
                  showWait ? Fmt.wait(controller.etaMinutes) : '-',
                  style: _valueStyle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (doctor != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              children: [
                DoctorAvatar(doctor: doctor, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Text(
                        '${doctor.specialty}  |  ${doctor.room}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Fmt.longDate(controller.current.date),
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (status == AppointmentStatus.waiting) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: controller.isLoading.value ? null : controller.cancel,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancel appointment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

const _valueStyle = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w700,
  color: AppColors.primaryDark,
);

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          value,
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
