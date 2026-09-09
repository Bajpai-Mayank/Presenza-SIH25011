import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class AdminCoursesScreen extends ConsumerStatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  ConsumerState<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends ConsumerState<AdminCoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedDept;

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

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(allCoursesCatalogProvider);
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final batches = ref.watch(batchesProvider).valueOrNull ?? [];
    final students = ref.watch(allStudentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final departments = courses.map((c) => c.departmentId).toSet().toList()..sort();

    final filteredCourses = courses.where((c) {
      final matchesSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery) ||
          c.code.toLowerCase().contains(_searchQuery) ||
          c.departmentId.toLowerCase().contains(_searchQuery);
      final matchesDept = _selectedDept == null || c.departmentId == _selectedDept;
      return matchesSearch && matchesDept;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Courses & Curricula'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: AppTextField(
              controller: _searchController,
              hintText: 'Search courses by name, code, or department...',
              prefixIcon: Icons.search_rounded,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),

          // Department filter chips
          if (departments.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('All (${courses.length})'),
                    selected: _selectedDept == null,
                    onSelected: (_) => setState(() => _selectedDept = null),
                  ),
                  const SizedBox(width: 8),
                  ...departments.map((dept) {
                    final isSelected = _selectedDept == dept;
                    final count = courses.where((c) => c.departmentId == dept).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${dept.replaceAll('dept-', '').toUpperCase()} ($count)'),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() => _selectedDept = val ? dept : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          const Divider(height: 1),

          Expanded(
            child: filteredCourses.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.school_outlined,
                    title: 'No Courses Found',
                    subtitle: 'Try refining your search query or department filter.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    itemCount: filteredCourses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final course = filteredCourses[index];
                      final courseSubjects = subjects.where((s) => s.courseId == course.id).toList();
                      final courseBatches = batches.where((b) => b.courseId == course.id).toList();
                      final enrolledStudentsCount = students.where((s) => s.courseId == course.id).length;

                      return AppCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_rounded,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppColors.elevatedDark : AppColors.slate200,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              course.code,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            course.departmentId.replaceAll('dept-', '').toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (course.description != null && course.description!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                course.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Metrics summary row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetricItem(
                                  context,
                                  icon: Icons.calendar_view_month_rounded,
                                  label: 'Semesters',
                                  value: course.totalSemesters.toString(),
                                  isDark: isDark,
                                ),
                                _buildMetricItem(
                                  context,
                                  icon: Icons.groups_rounded,
                                  label: 'Active Batches',
                                  value: courseBatches.length.toString(),
                                  isDark: isDark,
                                ),
                                _buildMetricItem(
                                  context,
                                  icon: Icons.person_outline_rounded,
                                  label: 'Enrolled',
                                  value: enrolledStudentsCount.toString(),
                                  isDark: isDark,
                                ),
                                _buildMetricItem(
                                  context,
                                  icon: Icons.auto_stories_rounded,
                                  label: 'Subjects',
                                  value: courseSubjects.length.toString(),
                                  isDark: isDark,
                                ),
                              ],
                            ),

                            // Subjects collapsible list
                            if (courseSubjects.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  childrenPadding: const EdgeInsets.only(top: 8),
                                  title: Text(
                                    'Curriculum Subjects (${courseSubjects.length})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  children: courseSubjects.map((sub) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.cardDark : AppColors.slate100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withAlpha(25),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              sub.code,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              sub.name,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Sem ${sub.semester} • ${sub.credits} Cr',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
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

  Widget _buildMetricItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }
}
