import 'package:flutter/material.dart';

import '../../data/models/doctor.dart';
import '../theme/app_colors.dart';

class DoctorAvatar extends StatelessWidget {
  const DoctorAvatar({super.key, required this.doctor, this.size = 56});

  final Doctor doctor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.sky, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        doctor.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}
