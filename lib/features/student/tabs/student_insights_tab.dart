import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class StudentInsightsTab extends ConsumerWidget {
  const StudentInsightsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectAttendanceProvider);
    final overall = ref.watch(overallAttendanceProvider);
    final leaderboard = ref.watch(leaderboardProvider);
    final student = ref.watch(studentProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final lowAttendanceSubjects = subjects.where((s) => s.percentage < 75.0).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentAttendanceRecordsProvider);
        ref.invalidate(leaderboardStreamProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Overview Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Academic Health Index',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (overall >= 75 ? AppColors.success : AppColors.error).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          overall >= 75 ? 'ELIGIBLE' : 'DEBARRED RISK',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: overall >= 75 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    overall >= 75
                        ? 'Your attendance across all academic subjects fulfills the minimum criteria required for end-semester examinations.'
                        : 'Warning: Your attendance in one or more subjects is below the institutional threshold. Immediate attendance improvement is required.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Overall %',
                          value: '${overall.toStringAsFixed(0)}%',
                          icon: Icons.pie_chart_outline_rounded,
                          iconColor: overall >= 75 ? AppColors.success : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Subjects Safe',
                          value: '${subjects.length - lowAttendanceSubjects.length}/${subjects.length}',
                          icon: Icons.verified_user_outlined,
                          iconColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Risk Assessment Section
            Text(
              'Attendance Risk Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),

            if (lowAttendanceSubjects.isEmpty)
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Subjects At Risk',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You have maintained 75%+ in all enrolled course modules.',
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
                itemCount: lowAttendanceSubjects.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final sa = lowAttendanceSubjects[index];
                  final needed = sa.classesNeededForThreshold(75.0);

                  return AppCard(
                    borderColor: AppColors.error.withAlpha(80),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sa.subjectName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Current: ${sa.percentage.toStringAsFixed(0)}% • Must attend next $needed classes consecutively',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // Class Leaderboard
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Batch Attendance Leaderboard',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  'Top Scholars',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (leaderboard.isEmpty)
              const EmptyStateWidget(
                icon: Icons.leaderboard_outlined,
                title: 'Leaderboard Inactive',
                subtitle: 'Rankings will appear as more classes are conducted.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leaderboard.take(5).length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = leaderboard[index];
                  final isMe = student?.studentId == entry.studentId || student?.user.name == entry.studentName;

                  return AppCard(
                    backgroundColor: isMe
                        ? (isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer)
                        : null,
                    borderColor: isMe ? AppColors.primary : null,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: index == 0
                                ? const Color(0xFFF59E0B)
                                : (index == 1
                                    ? const Color(0xFF94A3B8)
                                    : (index == 2 ? const Color(0xFFB45309) : (isDark ? AppColors.elevatedDark : AppColors.slate200))),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.studentName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              Text(
                                '${entry.streak} Day Streak',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${entry.attendancePercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
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
}
