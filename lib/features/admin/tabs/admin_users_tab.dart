import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class _AdminUserItem {
  final UserModel user;
  final String displayId;
  final StudentModel? student;
  final TeacherModel? teacher;

  _AdminUserItem({
    required this.user,
    required this.displayId,
    this.student,
    this.teacher,
  });
}

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  UserRole? _filterRole;
  bool _onlyActive = false;

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
    final teachers = ref.watch(allTeachersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allItems = <_AdminUserItem>[
      ...students.map((s) => _AdminUserItem(
            user: s.user,
            displayId: s.studentId,
            student: s,
          )),
      ...teachers.map((t) => _AdminUserItem(
            user: t.user,
            displayId: t.employeeId,
            teacher: t,
          )),
    ];

    final activeCount = allItems.where((i) => i.user.isCurrentlyActive).length;

    final filtered = allItems.where((item) {
      if (_onlyActive && !item.user.isCurrentlyActive) {
        return false;
      }
      if (_filterRole != null && item.user.role != _filterRole) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final matchesName = item.user.name.toLowerCase().contains(_searchQuery);
        final matchesId = item.displayId.toLowerCase().contains(_searchQuery);
        final matchesEmail = item.user.email.toLowerCase().contains(_searchQuery);
        if (!matchesName && !matchesId && !matchesEmail) {
          return false;
        }
      }
      return true;
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

        // Filter Chips Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            children: [
              ChoiceChip(
                label: Text('All Users (${allItems.length})'),
                selected: _filterRole == null && !_onlyActive,
                onSelected: (_) => setState(() {
                  _filterRole = null;
                  _onlyActive = false;
                }),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: Icon(
                  Icons.circle,
                  size: 10,
                  color: _onlyActive ? Colors.white : AppColors.success,
                ),
                label: Text('Active Now ($activeCount)'),
                selected: _onlyActive,
                selectedColor: AppColors.success,
                onSelected: (val) => setState(() {
                  _onlyActive = val;
                  if (val) _filterRole = null;
                }),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Students (${students.length})'),
                selected: _filterRole == UserRole.student && !_onlyActive,
                onSelected: (_) => setState(() {
                  _filterRole = UserRole.student;
                  _onlyActive = false;
                }),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Faculty (${teachers.length})'),
                selected: _filterRole == UserRole.teacher && !_onlyActive,
                onSelected: (_) => setState(() {
                  _filterRole = UserRole.teacher;
                  _onlyActive = false;
                }),
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
                  subtitle: 'Try refining your search query or filter criteria.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isActive = item.user.isCurrentlyActive;

                    return AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isDark
                                    ? AppColors.primaryContainerDark
                                    : AppColors.primaryContainer,
                                child: Text(
                                  item.user.initials,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.primaryDark
                                        : AppColors.primary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive
                                        ? AppColors.success
                                        : AppColors.slate400,
                                    border: Border.all(
                                      color: Theme.of(context).cardColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.user.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    StatusBadge(
                                      label: isActive ? 'Active Now' : 'Offline',
                                      color: isActive
                                          ? AppColors.success
                                          : AppColors.slate400,
                                      small: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${item.displayId} • ${item.user.email}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 12,
                                      color: isActive
                                          ? AppColors.success
                                          : (isDark
                                              ? AppColors.textMutedDark
                                              : AppColors.textMutedLight),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        isActive
                                            ? 'Active now in portal'
                                            : (item.user.lastLoginAt != null
                                                ? 'Last logged in: ${DateFormat('d MMM, hh:mm a').format(item.user.lastLoginAt!)}'
                                                : (item.user.lastActiveAt != null
                                                    ? 'Last active: ${DateFormat('d MMM, hh:mm a').format(item.user.lastActiveAt!)}'
                                                    : 'No login recorded')),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isActive
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isActive
                                              ? AppColors.success
                                              : (isDark
                                                  ? AppColors.textMutedDark
                                                  : AppColors.textMutedLight),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (item.student != null)
                            IconButton(
                              icon: const Icon(Icons.edit_calendar_rounded,
                                  size: 20),
                              tooltip: 'Correct Attendance',
                              onPressed: () {
                                AttendanceCorrectionModal.show(
                                    context, item.student!);
                              },
                            ),
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
