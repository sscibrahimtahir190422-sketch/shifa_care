import 'package:get/get.dart';

import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';
import '../routes/app_routes.dart';


class SessionService extends GetxService {
  SessionService(this._auth);

  final AuthRepository _auth;

  final user = Rxn<AppUser>();

  bool get isDoctor => user.value?.role == UserRole.doctor;
  bool get isAdmin => user.value?.role == UserRole.admin;

  String get homeRoute {
    if (isAdmin) return Routes.adminDashboard;
    if (isDoctor) return Routes.doctorDashboard;
    return Routes.home;
  }

  Future<void> restore() async {
    if (_auth.hasSession) await loadProfile();
  }

  Future<void> loadProfile() async {
    user.value = await _auth.fetchProfile();
  }


  Future<void> clear() async {
    try {
      await _auth.signOut();
    } catch (_) {

    }
    user.value = null;
  }

  Future<void> logout() async {
    await clear();
    Get.offAllNamed(Routes.login);
  }
}
