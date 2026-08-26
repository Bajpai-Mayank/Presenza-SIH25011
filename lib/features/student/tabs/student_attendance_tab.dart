import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/attendance_status.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class StudentAttendanceTab extends ConsumerStatefulWidget {
  const StudentAttendanceTab({super.key});

  @override
  ConsumerState<StudentAttendanceTab> createState() => _StudentAttendanceTabState();
}

class _StudentAttendanceTabState extends ConsumerState<StudentAttendanceTab> {
  String _filter = 'all'; // 'all', 'safe', 'risk'

  void _showSubjectLogs(BuildContext context, SubjectAttendance sa) {
    final recordsAsync = ref.read(studentAttendanceRecordsProvider);
    final allRecords = recordsAsync.valueOrNull ?? [];
    final subjectRecords = allRecords.where((r) => r.subjectId == sa.subjectId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sa.subjectName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          '${sa.subjectCode} • ${sa.teacherName ?? "Faculty"}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: subjectRecords.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.history_toggle_off_rounded,
                      title: 'No Session Records',
                      subtitle: 'No attendance sessions have been logged for this subject yet.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: subjectRecords.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final rec = subjectRecords[index];
                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (rec.status == AttendanceStatus.present
                                          ? AppColors.success
                                          : AppColors.error)
                                      .withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  rec.status == AttendanceStatus.present
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.cancel_outlined,
                                  color: rec.status == AttendanceStatus.present
                                      ? AppColors.success
                                      : AppColors.error,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('EEEE, d MMM yyyy').format(rec.timestamp),
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${DateFormat('hh:mm a').format(rec.timestamp)} • Via ${rec.verificationMethod.displayName}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (rec.locationVerified)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                                ),
                              StatusBadge(
                                label: rec.status.displayName,
                                color: rec.status == AttendanceStatus.present
                                    ? AppColors.success
                                    : AppColors.error,
                                small: true,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectAttendanceProvider);
    final recordsAsync = ref.watch(studentAttendanceRecordsProvider);
    final allRecords = recordsAsync.valueOrNull ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = subjects.where((sa) {
      if (_filter == 'safe') return sa.percentage >= 75.0;
      if (_filter == 'risk') return sa.percentage < 75.0;
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentAttendanceRecordsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Overview
            Text(
              'Monthly Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: AttendanceCalendar(
                records: allRecords,
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Subject Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),

            // Filter Pills Row
            Row(
              children: [
                ChoiceChip(
                  label: Text('All Subjects (${subjects.length})'),
                  selected: _filter == 'all',
                  onSelected: (_) => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text('Safe (≥75%) (${subjects.where((s) => s.percentage >= 75).length})'),
                  selected: _filter == 'safe',
                  onSelected: (_) => setState(() => _filter = 'safe'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.warning_amber_rounded, size: 16),
                  label: Text('At Risk (<75%) (${subjects.where((s) => s.percentage < 75).length})'),
                  selected: _filter == 'risk',
                  onSelected: (_) => setState(() => _filter = 'risk'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (filtered.isEmpty)
              EmptyStateWidget(
                icon: Icons.checklist_rtl_rounded,
                title: 'No Matching Subjects',
                subtitle: _filter == 'risk'
                    ? 'Great job! You have no subjects below the 75% attendance threshold.'
                    : 'No enrolled subjects found in your course catalog.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final sa = filtered[index];
                  final statusMsg = sa.getStatusMessage();
                  final isSafe = sa.percentage >= 75.0;

                  return AppCard(
                    onTap: () => _showSubjectLogs(context, sa),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sa.subjectName,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${sa.subjectCode}${sa.credits != null ? ' • ${sa.credits} Credits' : ''}${sa.teacherName != null ? ' • ${sa.teacherName}' : ''}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: (isSafe ? AppColors.success : AppColors.error).withAlpha(isDark ? 30 : 20),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (isSafe ? AppColors.success : AppColors.error).withAlpha(80),
                                ),
                              ),
                              child: Text(
                                '${sa.percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isSafe ? AppColors.success : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        AttendanceProgressBar(
                          percentage: sa.percentage,
                          height: 8,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            _MetricItem(label: 'Present', count: sa.present, color: AppColors.success),
                            const SizedBox(width: 16),
                            _MetricItem(label: 'Absent', count: sa.absent, color: AppColors.error),
                            const SizedBox(width: 16),
                            _MetricItem(label: 'Late', count: sa.late, color: AppColors.warning),
                            const SizedBox(width: 16),
                            _MetricItem(label: 'Conducted', count: sa.totalClasses, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.elevatedDark : AppColors.slate100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSafe ? Icons.insights_rounded : Icons.warning_amber_rounded,
                                size: 16,
                                color: isSafe ? AppColors.primary : AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  statusMsg,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: isSafe ? null : AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ],
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

class _MetricItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
