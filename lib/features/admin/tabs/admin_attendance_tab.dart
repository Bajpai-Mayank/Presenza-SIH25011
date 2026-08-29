import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/core/utils/csv_export_service.dart';

class AdminAttendanceTab extends ConsumerWidget {
  const AdminAttendanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessions = ref.watch(allActiveSessionsProvider);
    final students = ref.watch(allStudentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allActiveSessionsStreamProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Classroom Attendance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time overview of active attendance sessions across campus.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            if (activeSessions.isEmpty)
              const EmptyStateWidget(
                icon: Icons.sensors_off_rounded,
                title: 'No Active Sessions',
                subtitle: 'Classes that are currently taking attendance will be displayed here.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeSessions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final s = activeSessions[index];
                  return AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.success.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.sensors_rounded, color: AppColors.success, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.subjectName ?? 'Subject',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  Text(
                                    '${s.teacherName ?? "Faculty"} • Room ${s.room ?? "A"}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              label: 'LIVE',
                              color: AppColors.success,
                              small: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Started: ${DateFormat('hh:mm a').format(s.startTime)}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              'Expires: ${DateFormat('hh:mm a').format(s.endTime)}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // ── Student Directory Attendance Summary ────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enrolled Student Roster',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                TextButton.icon(
                  onPressed: students.isEmpty
                      ? null
                      : () async {
                          final ok = await CsvExportService.exportStudentRoster(
                            batchName: 'Campus Enrolled Students',
                            students: students,
                          );
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Campus student roster exported to CSV!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Export Roster (CSV)'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (students.isEmpty)
              const EmptyStateWidget(
                icon: Icons.people_outline_rounded,
                title: 'No Students Enrolled',
                subtitle: 'Enrolled students will appear here.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.take(6).length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final st = students[index];
                  return AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer,
                          child: Text(
                            st.user.initials,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.primaryDark : AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                st.user.name,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              Text(
                                '${st.studentId} • ${st.batchId.replaceAll("batch-", "").toUpperCase()}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const StatusBadge(
                          label: 'Enrolled',
                          color: AppColors.primary,
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
      ),
    );
  }
}
