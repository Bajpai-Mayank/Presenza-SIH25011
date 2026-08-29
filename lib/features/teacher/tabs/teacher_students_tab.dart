import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/data/models/user_model.dart';
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

  void _showStudentDetails(BuildContext context, StudentModel student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
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
                      Text(
                        '${student.studentId} • Semester ${student.semester}',
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
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            Text('Academic Profile', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),

            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(label: 'Email', value: student.user.email),
                  const Divider(height: 16),
                  _DetailRow(label: 'Course', value: student.courseId.replaceAll('course-', '').toUpperCase()),
                  const Divider(height: 16),
                  _DetailRow(label: 'Batch', value: student.batchId.replaceAll('batch-', '').toUpperCase()),
                  const Divider(height: 16),
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(allStudentsProvider);
    final batches = ref.watch(batchesProvider).valueOrNull ?? [];
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
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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

          // Batch Filter Chips & Export Button
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
                        ...batches.map((b) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(b.name),
                              selected: _selectedBatchId == b.id,
                              onSelected: (val) {
                                setState(() => _selectedBatchId = val ? b.id : null);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.file_download_outlined, size: 20),
                  tooltip: 'Export Student Roster (CSV)',
                  onPressed: filtered.isEmpty
                      ? null
                      : () async {
                          final batchName = _selectedBatchId != null
                              ? (batches.where((b) => b.id == _selectedBatchId).firstOrNull?.name ?? 'Section')
                              : 'All Students';
                          final ok = await CsvExportService.exportStudentRoster(
                            batchName: batchName,
                            students: filtered,
                          );
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Student roster exported to CSV successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final student = filtered[index];
                      return AppCard(
                        onTap: () => _showStudentDetails(context, student),
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
                                  const SizedBox(height: 2),
                                  Text(
                                    '${student.studentId} • ${student.batchId.replaceAll("batch-", "").toUpperCase()}',
                                    style: Theme.of(context).textTheme.bodySmall,
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
        ],
      ),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
