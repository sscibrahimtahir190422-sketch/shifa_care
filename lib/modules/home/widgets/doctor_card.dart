import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/doctor_avatar.dart';
import '../../../data/models/doctor.dart';

class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor, required this.index});

  final Doctor doctor;
  final int index;

  @override
  Widget build(BuildContext context) {
    final onLeave = doctor.onLeave;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Opacity(
        opacity: onLeave ? 0.6 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.softShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onLeave ? null : () => Get.toNamed(Routes.booking, arguments: doctor),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    DoctorAvatar(doctor: doctor, size: 60),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doctor.specialty,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (onLeave)
                                const _Pill(
                                  icon: Icons.event_busy_rounded,
                                  text: 'On leave today',
                                  danger: true,
                                )
                              else ...[
                                _Pill(icon: Icons.meeting_room_outlined, text: doctor.room),
                                _Pill(
                                  icon: Icons.workspace_premium_outlined,
                                  text: '${doctor.experienceYears} yrs',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!onLeave)
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: min(index * 70, 560)), duration: 450.ms)
        .slideY(begin: 0.15, curve: Curves.easeOutCubic, duration: 450.ms);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, this.danger = false});

  final IconData icon;
  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.primaryDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: danger ? AppColors.danger.withAlpha(28) : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
