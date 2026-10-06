import 'doctor.dart';

enum AppointmentStatus {
  waiting('waiting', 'Waiting'),
  inProgress('in_progress', 'In consultation'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  const AppointmentStatus(this.value, this.label);


  final String value;
  final String label;

  static AppointmentStatus parse(String? value) => AppointmentStatus.values
      .firstWhere((s) => s.value == value, orElse: () => AppointmentStatus.waiting);
}

class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.date,
    required this.token,
    required this.status,
    this.reason,
    this.doctor,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final DateTime date;
  final int token;
  final AppointmentStatus status;
  final String? reason;

  final Doctor? doctor;

  bool get isActive =>
      status == AppointmentStatus.waiting ||
      status == AppointmentStatus.inProgress;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final doc = json['doctors'];
    return Appointment(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      patientName: (json['patient_name'] as String?) ?? 'Patient',
      doctorId: json['doctor_id'] as String,
      date: DateTime.parse(json['appointment_date'] as String),
      token: (json['token_number'] as num).toInt(),
      status: AppointmentStatus.parse(json['status'] as String?),
      reason: json['reason'] as String?,
      doctor: doc is Map<String, dynamic> ? Doctor.fromJson(doc) : null,
    );
  }

  Appointment withDoctor(Doctor? newDoctor) => Appointment(
        id: id,
        patientId: patientId,
        patientName: patientName,
        doctorId: doctorId,
        date: date,
        token: token,
        status: status,
        reason: reason,
        doctor: newDoctor ?? doctor,
      );
}
