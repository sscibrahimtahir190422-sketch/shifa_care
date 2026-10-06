import 'package:get/get.dart';

import '../../app/services/session_service.dart';
import 'splash_view_model.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {

    Get.put(SplashViewModel(Get.find<SessionService>()));
  }
}
