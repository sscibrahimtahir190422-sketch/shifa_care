import 'package:get/get.dart';

import '../../core/services/local_notification_service.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/services/realtime_service.dart';
import 'live_queue_view_model.dart';

class LiveQueueBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => LiveQueueViewModel(
        Get.find<AppointmentRepository>(),
        Get.find<RealtimeService>(),
        Get.find<LocalNotificationService>(),
      ),
    );
  }
}
