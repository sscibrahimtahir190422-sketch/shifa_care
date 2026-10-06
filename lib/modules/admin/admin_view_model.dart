import 'package:get/get.dart';

import '../../app/services/session_service.dart';
import '../../core/base/base_view_model.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../data/repositories/stats_repository.dart';


class AdminViewModel extends BaseViewModel {
  AdminViewModel(this._stats, this._session);

  final StatsRepository _stats;
  final SessionService _session;

  final stats = Rxn<HospitalStatsToday>();

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load({bool silent = false}) async {
    if (isClosed) return;
    await run(
      () async => stats.value = await _stats.fetchHospitalStatsToday(),
      showLoader: !silent,
      showError: !silent,
    );
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
}
