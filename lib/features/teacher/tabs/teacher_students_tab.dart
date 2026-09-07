import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/data/models/course_model.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/core/enums/attendance_status.dart';
import 'package:presenza/data/models/profile_update_request_model.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/core/utils/csv_export_service.dart';

class TeacherStudentsTab extends ConsumerStatefulWidget {
  const TeacherStudentsTab({super.key});

  @override
  ConsumerState<TeacherStudentsTab> createState() => _TeacherStudentsTabState();
}

class _TeacherStudentsTabState extends ConsumerState<TeacherStudentsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedBatchId;
  int _selectedSegment = 0; // 0: Students, 1: Profile Requests
  final Set<String> _processingRequests = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStudentDetails(BuildContext context, StudentModel student, List<CourseModel> courses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final courseObj = courses.firstWhere(
      (c) => c.id == student.courseId,
      orElse: () => CourseModel(
        id: student.courseId,
        name: student.courseId.replaceAll('course-', '').toUpperCase(),
        code: student.courseId.replaceAll('course-', '').toUpperCase(),
        departmentId: '',
        totalSemesters: 8,
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withAlpha(20),
                    child: Text(
                      student.user.initials,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.user.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${student.studentId} • Sem ${student.semester} • Sec ${student.section}',
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
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 14),

              Text('Academic Details', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),

              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(label: 'Full Course', value: courseObj.name),
                    const Divider(height: 14),
                    _DetailRow(label: 'Batch', value: student.batchId.replaceAll('batch-', '').toUpperCase()),
                    const Divider(height: 14),
                    _DetailRow(label: 'Section', value: 'Section ${student.section}'),
                    const Divider(height: 14),
                    _DetailRow(label: 'Current Semester', value: 'Semester ${student.semester}'),
                    const Divider(height: 14),
                    _DetailRow(label: 'Roll / Student ID', value: student.studentId),
                    const Divider(height: 14),
                    _DetailRow(label: 'Email', value: student.user.email),
                    const Divider(height: 14),
                    _DetailRow(label: 'Phone', value: student.user.phone?.isNotEmpty == true ? student.user.phone! : 'Not provided'),
                    const Divider(height: 14),
                    _DetailRow(
                      label: 'Enrolled Date',
                      value: DateFormat('d MMM yyyy').format(student.enrollmentDate),
                    ),
                  ],
                ),
              ),

              if (student.user.bio != null && student.user.bio!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('About / Bio', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Text(student.user.bio!, style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],

              const SizedBox(height: 18),
              Text('Live Attendance Overview', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),

              Consumer(
                builder: (context, ref, _) {
                  final firestoreService = ref.watch(firestoreServiceProvider);
                  return StreamBuilder<List<AttendanceRecordModel>>(
                    stream: firestoreService.streamStudentAttendanceRecords(student.user.id),
                    builder: (context, snapshot) {
                      final records = snapshot.data ?? [];
                      final present = records.where((r) => r.status == AttendanceStatus.present).length;
                      final late = records.where((r) => r.status == AttendanceStatus.late).length;
                      final absent = records.where((r) => r.status == AttendanceStatus.absent).length;
                      final total = records.length;
                      final pct = total > 0 ? ((present + late) / total * 100).toStringAsFixed(1) : '0.0';

                      return AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _AttendanceStat(label: 'Present', count: present, color: AppColors.success),
                            _AttendanceStat(label: 'Late', count: late, color: AppColors.warning),
                            _AttendanceStat(label: 'Absent', count: absent, color: AppColors.error),
                            _AttendanceStat(label: 'Total', count: total, color: isDark ? Colors.white : Colors.black),
                            _AttendanceStat(label: 'Ratio', countStr: '$pct%', color: AppColors.primary),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  label: 'Correct Attendance',
                  icon: Icons.edit_calendar_rounded,
                  onPressed: () {
                    Navigator.pop(context);
                    AttendanceCorrectionModal.show(context, student);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _handleApprove(ProfileUpdateRequestModel req) async {
    final teacher = ref.read(teacherProfileProvider);
    final teacherName = teacher?.user.name ?? 'Faculty Advisor';
    final teacherUid = teacher?.user.id ?? '';

    setState(() => _processingRequests.add(req.id));
    try {
      await ref.read(firestoreServiceProvider).approveProfileUpdateRequest(
            requestId: req.id,
            teacherUid: teacherUid,
            teacherName: teacherName,
          );
      ref.invalidate(firestoreStudentsStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updates for ${req.studentName} validated & approved!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingRequests.remove(req.id));
    }
  }

  void _handleRejectDialog(ProfileUpdateRequestModel req) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Decline Profile Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to decline changes for ${req.studentName}?'),
            const SizedBox(height: 12),
            AppTextField(
              controller: reasonCtrl,
              labelText: 'Reason for Rejection',
              hintText: 'e.g. Invalid section or incorrect semester',
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dCtx);
              final teacher = ref.read(teacherProfileProvider);
              final teacherName = teacher?.user.name ?? 'Faculty Advisor';
              final teacherUid = teacher?.user.id ?? '';

              setState(() => _processingRequests.add(req.id));
              try {
                await ref.read(firestoreServiceProvider).rejectProfileUpdateRequest(
                      requestId: req.id,
                      teacherUid: teacherUid,
                      teacherName: teacherName,
                      reason: reasonCtrl.text.trim(),
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile update for ${req.studentName} was declined.'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                  );
                }
              } finally {
                if (mounted) setState(() => _processingRequests.remove(req.id));
              }
            },
            child: const Text('Decline Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(allStudentsProvider);
    final batches = ref.watch(batchesProvider).valueOrNull ?? [];
    final courses = ref.watch(allCoursesCatalogProvider);
    final pendingRequests = ref.watch(pendingProfileRequestsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = students.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.user.name.toLowerCase().contains(_searchQuery) ||
          s.studentId.toLowerCase().contains(_searchQuery) ||
          s.user.email.toLowerCase().contains(_searchQuery);
      final matchesBatch = _selectedBatchId == null || s.batchId == _selectedBatchId;
      return matchesSearch && matchesBatch;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(firestoreStudentsStreamProvider);
        ref.invalidate(pendingProfileRequestsStreamProvider);
      },
      child: Column(
        children: [
          // Segmented Switch: Students vs Profile Requests
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.elevatedDark : AppColors.slate200,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedSegment = 0),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedSegment == 0
                              ? (isDark ? AppColors.cardDark : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedSegment == 0
                              ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4, offset: const Offset(0, 1))]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Enrolled Students (${filtered.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: _selectedSegment == 0
                                ? (isDark ? Colors.white : AppColors.primary)
                                : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedSegment = 1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedSegment == 1
                              ? (isDark ? AppColors.cardDark : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedSegment == 1
                              ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4, offset: const Offset(0, 1))]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Profile Requests',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _selectedSegment == 1
                                    ? (isDark ? Colors.white : AppColors.primary)
                                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                              ),
                            ),
                            if (pendingRequests.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${pendingRequests.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_selectedSegment == 0) ...[
            // ── Tab 0: Students Directory ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: AppTextField(
                controller: _searchController,
                hintText: 'Search students by name, roll no, email...',
                prefixIcon: Icons.search_rounded,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),

            // Batch & Section Filter Chips + Export
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All Sections'),
                            selected: _selectedBatchId == null,
                            onSelected: (_) => setState(() => _selectedBatchId = null),
                          ),
                          const SizedBox(width: 8),
                          ...batches.map((b) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(b.name),
                                  selected: _selectedBatchId == b.id,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedBatchId = selected ? b.id : null;
                                    });
                                  },
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final ok = await CsvExportService.exportStudentRoster(
                        students: filtered,
                        batchName: _selectedBatchId != null
                            ? (batches.where((b) => b.id == _selectedBatchId).firstOrNull?.name ?? 'Section')
                            : 'All Sections',
                      );
                      if (context.mounted && ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Students roster exported to CSV successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Export'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: filtered.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.person_search_rounded,
                      title: 'No Students Found',
                      subtitle: 'No enrolled students match your search criteria.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final student = filtered[index];
                        final courseObj = courses.firstWhere(
                          (c) => c.id == student.courseId,
                          orElse: () => CourseModel(
                            id: student.courseId,
                            name: student.courseId.replaceAll('course-', '').toUpperCase(),
                            code: student.courseId.replaceAll('course-', '').toUpperCase(),
                            departmentId: '',
                            totalSemesters: 8,
                          ),
                        );

                        return AppCard(
                          onTap: () => _showStudentDetails(context, student, courses),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer,
                                child: Text(
                                  student.user.initials,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.user.name,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        _MiniPill(label: student.studentId, isDark: isDark),
                                        _MiniPill(label: courseObj.code, isDark: isDark),
                                        _MiniPill(label: 'Sec ${student.section}', isDark: isDark, isHighlighted: true),
                                        _MiniPill(label: 'Sem ${student.semester}', isDark: isDark),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 20),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ] else ...[
            // ── Tab 1: Profile Requests Review ──
            Expanded(
              child: pendingRequests.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.assignment_turned_in_rounded,
                      title: 'No Pending Requests',
                      subtitle: 'All student profile edits have been reviewed and resolved.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: pendingRequests.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final req = pendingRequests[index];
                        final isProcessing = _processingRequests.contains(req.id);

                        return AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primary.withAlpha(20),
                                    child: const Icon(Icons.edit_document, size: 18, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.studentName,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        Text(
                                          '${req.studentRollNo} • Submitted ${DateFormat('d MMM, hh:mm a').format(req.createdAt)}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withAlpha(30),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Pending Approval',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),

                              // Proposed Changes Breakdown
                              Text('Requested Changes:', style: Theme.of(context).textTheme.labelSmall),
                              const SizedBox(height: 8),

                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.elevatedDark : AppColors.slate100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    if (req.requestedName != req.studentName) ...[
                                      _DiffRow(label: 'Name', from: req.studentName, to: req.requestedName),
                                      const Divider(height: 12),
                                    ],
                                    if (req.requestedCourseId != (req.currentData['courseId'] ?? '')) ...[
                                      _DiffRow(
                                        label: 'Course',
                                        from: (req.currentData['courseId'] as String? ?? '').replaceAll('course-', '').toUpperCase(),
                                        to: req.requestedCourseId.replaceAll('course-', '').toUpperCase(),
                                      ),
                                      const Divider(height: 12),
                                    ],
                                    if (req.requestedSection != (req.currentData['section'] ?? 'A')) ...[
                                      _DiffRow(
                                        label: 'Section',
                                        from: 'Sec ${req.currentData['section'] ?? 'A'}',
                                        to: 'Sec ${req.requestedSection}',
                                      ),
                                      const Divider(height: 12),
                                    ],
                                    if (req.requestedSemester != ((req.currentData['semester'] as num?)?.toInt() ?? 1)) ...[
                                      _DiffRow(
                                        label: 'Semester',
                                        from: 'Sem ${req.currentData['semester'] ?? 1}',
                                        to: 'Sem ${req.requestedSemester}',
                                      ),
                                      const Divider(height: 12),
                                    ],
                                    if (req.requestedPhone != (req.currentData['phone'] as String?)) ...[
                                      _DiffRow(
                                        label: 'Phone',
                                        from: (req.currentData['phone'] as String?)?.isNotEmpty == true ? req.currentData['phone']! : 'None',
                                        to: req.requestedPhone?.isNotEmpty == true ? req.requestedPhone! : 'None',
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Approval Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: isProcessing ? null : () => _handleRejectDialog(req),
                                      icon: const Icon(Icons.close_rounded, size: 16),
                                      label: const Text('Decline'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(color: AppColors.error),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: isProcessing ? null : () => _handleApprove(req),
                                      icon: isProcessing
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.check_rounded, size: 16),
                                      label: const Text('Approve Changes'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool isHighlighted;

  const _MiniPill({required this.label, required this.isDark, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primary.withAlpha(isDark ? 35 : 20)
            : (isDark ? AppColors.elevatedDark : AppColors.slate200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
          color: isHighlighted
              ? AppColors.primary
              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        ),
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  final String label;
  final String from;
  final String to;

  const _DiffRow({required this.label, required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        Expanded(
          child: Row(
            children: [
              Text(from, style: const TextStyle(color: AppColors.slate400, fontSize: 12, decoration: TextDecoration.lineThrough)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(to, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  final String label;
  final int? count;
  final String? countStr;
  final Color color;

  const _AttendanceStat({required this.label, this.count, this.countStr, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          countStr ?? count.toString(),
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}
