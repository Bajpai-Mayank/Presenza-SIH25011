import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/features/teacher/widgets/attendance_statistics_view.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TeacherDashboardTab extends ConsumerWidget {
  final VoidCallback onNavigateToAttendance;
  final VoidCallback onNavigateToActivities;
  final VoidCallback onNavigateToStudents;

  const TeacherDashboardTab({
    super.key,
    required this.onNavigateToAttendance,
    required this.onNavigateToActivities,
    required this.onNavigateToStudents,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacher = ref.watch(teacherProfileProvider);
    final subjects = ref.watch(teacherSubjectsProvider);
    final activeSession = ref.watch(activeAttendanceSessionProvider);
    final pendingActivitiesAsync = ref.watch(pendingActivitiesStreamProvider);
    final pendingActivities = pendingActivitiesAsync.valueOrNull ?? [];
    final students = ref.watch(allStudentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (teacher == null) {
      return const DashboardShimmer();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting & Faculty Card ─────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: isDark
                    ? AppColors.primaryContainerDark
                    : AppColors.primaryContainer,
                child: Text(
                  teacher.user.initials,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Faculty Portal,',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textSecondaryLight,
                          ),
                    ),
                    Text(
                      teacher.user.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${teacher.employeeId} • ${teacher.user.department ?? "Department of Computer Science"}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.primaryDark
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Key Metrics Grid ────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Assigned Subjects',
                  value: subjects.length.toString(),
                  icon: Icons.auto_stories_outlined,
                  iconColor: AppColors.primary,
                  onTap: onNavigateToAttendance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Enrolled Students',
                  value: students.length.toString(),
                  icon: Icons.groups_outlined,
                  iconColor: AppColors.secondary,
                  onTap: onNavigateToStudents,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Active QR Session',
                  value: activeSession != null && activeSession.isActive ? '1 LIVE' : 'None',
                  icon: Icons.qr_code_2_rounded,
                  iconColor: activeSession != null && activeSession.isActive ? AppColors.success : AppColors.slate400,
                  onTap: onNavigateToAttendance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Pending Approvals',
                  value: pendingActivities.length.toString(),
                  icon: Icons.pending_actions_rounded,
                  iconColor: pendingActivities.isNotEmpty ? AppColors.warning : AppColors.slate400,
                  onTap: onNavigateToActivities,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Quick Actions ───────────────────────────────────────────
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: AppButton.primary(
                  label: 'Start Attendance',
                  icon: Icons.qr_code_rounded,
                  onPressed: onNavigateToAttendance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton.secondary(
                  label: 'Create Notice',
                  icon: Icons.campaign_rounded,
                  onPressed: onNavigateToActivities,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Active Live Session Alert (If Running) ───────────────────
          if (activeSession != null && activeSession.isActive) ...[
            AppCard(
              backgroundColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
              borderColor: AppColors.success,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attendance Session In Progress',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${activeSession.subjectName ?? "Subject"} • Room ${activeSession.room ?? "A"}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onNavigateToAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('View QR'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Pending Student Submissions for Approval ────────────────
          if (pendingActivities.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Student Activities',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                StatusBadge(
                  label: '${pendingActivities.length} Pending',
                  color: AppColors.warning,
                  small: true,
                ),
              ],
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingActivities.take(3).length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final post = pendingActivities[index];
                return AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CategoryBadge(category: post.category, small: true),
                          const Spacer(),
                          Text(
                            'Submitted by ${post.authorName}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              ref.read(firestoreServiceProvider).rejectActivityPost(post.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Activity submission rejected.')),
                              );
                            },
                            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                            label: const Text('Reject', style: TextStyle(color: AppColors.error)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.read(firestoreServiceProvider).approveActivityPost(post.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Activity post approved!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // ── Attendance Statistics ────────────────────────────────────
          const AttendanceStatisticsView(),
          const SizedBox(height: 24),

          // ── Assigned Subjects ───────────────────────────────────────
          Text(
            'My Academic Subjects',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),

          if (subjects.isEmpty)
            const EmptyStateWidget(
              icon: Icons.menu_book_rounded,
              title: 'No Subjects Assigned',
              subtitle: 'Add a subject from the attendance tab to begin generating session QRs.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final sub = subjects[index];
                return AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.elevatedDark : AppColors.slate100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.book_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.name,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              '${sub.code} • Semester ${sub.semester} • ${sub.credits} Credits',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_rounded, color: AppColors.primary),
                        tooltip: 'Start Session for this subject',
                        onPressed: onNavigateToAttendance,
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
        ].animate(interval: 50.ms).fade(duration: 300.ms).slideY(begin: 0.05, duration: 300.ms),
      ),
    );
  }
}
