import 'package:get/get.dart';

import '../../app/services/session_service.dart';
import '../../core/services/local_notification_service.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/doctor_repository.dart';
import '../../data/services/realtime_service.dart';
import 'home_view_model.dart';
import 'my_appointments_view_model.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
          () => HomeViewModel(Get.find<DoctorRepository>(), Get.find<SessionService>()),
    );

    Get.put(
      MyAppointmentsViewModel(
        Get.find<AppointmentRepository>(),
        Get.find<RealtimeService>(),
        Get.find<SessionService>(),
        Get.find<LocalNotificationService>(),
      ),
    );
  }
}
