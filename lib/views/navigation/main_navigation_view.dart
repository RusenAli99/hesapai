import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../chat/chat_view.dart';
import '../dashboard/dashboard_view.dart';
import '../statistics/statistics_view.dart';
import '../profile/profile_view.dart';
import '../../core/theme/app_colors.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ChatView(),
    DashboardView(),
    StatisticsView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          indicatorColor: AppColors.primary.withOpacity(0.15),
          height: 72,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              selectedIcon: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
              label: 'Sohbet',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              selectedIcon: const Icon(Icons.grid_view_rounded, color: AppColors.primary),
              label: 'Panel',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              selectedIcon: const Icon(Icons.pie_chart_rounded, color: AppColors.primary),
              label: 'İstatistik',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              selectedIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
