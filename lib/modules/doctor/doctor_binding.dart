import 'package:get/get.dart';

import '../../app/services/session_service.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/doctor_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/services/realtime_service.dart';
import 'doctor_view_model.dart';

class DoctorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DoctorViewModel(
        Get.find<DoctorRepository>(),
        Get.find<AppointmentRepository>(),
        Get.find<RealtimeService>(),
        Get.find<SessionService>(),
        Get.find<StatsRepository>(),
      ),
    );
  }
}
