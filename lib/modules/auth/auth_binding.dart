import 'package:get/get.dart';

import '../../app/services/session_service.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_view_model.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AuthViewModel(Get.find<AuthRepository>(), Get.find<SessionService>()),
    );
  }
}
