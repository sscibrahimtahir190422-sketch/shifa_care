import 'package:flutter/material.dart';

import '../../data/models/appointment.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      AppointmentStatus.waiting => (AppColors.warning, Icons.schedule_rounded),
      AppointmentStatus.inProgress => (
          AppColors.primary,
          Icons.medical_services_rounded
        ),
      AppointmentStatus.completed => (
          AppColors.success,
          Icons.check_circle_rounded
        ),
      AppointmentStatus.cancelled => (AppColors.danger, Icons.cancel_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
