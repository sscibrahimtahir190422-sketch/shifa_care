import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/routes/app_routes.dart';
import '../../app/services/session_service.dart';
import '../../core/base/base_view_model.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/utils/app_snack.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../data/models/appointment.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/services/realtime_service.dart';

class MyAppointmentsViewModel extends BaseViewModel {
  MyAppointmentsViewModel(this._repo, this._realtime, this._session, this._notifications);

  final AppointmentRepository _repo;
  final RealtimeService _realtime;
  final SessionService _session;
  final LocalNotificationService _notifications;

  final appointments = <Appointment>[].obs;
  RealtimeChannel? _channel;
  bool _remindedThisSession = false;

  String get _userId => _session.user.value!.id;

  Appointment? get activeToday {
    final today = Fmt.today();
    return appointments.firstWhereOrNull(
          (a) => a.isActive && Fmt.isSameDay(a.date, today),
    );
  }

  List<Appointment> get upcoming {
    final today = Fmt.today();
    final list = appointments
        .where((a) => a.isActive && !a.date.isBefore(today))
        .toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.token.compareTo(b.token);
      });
    return list;
  }

  List<Appointment> get history {
    final upcomingIds = upcoming.map((a) => a.id).toSet();
    return appointments.where((a) => !upcomingIds.contains(a.id)).toList();
  }

  Appointment? get upcomingReminder {
    final today = Fmt.today();
    return upcoming.firstWhereOrNull((a) {
      final daysAway = a.date.difference(today).inDays;
      return daysAway >= 1 && daysAway <= 2;
    });
  }


  Appointment? get unratedCompleted =>
      history.firstWhereOrNull((a) => a.status == AppointmentStatus.completed);

  @override
  void onReady() {
    super.onReady();
    load();
    _channel = _realtime.listen(
      table: 'appointments',
      column: 'patient_id',
      value: _userId,
      onChange: () => load(silent: true),
    );
  }

  Future<void> load({bool silent = false}) async {
    if (isClosed) return;
    await run(
          () async {
        appointments.assignAll(await _repo.fetchMyAppointments(_userId));
      },
      showLoader: !silent,
      showError: !silent,
    );
    _maybeRemind();
  }


  void _maybeRemind() {
    if (_remindedThisSession) return;
    final reminder = upcomingReminder;
    if (reminder == null) return;
    _remindedThisSession = true;
    final daysAway = reminder.date.difference(Fmt.today()).inDays;
    _notifications.showNow(
      title: 'Upcoming appointment',
      body: 'Your appointment with ${reminder.doctor?.fullName ?? 'your doctor'} '
          'is in $daysAway day${daysAway == 1 ? '' : 's'} on ${Fmt.longDate(reminder.date)}.',
    );
  }

  void open(Appointment appointment) =>
      Get.toNamed(Routes.liveQueue, arguments: appointment);


  List<DateTime> get rescheduleDays {
    final t = Fmt.today();
    return List.generate(7, (i) => DateTime(t.year, t.month, t.day + i));
  }

  Future<void> reschedule(Appointment appointment, DateTime newDate) async {
    final done = await run(
          () => _repo.reschedule(appointmentId: appointment.id, newDate: newDate),
    );
    if (done) {
      AppSnack.success('Moved to ${Fmt.longDate(newDate)}.');
      await load(silent: true);
    }
  }

  Future<void> cancel(Appointment appointment) async {
    final confirmed = await ConfirmDialog.show(
      title: 'Cancel appointment?',
      message: 'Your token #${appointment.token} will be released.',
      confirmLabel: 'Yes, cancel',
      destructive: true,
    );
    if (!confirmed) return;

    final done = await run(() => _repo.cancel(appointment.id));
    if (done) {
      AppSnack.success('Your appointment has been cancelled.');
      await load(silent: true);
    }
  }

  Future<void> submitRating(Appointment appointment, int rating, String? comment) async {
    final done = await run(
      () => _repo.submitRating(
        appointmentId: appointment.id,
        rating: rating,
        comment: comment,
      ),
    );
    if (done) {
      AppSnack.success('Thank you for your feedback!');
      await load(silent: true);
    }
  }

  @override
  void onClose() {
    final channel = _channel;
    if (channel != null) _realtime.stop(channel);
    super.onClose();
  }
}