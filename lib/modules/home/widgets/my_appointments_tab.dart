import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/fmt.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/appointment.dart';
import '../my_appointments_view_model.dart';
import 'appointment_feedback_sheet.dart';

class MyAppointmentsTab extends StatelessWidget {
  const MyAppointmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<MyAppointmentsViewModel>();

    return RefreshIndicator(
      onRefresh: vm.load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My visits',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap a token to follow your queue live.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Obx(() {
                if (vm.isLoading.value && vm.appointments.isEmpty) {
                  return const Column(
                    children: [SkeletonBox(), SkeletonBox(), SkeletonBox()],
                  );
                }
                if (vm.appointments.isEmpty) {
                  return const EmptyState(
                    icon: Icons.event_available_rounded,
                    title: 'No visits yet',
                    message: 'Book an appointment from the Home tab and your token will appear here.',
                  );
                }
                final upcoming = vm.upcoming;
                final history = vm.history;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (upcoming.isNotEmpty) ...[
                      const _SectionTitle('Upcoming'),
                      for (var i = 0; i < upcoming.length; i++)
                        _AppointmentTile(
                          key: ValueKey(upcoming[i].id),
                          appointment: upcoming[i],
                          index: i,
                          onTap: () => vm.open(upcoming[i]),
                          onReschedule: upcoming[i].status == AppointmentStatus.waiting
                              ? () => _showRescheduleSheet(context, vm, upcoming[i])
                              : null,
                          onCancel: upcoming[i].status == AppointmentStatus.waiting
                              ? () => vm.cancel(upcoming[i])
                              : null,
                        ),
                    ],
                    if (history.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const _SectionTitle('Past visits'),
                      for (var i = 0; i < history.length; i++)
                        _AppointmentTile(
                          key: ValueKey(history[i].id),
                          appointment: history[i],
                          index: i,
                          onRate: history[i].status == AppointmentStatus.completed
                              ? () => AppointmentFeedbackSheet.show(context, vm, history[i])
                              : null,
                        ),
                    ],
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showRescheduleSheet(
  BuildContext context,
  MyAppointmentsViewModel vm,
  Appointment appointment,
) async {
  final picked = await showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final days = vm.rescheduleDays;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Move to a new day',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Token #${appointment.token} with ${appointment.doctor?.fullName ?? 'your doctor'}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final day in days)
                    if (!Fmt.isSameDay(day, appointment.date))
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(ctx).pop(day),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text(
                                Fmt.shortDay(day),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              Text(
                                '${day.day}',
                                style: const TextStyle(color: AppColors.primaryDark, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  if (picked != null) await vm.reschedule(appointment, picked);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({
    super.key,
    required this.appointment,
    required this.index,
    this.onTap,
    this.onReschedule,
    this.onCancel,
    this.onRate,
  });

  final Appointment appointment;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;
  final VoidCallback? onRate;

  @override
  Widget build(BuildContext context) {
    final doctor = appointment.doctor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.softShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '#${appointment.token}',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor?.fullName ?? 'Doctor',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Fmt.longDate(appointment.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: appointment.status),
                  if (onRate != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                      tooltip: 'Rate visit',
                      onPressed: onRate,
                    ),
                  ],
                  if (onReschedule != null || onCancel != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                      onSelected: (value) {
                        if (value == 'reschedule') onReschedule?.call();
                        if (value == 'cancel') onCancel?.call();
                      },
                      itemBuilder: (context) => [
                        if (onReschedule != null)
                          const PopupMenuItem(
                            value: 'reschedule',
                            child: Row(
                              children: [
                                Icon(Icons.event_repeat_rounded, size: 18, color: AppColors.primaryDark),
                                SizedBox(width: 10),
                                Text('Reschedule'),
                              ],
                            ),
                          ),
                        if (onCancel != null)
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(Icons.close_rounded, size: 18, color: AppColors.danger),
                                SizedBox(width: 10),
                                Text('Cancel'),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index), duration: 400.ms).slideX(begin: 0.08);
  }
}
