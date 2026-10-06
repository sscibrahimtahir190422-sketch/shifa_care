import 'package:get/get.dart';

import '../../app/services/session_service.dart';
import '../../data/repositories/stats_repository.dart';
import 'admin_view_model.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AdminViewModel(
        Get.find<StatsRepository>(),
        Get.find<SessionService>(),
      ),
    );
  }
}
