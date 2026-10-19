class Doctor {
  const Doctor({
    required this.id,
    required this.fullName,
    required this.specialty,
    required this.department,
    required this.room,
    required this.avgMinutes,
    required this.experienceYears,
    this.onLeave = false,
    this.fullyBookedUntil,
  });

  final String id;
  final String fullName;
  final String specialty;
  final String department;
  final String room;
  final int avgMinutes;
  final int experienceYears;
  final bool onLeave;


  final DateTime? fullyBookedUntil;

  bool get isFullyBookedToday {
    final d = fullyBookedUntil;
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
    id: json['id'] as String,
    fullName: json['full_name'] as String,
    specialty: json['specialty'] as String,
    department: json['department'] as String,
    room: json['room'] as String,
    avgMinutes: (json['avg_minutes'] as num).toInt(),
    experienceYears: (json['experience_years'] as num).toInt(),
    onLeave: json['on_leave'] as bool? ?? false,
    fullyBookedUntil: json['fully_booked_until'] == null
        ? null
        : DateTime.parse(json['fully_booked_until'] as String),
  );

  /// [fullyBookedToday]: true = closed for today, false = reopened.
  Doctor copyWith({bool? onLeave, bool? fullyBookedToday}) => Doctor(
    id: id,
    fullName: fullName,
    specialty: specialty,
    department: department,
    room: room,
    avgMinutes: avgMinutes,
    experienceYears: experienceYears,
    onLeave: onLeave ?? this.onLeave,
    fullyBookedUntil: fullyBookedToday == null
        ? fullyBookedUntil
        : (fullyBookedToday ? DateTime.now() : null),
  );

  String get initials {
    final parts = fullName
        .replaceAll('Dr.', '')
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'DR';
    final last = parts.length > 1 ? parts.last[0] : '';
    return (parts.first[0] + last).toUpperCase();
  }
}
