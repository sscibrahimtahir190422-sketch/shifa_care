import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/gradient_header.dart';
import '../../core/widgets/skeleton_box.dart';
import 'home_view_model.dart';
import 'my_appointments_view_model.dart';
import 'widgets/active_token_banner.dart';
import 'widgets/appointment_reminder_card.dart';
import 'widgets/doctor_card.dart';
import 'widgets/my_appointments_tab.dart';

class HomeView extends GetView<HomeViewModel> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
            () => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey(controller.tabIndex.value),
            child: controller.tabIndex.value == 0
                ? const _DoctorsTab()
                : const MyAppointmentsTab(),
          ),
        ),
      ),
      bottomNavigationBar: Obx(
            () => NavigationBar(
          selectedIndex: controller.tabIndex.value,
          onDestinationSelected: controller.changeTab,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryLight,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.confirmation_number_outlined),
              selectedIcon: Icon(
                Icons.confirmation_number_rounded,
                color: AppColors.primary,
              ),
              label: 'My visits',
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorsTab extends GetView<HomeViewModel> {
  const _DoctorsTab();

  @override
  Widget build(BuildContext context) {
    final visits = Get.find<MyAppointmentsViewModel>();

    return RefreshIndicator(
      onRefresh: controller.loadDoctors,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _HomeHeader(controller: controller)),
          SliverToBoxAdapter(
            child: Obx(() {
              final active = visits.activeToday;
              return AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: active == null
                      ? const SizedBox(key: ValueKey('no-token'), width: double.infinity)
                      : ActiveTokenBanner(
                    key: ValueKey(active.id),
                    appointment: active,
                  ),
                ),
              );
            }),
          ),
          SliverToBoxAdapter(
            child: Obx(() {
              final reminder = visits.upcomingReminder;
              return AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: reminder == null
                      ? const SizedBox(key: ValueKey('no-reminder'), width: double.infinity)
                      : AppointmentReminderCard(
                    key: ValueKey('reminder-${reminder.id}'),
                    appointment: reminder,
                  ),
                ),
              );
            }),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Find a doctor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Obx(() {
              final departments = controller.departments;
              return SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: departments.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final dept = departments[i];
                    final selected = controller.selectedDepartment.value == dept;
                    return GestureDetector(
                      onTap: () => controller.selectDepartment(dept),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Text(
                          dept,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Obx(() {
                if (controller.isLoading.value && controller.doctors.isEmpty) {
                  return const Column(
                    children: [SkeletonBox(), SkeletonBox(), SkeletonBox()],
                  );
                }
                final doctors = controller.filteredDoctors;
                if (doctors.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No doctors found',
                    message: 'Try another name, specialty or department.',
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < doctors.length; i++)
                      DoctorCard(key: ValueKey(doctors[i].id), doctor: doctors[i], index: i),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.controller});

  final HomeViewModel controller;

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assalam-o-Alaikum,',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      controller.firstName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: controller.logout,
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: controller.onSearch,
            decoration: InputDecoration(
              hintText: 'Search doctor or specialty',
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.08, curve: Curves.easeOutCubic),
    );
  }
}