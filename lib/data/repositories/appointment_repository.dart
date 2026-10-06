import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/fmt.dart';
import '../models/appointment.dart';
import '../models/queue_status.dart';


class AppointmentRepository {
  AppointmentRepository(this._client);

  final SupabaseClient _client;

  Future<Appointment> book({
    required String doctorId,
    required DateTime date,
    String? reason,
  }) async {
    final res = await _client.rpc('book_appointment', params: {
      'p_doctor_id': doctorId,
      'p_date': Fmt.dayKey(date),
      'p_reason': reason,
    });
    return Appointment.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<void> cancel(String appointmentId) async {
    await _client.rpc('cancel_appointment', params: {'p_id': appointmentId});
  }

  Future<List<Appointment>> fetchMyAppointments(String patientId) async {
    final rows = await _client
        .from('appointments')
        .select('*, doctors(*)')
        .eq('patient_id', patientId)
        .order('appointment_date', ascending: false)
        .order('token_number', ascending: false);
    return rows.map(Appointment.fromJson).toList();
  }

  Future<Appointment> fetchAppointment(String id) async {
    final row = await _client.from('appointments').select().eq('id', id).single();
    return Appointment.fromJson(row);
  }

  Future<QueueStatus> fetchQueueStatus({
    required String doctorId,
    required DateTime date,
  }) async {
    final row = await _client
        .from('queue_status')
        .select()
        .eq('doctor_id', doctorId)
        .eq('queue_date', Fmt.dayKey(date))
        .maybeSingle();
    return row == null ? QueueStatus.empty : QueueStatus.fromJson(row);
  }


  Future<int> fetchPatientsAhead(String appointmentId) async {
    final res = await _client
        .rpc('patients_ahead', params: {'p_appointment_id': appointmentId});
    return (res as num).toInt();
  }


  Future<int> fetchActiveQueueSize({
    required String doctorId,
    required DateTime date,
  }) async {
    final res = await _client.rpc('active_queue_size', params: {
      'p_doctor_id': doctorId,
      'p_date': Fmt.dayKey(date),
    });
    return (res as num).toInt();
  }

  Future<List<Appointment>> fetchDoctorQueue({
    required String doctorId,
    required DateTime date,
  }) async {
    final rows = await _client
        .from('appointments')
        .select()
        .eq('doctor_id', doctorId)
        .eq('appointment_date', Fmt.dayKey(date))
        .neq('status', 'cancelled')
        .order('token_number');
    return rows.map(Appointment.fromJson).toList();
  }

  Future<void> callNext({required String doctorId, required DateTime date}) async {
    await _client.rpc('call_next_patient', params: {
      'p_doctor_id': doctorId,
      'p_date': Fmt.dayKey(date),
    });
  }


  Future<Appointment> reschedule({
    required String appointmentId,
    required DateTime newDate,
  }) async {
    final res = await _client.rpc('reschedule_appointment', params: {
      'p_id': appointmentId,
      'p_new_date': Fmt.dayKey(newDate),
    });
    return Appointment.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<void> submitRating({
    required String appointmentId,
    required int rating,
    String? comment,
  }) async {
    await _client.rpc('submit_rating', params: {
      'p_appointment_id': appointmentId,
      'p_rating': rating,
      'p_comment': comment,
    });
  }
}
