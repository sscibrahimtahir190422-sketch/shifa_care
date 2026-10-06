import 'package:get/get.dart';

import '../../modules/admin/admin_binding.dart';
import '../../modules/admin/admin_view.dart';
import '../../modules/auth/auth_binding.dart';
import '../../modules/auth/auth_view.dart';
import '../../modules/booking/booking_binding.dart';
import '../../modules/booking/booking_view.dart';
import '../../modules/doctor/doctor_binding.dart';
import '../../modules/doctor/doctor_view.dart';
import '../../modules/home/home_binding.dart';
import '../../modules/home/home_view.dart';
import '../../modules/live_queue/live_queue_binding.dart';
import '../../modules/live_queue/live_queue_view.dart';
import '../../modules/splash/splash_binding.dart';
import '../../modules/splash/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.login,
      page: () => const AuthView(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.booking,
      page: () => const BookingView(),
      binding: BookingBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: Routes.liveQueue,
      page: () => const LiveQueueView(),
      binding: LiveQueueBinding(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: Routes.doctorDashboard,
      page: () => const DoctorView(),
      binding: DoctorBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.adminDashboard,
      page: () => const AdminView(),
      binding: AdminBinding(),
      transition: Transition.fadeIn,
    ),
  ];
}
