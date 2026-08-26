import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/attendance_status.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class StudentHomeTab extends ConsumerWidget {
  final VoidCallback onNavigateToAttendance;
  final VoidCallback onNavigateToActivities;

  const StudentHomeTab({
    super.key,
    required this.onNavigateToAttendance,
    required this.onNavigateToActivities,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProfileProvider);
    final overallAttendance = ref.watch(overallAttendanceProvider);
    final subjects = ref.watch(subjectAttendanceProvider);
    final enrolledCountAsync = ref.watch(enrolledStudentsCountProvider);
    final enrolledCount = enrolledCountAsync.valueOrNull ?? 0;
    final scheduleAsync = ref.watch(todayScheduleProvider);
    final schedule = scheduleAsync.valueOrNull ?? [];
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    final activities = activitiesAsync.valueOrNull ?? [];
    final streak = ref.watch(attendanceStreakProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (student == null) {
      return const DashboardShimmer();
    }

    final totalPresent = subjects.fold(0, (sum, sa) => sum + sa.present);
    final totalAbsent = subjects.fold(0, (sum, sa) => sum + sa.absent);
    final totalLate = subjects.fold(0, (sum, sa) => sum + sa.late);
    final totalClasses = subjects.fold(0, (sum, sa) => sum + sa.totalClasses);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(studentProfileProvider.notifier).refresh();
        ref.invalidate(studentAttendanceRecordsProvider);
        ref.invalidate(activitiesStreamProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting Header ──────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isDark
                      ? AppColors.primaryContainerDark
                      : AppColors.primaryContainer,
                  child: Text(
                    student.user.initials,
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
                        'Welcome back,',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textSecondaryLight,
                            ),
                      ),
                      Text(
                        student.user.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${student.studentId} • Semester ${student.semester}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? AppColors.secondaryDark
                                  : AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (enrolledCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '$enrolledCount students in your batch',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Streak Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withAlpha(isDark ? 30 : 20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEA580C).withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          size: 16, color: Color(0xFFEA580C)),
                      const SizedBox(width: 4),
                      Text(
                        '$streak Day${streak == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Color(0xFFEA580C),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Overall Attendance Summary Card ─────────────────────────
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AttendanceRing(
                        percentage: overallAttendance,
                        size: 110,
                        strokeWidth: 9,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              overallAttendance >= 75.0 ? 'Attendance On Track' : 'Attendance At Risk',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: overallAttendance >= 75.0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              overallAttendance >= 75.0
                                  ? 'You meet the minimum 75% requirement across your courses.'
                                  : 'Overall attendance is below the 75% mandatory threshold.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _AttendanceMetric(
                                  label: 'Present',
                                  count: totalPresent,
                                  color: AppColors.success,
                                ),
                                _AttendanceMetric(
                                  label: 'Absent',
                                  count: totalAbsent,
                                  color: AppColors.error,
                                ),
                                _AttendanceMetric(
                                  label: 'Late',
                                  count: totalLate,
                                  color: AppColors.warning,
                                ),
                                _AttendanceMetric(
                                  label: 'Total',
                                  count: totalClasses,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Quick Actions Grid ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan QR',
                    color: AppColors.primary,
                    onTap: () => context.push('/qr-scanner'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.calendar_month_rounded,
                    label: 'Attendance',
                    color: AppColors.secondary,
                    onTap: onNavigateToAttendance,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.campaign_rounded,
                    label: 'Activities',
                    color: const Color(0xFF7C3AED),
                    onTap: onNavigateToActivities,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Today's Classes & Status ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Schedule",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  DateFormat('EEE, d MMM').format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (schedule.isEmpty)
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.event_available_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Classes Scheduled Today',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enjoy your day or participate in campus activities.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: schedule.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = schedule[index];
                  final timeStr =
                      '${DateFormat('hh:mm a').format(entry.startTime)} - ${DateFormat('hh:mm a').format(entry.endTime)}';

                  return AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.elevatedDark : AppColors.slate100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 20,
                            color: isDark ? AppColors.primaryDark : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.subjectName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${entry.teacherName} • Room ${entry.room}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 13,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeStr,
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (entry.attendanceStatus != null)
                          _buildStatusBadge(entry.attendanceStatus!)
                        else
                          const StatusBadge(
                            label: 'Upcoming',
                            color: AppColors.primary,
                            icon: Icons.hourglass_top_rounded,
                            small: true,
                          ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // ── Recent Campus Activities & Circulars ────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Campus Announcements',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                TextButton(
                  onPressed: onNavigateToActivities,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (activities.isEmpty)
              const CardShimmer(height: 100)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.take(2).length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final post = activities[index];
                  return AppCard(
                    onTap: onNavigateToActivities,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CategoryBadge(category: post.category, small: true),
                            const Spacer(),
                            if (post.isOfficial)
                              const StatusBadge(
                                label: 'Official',
                                color: AppColors.primary,
                                icon: Icons.verified_outlined,
                                small: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
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
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded,
                                size: 14,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                            const SizedBox(width: 4),
                            Text(
                              post.authorName,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const Spacer(),
                            if (post.totalReactions > 0) ...[
                              const Icon(Icons.thumb_up_alt_outlined, size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                post.totalReactions.toString(),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return StatusBadge.present(small: true);
      case AttendanceStatus.absent:
        return StatusBadge.absent(small: true);
      case AttendanceStatus.late:
        return StatusBadge.late(small: true);
      case AttendanceStatus.excused:
        return StatusBadge.excused(small: true);
    }
  }
}

class _AttendanceMetric extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _AttendanceMetric({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 25 : 15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
