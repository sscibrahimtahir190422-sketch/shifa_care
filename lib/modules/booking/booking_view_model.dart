import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/base/base_view_model.dart';
import '../../core/utils/app_snack.dart';
import '../../core/utils/fmt.dart';
import '../../data/models/doctor.dart';
import '../../data/repositories/appointment_repository.dart';

class BookingViewModel extends BaseViewModel {
  BookingViewModel(this._repo);

  final AppointmentRepository _repo;

  late final Doctor doctor;

  final selectedDate = Fmt.today().obs;
  final queueSize = 0.obs;
  final isLoadingQueue = false.obs;
  final reasonCtrl = TextEditingController();


  List<DateTime> get days {
    final t = Fmt.today();
    return List.generate(7, (i) => DateTime(t.year, t.month, t.day + i));
  }

  bool get isToday => Fmt.isSameDay(selectedDate.value, Fmt.today());

  int get estimatedMinutes => queueSize.value * doctor.avgMinutes;

  @override
  void onInit() {
    super.onInit();
    doctor = Get.arguments as Doctor;
  }

  @override
  void onReady() {
    super.onReady();
    loadQueueSize();
  }

  Future<void> selectDate(DateTime date) async {
    selectedDate.value = date;
    await loadQueueSize();
  }

  Future<void> loadQueueSize() async {
    isLoadingQueue.value = true;
    final size = await guard(
      () => _repo.fetchActiveQueueSize(
        doctorId: doctor.id,
        date: selectedDate.value,
      ),
      showLoader: false,
      showError: false,
    );
    queueSize.value = size ?? 0;
    isLoadingQueue.value = false;
  }

  Future<void> confirm() async {
    final booked = await guard(
      () => _repo.book(
        doctorId: doctor.id,
        date: selectedDate.value,
        reason: reasonCtrl.text,
      ),
    );
    if (booked == null) return;

    AppSnack.success('Token #${booked.token} booked with ${doctor.fullName}');

    Get.offNamed(Routes.liveQueue, arguments: booked.withDoctor(doctor));
  }

  @override
  void onClose() {
    reasonCtrl.dispose();
    super.onClose();
  }
}
