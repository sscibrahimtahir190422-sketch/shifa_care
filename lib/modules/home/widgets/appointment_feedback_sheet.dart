import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/appointment.dart';
import '../my_appointments_view_model.dart';

class AppointmentFeedbackSheet extends StatefulWidget {
  const AppointmentFeedbackSheet({
    super.key,
    required this.appointment,
    required this.vm,
  });

  final Appointment appointment;
  final MyAppointmentsViewModel vm;

  static Future<void> show(BuildContext context, MyAppointmentsViewModel vm, Appointment appointment) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: AppointmentFeedbackSheet(appointment: appointment, vm: vm),
      ),
    );
  }

  @override
  State<AppointmentFeedbackSheet> createState() => _AppointmentFeedbackSheetState();
}

class _AppointmentFeedbackSheetState extends State<AppointmentFeedbackSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  final _ratingLabels = {
    1: 'Poor 😞',
    2: 'Fair 😐',
    3: 'Good 🙂',
    4: 'Very Good 😃',
    5: 'Excellent ⭐',
  };

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await widget.vm.submitRating(
        widget.appointment,
        _rating,
        _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.appointment.doctor;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.star_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rate your visit',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${doctor?.fullName ?? 'Doctor'} · Token #${widget.appointment.token}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      final isSelected = starVal <= _rating;
                      return IconButton(
                        iconSize: 36,
                        icon: Icon(
                          isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isSelected ? Colors.amber[700] : AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _rating = starVal),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _ratingLabels[_rating] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _commentController,
              label: 'Write feedback (optional)',
              icon: Icons.rate_review_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Submit Feedback',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
