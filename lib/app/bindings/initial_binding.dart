import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/doctor_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/services/realtime_service.dart';
import '../services/session_service.dart';


class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final client = Supabase.instance.client;

    Get.put(RealtimeService(client), permanent: true);
    Get.put(AuthRepository(client), permanent: true);
    Get.put(DoctorRepository(client), permanent: true);
    Get.put(AppointmentRepository(client), permanent: true);
    Get.put(StatsRepository(client), permanent: true);
    Get.put(SessionService(Get.find<AuthRepository>()), permanent: true);
  }
}
