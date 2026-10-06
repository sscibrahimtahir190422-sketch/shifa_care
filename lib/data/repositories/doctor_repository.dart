import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/doctor.dart';

class DoctorRepository {
  DoctorRepository(this._client);

  final SupabaseClient _client;

  Future<List<Doctor>> fetchDoctors() async {
    final rows = await _client.from('doctors').select().order('full_name');
    return rows.map(Doctor.fromJson).toList();
  }


  Future<Doctor?> fetchDoctorForUser(String userId) async {
    final row = await _client
        .from('doctors')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : Doctor.fromJson(row);
  }

  Future<void> setOnLeave(String doctorId, bool onLeave) async {
    await _client.rpc('set_doctor_leave', params: {
      'p_doctor_id': doctorId,
      'p_on_leave': onLeave,
    });
  }
}
