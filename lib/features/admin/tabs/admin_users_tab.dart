import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  UserRole? _filterRole;

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
    final students = ref.watch(allStudentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = students.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.user.name.toLowerCase().contains(_searchQuery) ||
          s.studentId.toLowerCase().contains(_searchQuery) ||
          s.user.email.toLowerCase().contains(_searchQuery);
      return matchesSearch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: AppTextField(
            controller: _searchController,
            hintText: 'Search by student name, roll number, email...',
            prefixIcon: Icons.search_rounded,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
          ),
        ),

        // Role Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            children: [
              ChoiceChip(
                label: Text('All Users (${students.length})'),
                selected: _filterRole == null,
                onSelected: (_) => setState(() => _filterRole = null),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Students'),
                selected: _filterRole == UserRole.student,
                onSelected: (_) => setState(() => _filterRole = UserRole.student),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Faculty'),
                selected: _filterRole == UserRole.teacher,
                onSelected: (_) => setState(() => _filterRole = UserRole.teacher),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: filtered.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.person_search_rounded,
                  title: 'No Users Found',
                  subtitle: 'Try refining your search query.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final student = filtered[index];
                    return AppCard(
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
                                  '${student.studentId} • ${student.user.email}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (student.user.role == UserRole.student)
                            IconButton(
                              icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                              tooltip: 'Correct Attendance',
                              onPressed: () {
                                AttendanceCorrectionModal.show(context, student);
                              },
                            )
                          else
                            const RoleBadge(role: UserRole.student),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
