import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/animated_number.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/gradient_header.dart';
import '../../core/widgets/live_dot.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/skeleton_box.dart';
import '../../data/models/appointment.dart';
import '../../data/repositories/stats_repository.dart';
import 'doctor_view_model.dart';

class DoctorView extends GetView<DoctorViewModel> {
  const DoctorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.load,
        edgeOffset: 120,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _Header(controller: controller),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Obx(() {
                if (controller.isLoading.value && controller.doctor.value == null) {
                  return const Column(children: [SkeletonBox(height: 150), SkeletonBox()]);
                }
                if (controller.notLinked.value) {
                  return const EmptyState(
                    icon: Icons.link_off_rounded,
                    title: 'Account not linked',
                    message:
                        'This login is not linked to a doctor profile yet. Ask the administrator to link it.',
                  );
                }
                return _Body(controller: controller);
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Obx(
            () => PrimaryButton(
              label: controller.advanceLabel,
              icon: Icons.skip_next_rounded,
              isLoading: controller.isCalling.value,
              onPressed: controller.canAdvance ? controller.advance : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final DoctorViewModel controller;

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      bottomRadius: 36,
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LiveDot(color: Colors.white, size: 8),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Today\'s clinic',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              IconButton(
                onPressed: controller.logout,
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
          Obx(() {
            final doctor = controller.doctor.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor?.fullName ?? 'Doctor dashboard',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doctor == null
                      ? Fmt.longDate(controller.today)
                      : '${doctor.room}  |  ${Fmt.longDate(controller.today)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            );
          }),
          const SizedBox(height: 14),
          Obx(() {
            final doctor = controller.doctor.value;
            if (doctor == null) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    doctor.onLeave ? Icons.event_busy_rounded : Icons.event_available_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doctor.onLeave ? 'On leave — booking paused' : 'Available for booking',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: doctor.onLeave,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.brandRed.withAlpha(160),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.white.withAlpha(70),
                    onChanged: controller.isTogglingLeave.value
                        ? null
                        : (_) => controller.toggleLeave(),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Obx(
              () => Row(
                children: [
                  Expanded(child: _HeaderStat(label: 'Waiting', value: controller.waiting.length)),
                  const SizedBox(width: 10),
                  Expanded(child: _HeaderStat(label: 'Completed', value: controller.completedCount)),
                  const SizedBox(width: 10),
                  Expanded(child: _HeaderStat(label: 'Total', value: controller.queue.length)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(34),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          AnimatedNumber(
            value: value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller});

  final DoctorViewModel controller;

  @override
  Widget build(BuildContext context) => Obx(_content);

  Widget _content() {
    final current = controller.current;
    final waiting = controller.waiting;
    final stats = controller.todayStats.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stats != null) ...[
          _StatsStrip(stats: stats),
          const SizedBox(height: 24),
        ],
        const Text(
          'Now consulting',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: current == null
              ? const _NoCurrent(key: ValueKey('none'))
              : _CurrentCard(key: ValueKey(current.id), appointment: current),
        ),
        const SizedBox(height: 24),
        Text(
          waiting.isEmpty ? 'Up next' : 'Up next (${waiting.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (waiting.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No patients are waiting.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          for (var i = 0; i < waiting.length; i++)
            _WaitingTile(key: ValueKey(waiting[i].id), appointment: waiting[i], index: i),
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.stats});

  final DoctorStatsToday stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.hourglass_bottom_rounded,
            label: 'Avg wait',
            value: '${stats.avgWaitMinutes.toStringAsFixed(0)}m',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Avg consult',
            value: '${stats.avgConsultMinutes.toStringAsFixed(0)}m',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.star_rounded,
            label: 'Rating',
            value: stats.avgRating > 0 ? stats.avgRating.toStringAsFixed(1) : '—',
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _NoCurrent extends StatelessWidget {
  const _NoCurrent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_empty_rounded, color: AppColors.textSecondary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No one is in consultation. Tap the button below to call the next patient.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentCard extends StatelessWidget {
  const _CurrentCard({super.key, required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final reason = appointment.reason;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(80),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '#${appointment.token}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (reason == null || reason.isEmpty) ? 'No reason provided' : reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingTile extends StatelessWidget {
  const _WaitingTile({super.key, required this.appointment, required this.index});

  final Appointment appointment;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
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
            child: Text(
              appointment.patientName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (index == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(36),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 350.ms).slideX(begin: 0.06);
  }
}
