import 'package:get/get.dart';

import '../../data/repositories/appointment_repository.dart';
import 'booking_view_model.dart';

class BookingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BookingViewModel(Get.find<AppointmentRepository>()));
  }
}
