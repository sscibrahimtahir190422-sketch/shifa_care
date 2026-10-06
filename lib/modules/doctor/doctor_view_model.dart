import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/services/session_service.dart';
import '../../core/base/base_view_model.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../data/models/appointment.dart';
import '../../data/models/doctor.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/doctor_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/services/realtime_service.dart';

class DoctorViewModel extends BaseViewModel {
  DoctorViewModel(
    this._doctors,
    this._appointments,
    this._realtime,
    this._session,
    this._stats,
  );

  final DoctorRepository _doctors;
  final AppointmentRepository _appointments;
  final RealtimeService _realtime;
  final SessionService _session;
  final StatsRepository _stats;

  final todayStats = Rxn<DoctorStatsToday>();

  final doctor = Rxn<Doctor>();
  final queue = <Appointment>[].obs;
  final notLinked = false.obs;
  final isCalling = false.obs;
  final isTogglingLeave = false.obs;

  RealtimeChannel? _channel;

  DateTime get today => Fmt.today();

  Appointment? get current =>
      queue.firstWhereOrNull((a) => a.status == AppointmentStatus.inProgress);

  List<Appointment> get waiting =>
      queue.where((a) => a.status == AppointmentStatus.waiting).toList();

  int get completedCount =>
      queue.where((a) => a.status == AppointmentStatus.completed).length;

  bool get canAdvance => current != null || waiting.isNotEmpty;

  String get advanceLabel {
    if (waiting.isNotEmpty) {
      return current == null ? 'Call first patient' : 'Call next patient';
    }
    return current != null ? 'Finish consultation' : 'No patients waiting';
  }

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load({bool silent = false}) async {
    if (isClosed) return;
    await run(
      () async {
        doctor.value ??= await _doctors.fetchDoctorForUser(_session.user.value!.id);
        final d = doctor.value;
        if (d == null) {
          notLinked.value = true;
          return;
        }
        queue.assignAll(
          await _appointments.fetchDoctorQueue(doctorId: d.id, date: today),
        );
        _channel ??= _realtime.listen(
          table: 'appointments',
          column: 'doctor_id',
          value: d.id,
          onChange: () => load(silent: true),
        );
        todayStats.value = await _stats.fetchDoctorStatsToday();
      },
      showLoader: !silent,
      showError: !silent,
    );
  }

  Future<void> advance() async {
    final d = doctor.value;
    if (d == null || isCalling.value || !canAdvance) return;

    isCalling.value = true;
    final ok = await run(
      () => _appointments.callNext(doctorId: d.id, date: today),
      showLoader: false,
    );
    isCalling.value = false;

    if (ok) {
      HapticFeedback.mediumImpact();
      await load(silent: true);
    }
  }

  Future<void> toggleLeave() async {
    final d = doctor.value;
    if (d == null || isTogglingLeave.value) return;

    final next = !d.onLeave;
    isTogglingLeave.value = true;
    doctor.value = d.copyWith(onLeave: next); // optimistic

    final ok = await run(
      () => _doctors.setOnLeave(d.id, next),
      showLoader: false,
    );

    if (!ok) doctor.value = d; // revert on failure
    isTogglingLeave.value = false;
  }

  Future<void> logout() async {
    final confirmed = await ConfirmDialog.show(
      title: 'Sign out?',
      message: 'You can sign back in any time.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (confirmed) await _session.logout();
  }

  @override
  void onClose() {
    final channel = _channel;
    if (channel != null) _realtime.stop(channel);
    super.onClose();
  }
}
