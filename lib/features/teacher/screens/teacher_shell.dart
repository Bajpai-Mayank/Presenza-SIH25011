import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/features/teacher/tabs/teacher_dashboard_tab.dart';
import 'package:presenza/features/teacher/tabs/teacher_attendance_tab.dart';
import 'package:presenza/features/teacher/tabs/teacher_activities_tab.dart';
import 'package:presenza/features/teacher/tabs/teacher_students_tab.dart';
import 'package:presenza/features/teacher/tabs/teacher_profile_tab.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class TeacherShell extends ConsumerStatefulWidget {
  const TeacherShell({super.key});

  @override
  ConsumerState<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends ConsumerState<TeacherShell> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Faculty Dashboard',
    'Class Attendance',
    'Notices & Moderation',
    'Student Directory',
    'Faculty Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      TeacherDashboardTab(
        onNavigateToAttendance: () => setState(() => _currentIndex = 1),
        onNavigateToActivities: () => setState(() => _currentIndex = 2),
        onNavigateToStudents: () => setState(() => _currentIndex = 3),
      ),
      const TeacherAttendanceTab(),
      const TeacherActivitiesTab(),
      const TeacherStudentsTab(),
      const TeacherProfileTab(),
    ];

    const navigationItems = [
      ShellNavigationItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Home',
      ),
      ShellNavigationItem(
        icon: Icons.qr_code_2_outlined,
        activeIcon: Icons.qr_code_2_rounded,
        label: 'Attendance',
      ),
      ShellNavigationItem(
        icon: Icons.campaign_outlined,
        activeIcon: Icons.campaign_rounded,
        label: 'Activities',
      ),
      ShellNavigationItem(
        icon: Icons.groups_outlined,
        activeIcon: Icons.groups_rounded,
        label: 'Students',
      ),
      ShellNavigationItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
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
