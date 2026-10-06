import 'package:supabase_flutter/supabase_flutter.dart';


class DoctorStatsToday {
  const DoctorStatsToday({
    required this.patientsCompleted,
    required this.patientsWaiting,
    required this.avgWaitMinutes,
    required this.avgConsultMinutes,
    required this.avgRating,
  });

  final int patientsCompleted;
  final int patientsWaiting;
  final double avgWaitMinutes;
  final double avgConsultMinutes;
  final double avgRating;

  factory DoctorStatsToday.fromJson(Map<String, dynamic> json) => DoctorStatsToday(
        patientsCompleted: (json['patients_completed'] as num?)?.toInt() ?? 0,
        patientsWaiting: (json['patients_waiting'] as num?)?.toInt() ?? 0,
        avgWaitMinutes: (json['avg_wait_minutes'] as num?)?.toDouble() ?? 0,
        avgConsultMinutes: (json['avg_consult_minutes'] as num?)?.toDouble() ?? 0,
        avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      );
}

class DepartmentStat {
  const DepartmentStat({
    required this.department,
    required this.patientsToday,
    required this.completedToday,
    required this.avgWaitMinutes,
  });

  final String department;
  final int patientsToday;
  final int completedToday;
  final double avgWaitMinutes;

  factory DepartmentStat.fromJson(Map<String, dynamic> json) => DepartmentStat(
        department: json['department'] as String? ?? 'Unknown',
        patientsToday: (json['patients_today'] as num?)?.toInt() ?? 0,
        completedToday: (json['completed_today'] as num?)?.toInt() ?? 0,
        avgWaitMinutes: (json['avg_wait_minutes'] as num?)?.toDouble() ?? 0,
      );
}

class DoctorLoadStat {
  const DoctorLoadStat({
    required this.id,
    required this.fullName,
    required this.department,
    required this.onLeave,
    required this.patientsToday,
    required this.completedToday,
  });

  final String id;
  final String fullName;
  final String department;
  final bool onLeave;
  final int patientsToday;
  final int completedToday;

  factory DoctorLoadStat.fromJson(Map<String, dynamic> json) => DoctorLoadStat(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        department: json['department'] as String? ?? '',
        onLeave: json['on_leave'] as bool? ?? false,
        patientsToday: (json['patients_today'] as num?)?.toInt() ?? 0,
        completedToday: (json['completed_today'] as num?)?.toInt() ?? 0,
      );
}

class HospitalStatsToday {
  const HospitalStatsToday({
    required this.totalPatientsToday,
    required this.totalCompletedToday,
    required this.avgWaitMinutesToday,
    required this.byDepartment,
    required this.byDoctor,
  });

  final int totalPatientsToday;
  final int totalCompletedToday;
  final double avgWaitMinutesToday;
  final List<DepartmentStat> byDepartment;
  final List<DoctorLoadStat> byDoctor;


  DepartmentStat? get busiestDepartment =>
      byDepartment.isEmpty ? null : byDepartment.first;

  factory HospitalStatsToday.fromJson(Map<String, dynamic> json) => HospitalStatsToday(
        totalPatientsToday: (json['total_patients_today'] as num?)?.toInt() ?? 0,
        totalCompletedToday: (json['total_completed_today'] as num?)?.toInt() ?? 0,
        avgWaitMinutesToday: (json['avg_wait_minutes_today'] as num?)?.toDouble() ?? 0,
        byDepartment: ((json['by_department'] as List?) ?? [])
            .map((e) => DepartmentStat.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        byDoctor: ((json['by_doctor'] as List?) ?? [])
            .map((e) => DoctorLoadStat.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class StatsRepository {
  StatsRepository(this._client);

  final SupabaseClient _client;

  Future<DoctorStatsToday> fetchDoctorStatsToday() async {
    final res = await _client.rpc('doctor_stats_today');
    return DoctorStatsToday.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<HospitalStatsToday> fetchHospitalStatsToday() async {
    final res = await _client.rpc('hospital_stats_today');
    return HospitalStatsToday.fromJson(Map<String, dynamic>.from(res as Map));
  }
}
