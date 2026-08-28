import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/features/student/tabs/student_home_tab.dart';
import 'package:presenza/features/student/tabs/student_attendance_tab.dart';
import 'package:presenza/features/student/screens/qr_scanner_screen.dart';
import 'package:presenza/features/student/tabs/student_activities_tab.dart';

import 'package:presenza/features/student/tabs/student_profile_tab.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Student Portal',
    'Subject Attendance',
    'QR Scanner',
    'Campus Activities',
    'Profile',
  ];

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final notifs = ref.watch(notificationsProvider);
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (notifs.isNotEmpty)
                        TextButton(
                          onPressed: () =>
                              ref.read(notificationsProvider.notifier).markAllAsRead(),
                          child: const Text('Mark all as read'),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: notifs.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.notifications_none_rounded,
                          title: 'No Notifications',
                          subtitle: 'You are all caught up!',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: notifs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final n = notifs[index];
                            return AppCard(
                              padding: const EdgeInsets.all(14),
                              onTap: () {
                                if (!n.isRead) {
                                  ref.read(notificationsProvider.notifier).markAsRead(n.id);
                                }
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    n.isRead ? Icons.notifications_none : Icons.notifications_active,
                                    color: n.isRead ? AppColors.slate400 : AppColors.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n.title,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          n.body,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      StudentHomeTab(
        onNavigateToAttendance: () => setState(() => _currentIndex = 1),
        onNavigateToActivities: () => setState(() => _currentIndex = 3),
      ),
      const StudentAttendanceTab(),
      const QrScannerScreen(),
      const StudentActivitiesTab(),
      const StudentProfileTab(),
    ];

    const navigationItems = [
      ShellNavigationItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Home',
      ),
      ShellNavigationItem(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: 'Attendance',
      ),
      ShellNavigationItem(
        icon: Icons.qr_code_scanner_outlined,
        activeIcon: Icons.qr_code_scanner_rounded,
        label: 'Scan QR',
        iconSize: 26,
      ),
      ShellNavigationItem(
        icon: Icons.campaign_outlined,
        activeIcon: Icons.campaign_rounded,
        label: 'Activities',
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _showNotifications(context),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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
