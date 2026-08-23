import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/features/admin/tabs/admin_overview_tab.dart';
import 'package:presenza/features/admin/tabs/admin_attendance_tab.dart';
import 'package:presenza/features/admin/tabs/admin_circulars_tab.dart';
import 'package:presenza/features/admin/tabs/admin_users_tab.dart';
import 'package:presenza/features/admin/tabs/admin_profile_tab.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Admin Overview',
    'Attendance Monitor',
    'Official Circulars',
    'User Management',
    'System Admin',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      AdminOverviewTab(
        onNavigateToAttendance: () => setState(() => _currentIndex = 1),
        onNavigateToCirculars: () => setState(() => _currentIndex = 2),
        onNavigateToUsers: () => setState(() => _currentIndex = 3),
      ),
      const AdminAttendanceTab(),
      const AdminCircularsTab(),
      const AdminUsersTab(),
      const AdminProfileTab(),
    ];

    const navigationItems = [
      ShellNavigationItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Overview',
      ),
      ShellNavigationItem(
        icon: Icons.analytics_outlined,
        activeIcon: Icons.analytics_rounded,
        label: 'Attendance',
      ),
      ShellNavigationItem(
        icon: Icons.campaign_outlined,
        activeIcon: Icons.campaign_rounded,
        label: 'Circulars',
      ),
      ShellNavigationItem(
        icon: Icons.manage_accounts_outlined,
        activeIcon: Icons.manage_accounts_rounded,
        label: 'Users',
      ),
      ShellNavigationItem(
        icon: Icons.admin_panel_settings_outlined,
        activeIcon: Icons.admin_panel_settings_rounded,
        label: 'Profile',
      ),
    ];

    return ResponsiveShell(
      currentIndex: _currentIndex,
      onIndexChanged: (index) => setState(() => _currentIndex = index),
      items: navigationItems,
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: 'Switch Theme',
            onPressed: () {
              ref.read(themeModeProvider.notifier).setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
    );
  }
}
