import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../app/services/session_service.dart';

class SplashViewModel extends GetxController {
  SplashViewModel(this._session);

  final SessionService _session;

  @override
  void onReady() {
    super.onReady();
    _boot();
  }

  Future<void> _boot() async {
    try {

      await Future.wait([
        _session.restore(),
        Future<void>.delayed(const Duration(milliseconds: 2400)),
      ]);
    } catch (_) {
      await _session.clear();
    }

    Get.offAllNamed(
      _session.user.value == null ? Routes.login : _session.homeRoute,
    );
  }
}
