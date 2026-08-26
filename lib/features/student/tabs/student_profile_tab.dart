import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class StudentProfileTab extends ConsumerWidget {
  const StudentProfileTab({super.key});

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
          title: const Text('Edit Profile'),
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
                    labelText: 'Bio / About',
                    hintText: 'Share your academic interests...',
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
                      await ref.read(studentProfileProvider.notifier).refresh();

                      if (context.mounted) {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully!'),
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
        content: const Text('Are you sure you want to sign out of your Presenza account?'),
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
              ref.read(authStatusProvider.notifier).logout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadProfilePicture(BuildContext context, WidgetRef ref, UserModel user) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      
      // Compress the image
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 400,
        minHeight: 400,
        quality: 70,
      );

      final base64String = base64Encode(compressedBytes);
      final dataUri = 'data:image/jpeg;base64,$base64String';

      await ref.read(firestoreServiceProvider).updateUserProfile(
        uid: user.id,
        avatarUrl: dataUri,
      );

      await ref.read(authStatusProvider.notifier).refreshProfile();
      await ref.read(studentProfileProvider.notifier).refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update picture: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final overall = ref.watch(overallAttendanceProvider);
    final streak = ref.watch(attendanceStreakProvider);
    final subjects = ref.watch(subjectAttendanceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (student == null) {
      return const LoadingState();
    }

    final totalClasses = subjects.fold(0, (s, sa) => s + sa.totalClasses);
    final totalPresent = subjects.fold(0, (s, sa) => s + sa.present + sa.late);

    final achievements = [
      AchievementModel(
        id: '1',
        title: 'Perfect Attendance Week',
        description: 'Attended 100% of classes in a single academic week',
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFFF59E0B),
        isUnlocked: totalPresent >= 5,
      ),
      AchievementModel(
        id: '2',
        title: '75%+ Club Scholar',
        description: 'Maintained safe eligible status across all subjects',
        icon: Icons.shield_outlined,
        color: AppColors.primary,
        isUnlocked: overall >= 75.0,
      ),
      AchievementModel(
        id: '3',
        title: 'Consistent Streaker',
        description: 'Achieved a consecutive attendance streak of 5+ days',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFEA580C),
        isUnlocked: streak >= 3,
      ),
      AchievementModel(
        id: '4',
        title: 'Campus Participant',
        description: 'Active participant in college workshops and activities',
        icon: Icons.celebration_outlined,
        color: const Color(0xFF0D9488),
        isUnlocked: true,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Card
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _pickAndUploadProfilePicture(context, ref, student.user),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer,
                            backgroundImage: student.user.avatarUrl != null 
                                ? (student.user.avatarUrl!.startsWith('data:') 
                                    ? MemoryImage(base64Decode(student.user.avatarUrl!.split(',')[1])) 
                                    : NetworkImage(student.user.avatarUrl!) as ImageProvider)
                                : null,
                            child: student.user.avatarUrl == null ? Text(
                              student.user.initials,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.primaryDark : AppColors.primary,
                              ),
                            ) : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
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
                          const SizedBox(height: 4),
                          Text(
                            student.user.email,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: const [
                              RoleBadge(role: UserRole.student),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showEditProfileDialog(context, ref, student.user),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Academic details
                Row(
                  children: [
                    Expanded(
                      child: _ProfileInfoItem(
                        label: 'Roll No',
                        value: student.studentId,
                        icon: Icons.fingerprint_rounded,
                      ),
                    ),
                    Expanded(
                      child: _ProfileInfoItem(
                        label: 'Semester',
                        value: 'Semester ${student.semester}',
                        icon: Icons.school_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileInfoItem(
                        label: 'Department',
                        value: student.user.department ?? 'Computer Science',
                        icon: Icons.apartment_rounded,
                      ),
                    ),
                    Expanded(
                      child: _ProfileInfoItem(
                        label: 'Batch',
                        value: student.batchId.replaceAll('batch-', '').toUpperCase(),
                        icon: Icons.group_outlined,
                      ),
                    ),
                  ],
                ),
                if (student.user.bio != null && student.user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.elevatedDark : AppColors.slate100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      student.user.bio!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Stats Grid
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Attendance',
                  value: '${overall.toStringAsFixed(0)}%',
                  icon: Icons.pie_chart_outline_rounded,
                  iconColor: overall >= 75 ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Classes Attended',
                  value: '$totalPresent / $totalClasses',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Achievements & Milestones Showcase
          Text(
            'Achievements & Milestones',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final ach = achievements[index];
              return AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (ach.isUnlocked ? ach.color : AppColors.slate400).withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            ach.icon,
                            color: ach.isUnlocked ? ach.color : AppColors.slate400,
                            size: 20,
                          ),
                        ),
                        Icon(
                          ach.isUnlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
                          size: 16,
                          color: ach.isUnlocked ? AppColors.success : AppColors.slate400,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ach.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ach.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
                // Theme Option: System / Light / Dark
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
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Privacy & Security'),
                  subtitle: const Text('FLAG_SECURE screenshot protection enabled'),
                  trailing: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                ),
                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: const Text('Help & Support'),
                  subtitle: const Text('Presenza SIH25011 documentation & FAQs'),
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

class _ProfileInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileInfoItem({
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
