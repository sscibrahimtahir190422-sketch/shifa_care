import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/doctor_avatar.dart';
import '../../core/widgets/gradient_header.dart';
import '../../core/widgets/primary_button.dart';
import 'booking_view_model.dart';

class BookingView extends GetView<BookingViewModel> {
  const BookingView({super.key});

  @override
  Widget build(BuildContext context) {
    final doctor = controller.doctor;

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            bottomRadius: 32,
            padding: const EdgeInsets.fromLTRB(8, 4, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    const Text(
                      'Book appointment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      DoctorAvatar(doctor: doctor, size: 64),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${doctor.specialty}  |  ${doctor.room}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.06),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                const Text(
                  'Choose a day',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _DayStrip(controller: controller),
                const SizedBox(height: 24),
                _QueueInfo(controller: controller),
                const SizedBox(height: 24),
                const Text(
                  'Reason for visit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: controller.reasonCtrl,
                  label: 'Symptoms or notes (optional)',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
              ].animate(interval: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.06),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Obx(
            () => PrimaryButton(
              label: 'Confirm booking',
              icon: Icons.check_rounded,
              isLoading: controller.isLoading.value,
              onPressed: controller.confirm,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.controller});

  final BookingViewModel controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Obx(() {
        final selected = controller.selectedDate.value;
        final days = controller.days;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final day = days[i];
            final isSelected = Fmt.isSameDay(day, selected);
            final fg = isSelected ? Colors.white : AppColors.textPrimary;
            return GestureDetector(
              onTap: () => controller.selectDate(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: 64,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.heroGradient : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppColors.border,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(70),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : const [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      i == 0 ? 'Today' : Fmt.shortDay(day),
                      style: TextStyle(color: fg.withAlpha(200), fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Fmt.dayNumber(day),
                      style: TextStyle(
                        color: fg,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      Fmt.month(day),
                      style: TextStyle(color: fg.withAlpha(200), fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _QueueInfo extends StatelessWidget {
  const _QueueInfo({required this.controller});

  final BookingViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoadingQueue.value;
      final waiting = controller.queueSize.value;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: _InfoItem(
                icon: Icons.groups_rounded,
                label: 'In queue',
                value: loading ? '...' : '$waiting',
              ),
            ),
            Container(width: 1, height: 40, color: AppColors.sky),
            Expanded(
              child: _InfoItem(
                icon: Icons.timer_outlined,
                label: 'Est. wait',
                value: loading
                    ? '...'
                    : controller.isToday
                        ? Fmt.wait(controller.estimatedMinutes)
                        : 'On the day',
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            value,
            key: ValueKey(value),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
