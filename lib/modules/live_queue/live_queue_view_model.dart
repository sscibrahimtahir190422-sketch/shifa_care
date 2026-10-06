import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/base/base_view_model.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/utils/app_snack.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../data/models/appointment.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/services/realtime_service.dart';


class LiveQueueViewModel extends BaseViewModel {
  LiveQueueViewModel(this._repo, this._realtime, this._notifications);

  final AppointmentRepository _repo;
  final RealtimeService _realtime;
  final LocalNotificationService _notifications;

  late final Rx<Appointment> appointment;
  final nowServing = 0.obs;
  final ahead = 0.obs;

  final _channels = <RealtimeChannel>[];
  late AppointmentStatus _lastStatus;

  Appointment get current => appointment.value;
  AppointmentStatus get status => current.status;
  bool get isToday => Fmt.isSameDay(current.date, Fmt.today());

  int get etaMinutes => ahead.value * (current.doctor?.avgMinutes ?? 10);

  double get progress {
    if (status == AppointmentStatus.completed ||
        status == AppointmentStatus.inProgress) {
      return 1;
    }
    final before = current.token - 1;
    if (before <= 0) return 0.08;
    final moved = ((before - ahead.value) / before).clamp(0.0, 1.0).toDouble();
    return max(0.08, moved);
  }

  String get headline {
    switch (status) {
      case AppointmentStatus.waiting:
        if (!isToday) return 'Booked for ${Fmt.longDate(current.date)}';
        if (ahead.value == 0) return "You're next";
        final n = ahead.value;
        return '$n ${n == 1 ? 'patient' : 'patients'} ahead of you';
      case AppointmentStatus.inProgress:
        return "It's your turn";
      case AppointmentStatus.completed:
        return 'Visit completed';
      case AppointmentStatus.cancelled:
        return 'Appointment cancelled';
    }
  }

  String get subline {
    switch (status) {
      case AppointmentStatus.waiting:
        if (!isToday) return 'The live queue starts on the day of your visit.';
        if (ahead.value == 0) return 'Please stay close to the consultation room.';
        return 'Estimated wait about ${Fmt.wait(etaMinutes)}.';
      case AppointmentStatus.inProgress:
        return 'Please proceed to ${current.doctor?.room ?? 'the consultation room'}.';
      case AppointmentStatus.completed:
        return 'Thank you for visiting. Wishing you good health.';
      case AppointmentStatus.cancelled:
        return 'You can book a new slot anytime.';
    }
  }

  @override
  void onInit() {
    super.onInit();
    appointment = Rx<Appointment>(Get.arguments as Appointment);
    _lastStatus = current.status;

    _channels.add(_realtime.listen(
      table: 'queue_status',
      column: 'doctor_id',
      value: current.doctorId,
      onChange: () => loadState(silent: true),
    ));
    _channels.add(_realtime.listen(
      table: 'appointments',
      column: 'id',
      value: current.id,
      onChange: () => loadState(silent: true),
    ));
  }

  @override
  void onReady() {
    super.onReady();
    loadState();
  }

  Future<void> loadState({bool silent = false}) async {
    if (isClosed) return;
    await run(
      () async {
        final (fresh, queue, patientsAhead) = await (
          _repo.fetchAppointment(current.id),
          _repo.fetchQueueStatus(doctorId: current.doctorId, date: current.date),
          _repo.fetchPatientsAhead(current.id),
        ).wait;

        nowServing.value = queue.nowServing;
        ahead.value = patientsAhead;
        appointment.value = fresh.withDoctor(current.doctor);
        _announceIfMyTurn();
      },
      showLoader: !silent,
      showError: !silent,
    );
  }

  void _announceIfMyTurn() {
    final now = current.status;
    if (now == AppointmentStatus.inProgress &&
        _lastStatus != AppointmentStatus.inProgress) {
      HapticFeedback.heavyImpact();
      final room = current.doctor?.room ?? 'the consultation room';
      AppSnack.success("It's your turn. Please proceed to $room.");
      _notifications.showNow(
        title: "It's your turn",
        body: 'Token #${current.token} — please proceed to $room.',
      );
    }
    _lastStatus = now;
  }

  Future<void> cancel() async {
    final confirmed = await ConfirmDialog.show(
      title: 'Cancel appointment?',
      message: 'Your token #${current.token} will be released.',
      confirmLabel: 'Yes, cancel',
      destructive: true,
    );
    if (!confirmed) return;

    final done = await run(() => _repo.cancel(current.id));
    if (done) {
      AppSnack.success('Your appointment has been cancelled.');
      await loadState(silent: true);
    }
  }

  @override
  void onClose() {
    for (final channel in _channels) {
      _realtime.stop(channel);
    }
    super.onClose();
  }
}
