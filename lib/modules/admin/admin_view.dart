import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/animated_number.dart';
import '../../core/widgets/gradient_header.dart';
import '../../core/widgets/live_dot.dart';
import '../../core/widgets/skeleton_box.dart';
import '../../data/repositories/stats_repository.dart';
import 'admin_view_model.dart';

class AdminView extends GetView<AdminViewModel> {
  const AdminView({super.key});

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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Obx(() {
                final stats = controller.stats.value;
                if (controller.isLoading.value && stats == null) {
                  return const Column(
                    children: [SkeletonBox(height: 90), SkeletonBox(height: 160), SkeletonBox()],
                  );
                }
                if (stats == null) return const SizedBox.shrink();
                return _Body(stats: stats);
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final AdminViewModel controller;

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      bottomRadius: 36,
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LiveDot(color: Colors.white, size: 8),
              const SizedBox(width: 4),
              Expanded(
                child: Obx(() {
                  final t = controller.lastUpdated.value;
                  return Text(
                    t == null ? "Today's overview" : "Today's overview · updated ${Fmt.shortTime(t)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  );
                }),
              ),
              IconButton(
                onPressed: () => controller.load(),
                tooltip: 'Refresh now',
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
              IconButton(
                onPressed: controller.logout,
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
          const Text(
            'HOD dashboard',
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          const Text(
            'Live patient flow across all departments',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.stats});

  final HospitalStatsToday stats;

  @override
  Widget build(BuildContext context) {
    final busiest = stats.busiestDepartment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Patients today',
                value: stats.totalPatientsToday,
                icon: Icons.groups_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Completed',
                value: stats.totalCompletedToday,
                icon: Icons.task_alt_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Average wait time today',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${stats.avgWaitMinutesToday.toStringAsFixed(0)} min',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (busiest != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Busiest department',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      busiest.department,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _TrendChart(),
        const SizedBox(height: 24),
        const Text('By department', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (var i = 0; i < stats.byDepartment.length; i++)
          _DepartmentTile(stat: stats.byDepartment[i], index: i),
        const SizedBox(height: 24),
        const Text('By doctor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (var i = 0; i < stats.byDoctor.length; i++)
          _DoctorLoadTile(stat: stats.byDoctor[i], index: i),
      ],
    );
  }
}


class _TrendChart extends StatelessWidget {
  const _TrendChart();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminViewModel>();

    return Obx(() {
      final days = controller.trend.toList();
      if (days.isEmpty) return const SizedBox.shrink();

      final booked = <FlSpot>[];
      final done = <FlSpot>[];
      var maxY = 4.0;
      for (var i = 0; i < days.length; i++) {
        booked.add(FlSpot(i.toDouble(), days[i].patients.toDouble()));
        done.add(FlSpot(i.toDouble(), days[i].completed.toDouble()));
        if (days[i].patients > maxY) maxY = days[i].patients.toDouble();
      }
      maxY = (maxY * 1.25).ceilToDouble();

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 18, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 7 days',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                _LegendDot(color: AppColors.primary, label: 'Booked'),
                SizedBox(width: 16),
                _LegendDot(color: AppColors.success, label: 'Completed'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (days.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppColors.border, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value != value.roundToDouble()) return const SizedBox.shrink();
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= days.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              Fmt.shortDay(days[i].date),
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: booked,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withAlpha(30),
                      ),
                    ),
                    LineChartBarData(
                      spots: done,
                      isCurved: true,
                      color: AppColors.success,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
              ),
            ),
          ],
        ),
      );
    }).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, curve: Curves.easeOutCubic);
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedNumber(
                  value: value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentTile extends StatelessWidget {
  const _DepartmentTile({required this.stat, required this.index});

  final DepartmentStat stat;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(stat.department, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          _MiniStat(label: 'Today', value: '${stat.patientsToday}'),
          const SizedBox(width: 14),
          _MiniStat(label: 'Done', value: '${stat.completedToday}'),
          const SizedBox(width: 14),
          _MiniStat(label: 'Wait', value: '${stat.avgWaitMinutes.toStringAsFixed(0)}m'),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 350.ms).slideX(begin: 0.06);
  }
}

class _DoctorLoadTile extends StatelessWidget {
  const _DoctorLoadTile({required this.stat, required this.index});

  final DoctorLoadStat stat;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  stat.department,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (stat.onLeave)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(28),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'On leave',
                style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            )
          else ...[
            if (stat.fullyBookedToday) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Fully booked',
                  style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
            ],
            _MiniStat(label: 'Today', value: '${stat.patientsToday}'),
            const SizedBox(width: 14),
            _MiniStat(label: 'Done', value: '${stat.completedToday}'),
          ],
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 350.ms).slideX(begin: 0.06);
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}