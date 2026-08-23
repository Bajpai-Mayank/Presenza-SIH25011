import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class AdminOverviewTab extends ConsumerWidget {
  final VoidCallback onNavigateToAttendance;
  final VoidCallback onNavigateToCirculars;
  final VoidCallback onNavigateToUsers;

  const AdminOverviewTab({
    super.key,
    required this.onNavigateToAttendance,
    required this.onNavigateToCirculars,
    required this.onNavigateToUsers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final students = ref.watch(allStudentsProvider);
    final courses = ref.watch(coursesProvider).valueOrNull ?? [];
    final circulars = ref.watch(circularsProvider);
    final activeSessions = ref.watch(allActiveSessionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Admin Greeting ───────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer,
                child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Institution Admin Portal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                          ),
                    ),
                    Text(
                      user?.name ?? 'Campus Administrator',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Metrics Row 1 ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Enrolled Students',
                  value: students.length.toString(),
                  icon: Icons.school_outlined,
                  iconColor: AppColors.primary,
                  onTap: onNavigateToUsers,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Academic Courses',
                  value: courses.length.toString(),
                  icon: Icons.account_balance_outlined,
                  iconColor: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Metrics Row 2 ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Active Class Sessions',
                  value: activeSessions.length.toString(),
                  icon: Icons.sensors_rounded,
                  iconColor: activeSessions.isNotEmpty ? AppColors.success : AppColors.slate400,
                  onTap: onNavigateToAttendance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Official Notices',
                  value: circulars.length.toString(),
                  icon: Icons.campaign_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  onTap: onNavigateToCirculars,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Campus Health Overview ──────────────────────────────────
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Campus Attendance Overview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const StatusBadge(
                      label: 'Academic Year 2024-25',
                      color: AppColors.primary,
                      small: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Automated QR attendance tracking with geolocation and fraud protection is active across all lecture halls.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onNavigateToAttendance,
                        icon: const Icon(Icons.analytics_outlined, size: 16),
                        label: const Text('Live Monitor'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onNavigateToCirculars,
                        icon: const Icon(Icons.add_alert_rounded, size: 16),
                        label: const Text('Broadcast Notice'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Active Sessions In Progress ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Classroom Sessions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              StatusBadge(
                label: '${activeSessions.length} Active',
                color: activeSessions.isNotEmpty ? AppColors.success : AppColors.slate400,
                small: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (activeSessions.isEmpty)
            const EmptyStateWidget(
              icon: Icons.sensors_off_rounded,
              title: 'No Live Sessions',
              subtitle: 'No classroom attendance sessions are currently running.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeSessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final session = activeSessions[index];
                return AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.sensors_rounded, color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.subjectName ?? 'Subject',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              '${session.teacherName ?? "Faculty"} • Room ${session.room ?? "A"}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: 'Active',
                        color: AppColors.success,
                        small: true,
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
