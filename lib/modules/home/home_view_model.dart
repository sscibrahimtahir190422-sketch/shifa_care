import 'package:get/get.dart';

import '../../app/services/session_service.dart';
import '../../core/base/base_view_model.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../data/models/doctor.dart';
import '../../data/repositories/doctor_repository.dart';

class HomeViewModel extends BaseViewModel {
  HomeViewModel(this._doctorRepo, this._session);

  final DoctorRepository _doctorRepo;
  final SessionService _session;

  final doctors = <Doctor>[].obs;
  final searchQuery = ''.obs;
  final selectedDepartment = 'All'.obs;
  final tabIndex = 0.obs;

  String get firstName {
    final name = (_session.user.value?.fullName ?? '').trim();
    return name.isEmpty ? 'there' : name.split(' ').first;
  }

  List<String> get departments => [
        'All',
        ...{for (final d in doctors) d.department},
      ];

  List<Doctor> get filteredDoctors {
    final query = searchQuery.value.trim().toLowerCase();
    final dept = selectedDepartment.value;

    return doctors.where((d) {
      final inDepartment = dept == 'All' || d.department == dept;
      final matches = query.isEmpty ||
          d.fullName.toLowerCase().contains(query) ||
          d.specialty.toLowerCase().contains(query);
      return inDepartment && matches;
    }).toList();
  }

  @override
  void onReady() {
    super.onReady();
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    await run(() async {
      doctors.assignAll(await _doctorRepo.fetchDoctors());
    });
  }

  void changeTab(int index) => tabIndex.value = index;

  void selectDepartment(String department) =>
      selectedDepartment.value = department;

  void onSearch(String value) => searchQuery.value = value;

  Future<void> logout() async {
    final confirmed = await ConfirmDialog.show(
      title: 'Sign out?',
      message: 'You will need to sign in again to see your tokens.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (confirmed) await _session.logout();
  }
}
