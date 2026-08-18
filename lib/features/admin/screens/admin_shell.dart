import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/config/theme/app_colors.dart';
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
    'System Analytics',
    'Attendance Policies',
    'User Directory',
    'Security Audit Logs',
    'Admin Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = [
      const _AdminDashboardTab(),
      const _AdminPoliciesTab(),
      const _AdminUsersTab(),
      const _AdminAuditLogsTab(),
      const _AdminProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () {
              ref.read(themeModeProvider.notifier).setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.white.withAlpha(20) : AppColors.black.withAlpha(10),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.policy_outlined),
              activeIcon: Icon(Icons.policy),
              label: 'Policies',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.security_outlined),
              activeIcon: Icon(Icons.security),
              label: 'Audit',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_box_outlined),
              activeIcon: Icon(Icons.account_box),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 0: DASHBOARD
// ══════════════════════════════════════════════════════════════════════
class _AdminDashboardTab extends ConsumerWidget {
  const _AdminDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(allStudentsProvider);
    final teachers = ref.watch(allTeachersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Cards Grid
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total Students',
                  value: students.length.toString(),
                  icon: Icons.people,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  label: 'Active Teachers',
                  value: teachers.length.toString(),
                  icon: Icons.school,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Avg Attendance',
                  value: '88.4%',
                  icon: Icons.trending_up,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  label: 'Below Threshold',
                  value: '1',
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Analytics Detail Card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Active Rates',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Today\'s overall check-in rate is 92.4% with QR validation enabled. There are currently no system downtime issues reported.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 1: POLICIES
// ══════════════════════════════════════════════════════════════════════
class _AdminPoliciesTab extends ConsumerWidget {
  const _AdminPoliciesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policies = ref.watch(attendancePoliciesProvider);

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: policies.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final policy = policies[index];
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Course Policy: ${policy.courseId.replaceAll('course-', '').toUpperCase()}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Icon(Icons.settings, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              _PolicyRow(label: 'Min Attendance Required', value: '${policy.minimumAttendancePercent}%'),
              _PolicyRow(label: 'QR Expiration Window', value: '${policy.qrExpiryMinutes} mins'),
              _PolicyRow(label: 'Geo-fence Validation', value: policy.locationRequired ? 'Enabled (Radius: ${policy.allowedRadiusMeters}m)' : 'Disabled'),
              _PolicyRow(label: 'Face Verification', value: policy.faceVerificationMode.displayName),
            ],
          ),
        );
      },
    );
  }
}

class _PolicyRow extends StatelessWidget {
  final String label;
  final String value;

  const _PolicyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 2: USER DIRECTORY
// ══════════════════════════════════════════════════════════════════════
class _AdminUsersTab extends ConsumerWidget {
  const _AdminUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(allStudentsProvider);
    final teachers = ref.watch(allTeachersProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Students'),
              Tab(text: 'Teachers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Students List
                ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: students.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final std = students[index];
                    return GlassCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.white.withAlpha(20),
                            child: Text(std.user.initials, style: const TextStyle(color: AppColors.white)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(std.user.name, style: Theme.of(context).textTheme.titleMedium),
                                Text(std.studentId, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.gray400),
                        ],
                      ),
                    );
                  },
                ),

                // Teachers List
                ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: teachers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final t = teachers[index];
                    return GlassCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.white.withAlpha(20),
                            child: Text(t.user.initials, style: const TextStyle(color: AppColors.white)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.user.name, style: Theme.of(context).textTheme.titleMedium),
                                Text(t.employeeId, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.gray400),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 3: AUDIT LOGS
// ══════════════════════════════════════════════════════════════════════
class _AdminAuditLogsTab extends ConsumerWidget {
  const _AdminAuditLogsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(auditLogsProvider);

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: logs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = logs[index];
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(label: log.action, color: AppColors.info, small: true),
                  Text(
                    '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'By ${log.userName} (${log.userId})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                log.details ?? '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 4: PROFILE
// ══════════════════════════════════════════════════════════════════════
class _AdminProfileTab extends ConsumerWidget {
  const _AdminProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    if (user == null) return const LoadingState();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GlassCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.white.withAlpha(20),
                  child: Text(
                    user.initials,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                _ProfileRow(label: 'Role', value: 'System Administrator'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            label: 'Logout',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
            filled: false,
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
