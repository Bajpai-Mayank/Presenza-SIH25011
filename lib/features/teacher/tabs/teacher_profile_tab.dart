import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/models/course_model.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class TeacherProfileTab extends ConsumerWidget {
  const TeacherProfileTab({super.key});

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref, String teacherUid) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final courses = ref.read(coursesProvider).valueOrNull ?? [];
    String selectedCourseId = courses.isNotEmpty ? courses.first.id : 'course-btech-cse';
    int selectedSemester = 4;
    int selectedCredits = 4;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Academic Subject'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: nameCtrl,
                    labelText: 'Subject Name',
                    hintText: 'e.g. Cloud Computing & DevOps',
                    prefixIcon: Icons.book_outlined,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: codeCtrl,
                    labelText: 'Subject Code',
                    hintText: 'e.g. CS502',
                    prefixIcon: Icons.pin_outlined,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedSemester,
                          decoration: const InputDecoration(labelText: 'Semester'),
                          items: List.generate(8, (i) => i + 1).map((s) {
                            return DropdownMenuItem(value: s, child: Text('Sem $s'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedSemester = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedCredits,
                          decoration: const InputDecoration(labelText: 'Credits'),
                          items: [1, 2, 3, 4, 5].map((c) {
                            return DropdownMenuItem(value: c, child: Text('$c Credits'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedCredits = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      final newSubject = SubjectModel(
                        id: 'sub-${const Uuid().v4().substring(0, 8)}',
                        name: nameCtrl.text.trim(),
                        code: codeCtrl.text.trim().toUpperCase(),
                        courseId: selectedCourseId,
                        semester: selectedSemester,
                        credits: selectedCredits,
                        teacherId: teacherUid,
                      );

                      await ref.read(firestoreServiceProvider).addTeacherSubject(
                            teacherUid: teacherUid,
                            subject: newSubject,
                          );

                      await ref.read(teacherProfileProvider.notifier).refresh();

                      if (context.mounted) {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Academic subject created & assigned!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Subject'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final bioCtrl = TextEditingController(text: user.bio ?? '');
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Faculty Profile'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: nameCtrl,
                    labelText: 'Full Name',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: bioCtrl,
                    labelText: 'Bio / Department Role',
                    hintText: 'e.g. Professor & Head of Lab...',
                    prefixIcon: Icons.edit_note_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: phoneCtrl,
                    labelText: 'Phone Number',
                    hintText: '+91 98765 43210',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      await ref.read(firestoreServiceProvider).updateUserProfile(
                            uid: user.id,
                            name: nameCtrl.text.trim(),
                            bio: bioCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                          );

                      await ref.read(authStatusProvider.notifier).refreshProfile();
                      await ref.read(teacherProfileProvider.notifier).refresh();

                      if (context.mounted) {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Faculty profile updated!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your faculty account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacher = ref.watch(teacherProfileProvider);
    final subjects = ref.watch(teacherSubjectsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (teacher == null) {
      return const LoadingState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Faculty Profile Card
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer,
                      child: Text(
                        teacher.user.initials,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.primaryDark : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacher.user.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            teacher.user.email,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: const [
                              RoleBadge(role: UserRole.teacher),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showEditProfileDialog(context, ref, teacher.user),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _TeacherDetailItem(
                        label: 'Employee ID',
                        value: teacher.employeeId,
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    Expanded(
                      child: _TeacherDetailItem(
                        label: 'Department',
                        value: teacher.user.department ?? 'Computer Science',
                        icon: Icons.apartment_rounded,
                      ),
                    ),
                  ],
                ),
                if (teacher.user.bio != null && teacher.user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.elevatedDark : AppColors.slate100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      teacher.user.bio!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Assigned Subjects Section with Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Assigned Subjects',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              TextButton.icon(
                onPressed: () => _showAddSubjectDialog(context, ref, teacher.user.id),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Subject'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (subjects.isEmpty)
            const EmptyStateWidget(
              icon: Icons.menu_book_outlined,
              title: 'No Subjects Assigned',
              subtitle: 'Click Add Subject above to assign new course modules.',
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
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.elevatedDark : AppColors.slate100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.book_outlined, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
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
                              '${sub.code} • Sem ${sub.semester} • ${sub.credits} Credits',
                              style: Theme.of(context).textTheme.bodySmall,
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

          // Settings Section
          Text(
            'Settings & Preferences',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Appearance & Theme'),
                  subtitle: Text(
                    themeMode == ThemeMode.system
                        ? 'System Default'
                        : (themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode'),
                  ),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                    onChanged: (newMode) {
                      if (newMode != null) {
                        ref.read(themeModeProvider.notifier).setThemeMode(newMode);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.security_rounded),
                  title: const Text('Session Security'),
                  subtitle: const Text('Dynamic QR tokenization & replay protection active'),
                  trailing: const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 18),
                ),
                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: const Text('Help & Support'),
                  subtitle: const Text('Presenza Faculty documentation & FAQs'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    context.push('/help');
                  },
                ),
                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  onTap: () => _showLogoutDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _TeacherDetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TeacherDetailItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
