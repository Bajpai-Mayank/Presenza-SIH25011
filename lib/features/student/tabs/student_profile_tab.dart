import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/data/models/course_model.dart';
import 'package:presenza/data/models/profile_update_request_model.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';

class StudentProfileTab extends ConsumerWidget {
  const StudentProfileTab({super.key});

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, StudentModel student) {
    final courses = ref.read(allCoursesCatalogProvider);
    final nameCtrl = TextEditingController(text: student.user.name);
    final bioCtrl = TextEditingController(text: student.user.bio ?? '');
    final phoneCtrl = TextEditingController(text: student.user.phone ?? '');
    
    String selectedCourseId = student.courseId;
    String selectedSection = student.section.isNotEmpty ? student.section : 'A';
    int selectedSemester = student.semester;

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (stfCtx, setDialogState) => AlertDialog(
          title: const Text('Edit Profile & Academics'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Academic profile modifications require faculty verification before validation.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: nameCtrl,
                    labelText: 'Full Name *',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 14),
                  // Course Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: courses.any((c) => c.id == selectedCourseId)
                        ? selectedCourseId
                        : (courses.isNotEmpty ? courses.first.id : selectedCourseId),
                    decoration: InputDecoration(
                      labelText: 'Course *',
                      prefixIcon: const Icon(Icons.school_outlined),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.cardDark
                          : AppColors.cardLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    isExpanded: true,
                    items: courses.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          c.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCourseId = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Section Dropdown
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: ['A', 'B', 'C', 'D', 'E', 'F'].contains(selectedSection.toUpperCase())
                              ? selectedSection.toUpperCase()
                              : 'A',
                          decoration: InputDecoration(
                            labelText: 'Section *',
                            prefixIcon: const Icon(Icons.grid_view_rounded),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.cardDark
                                : AppColors.cardLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: ['A', 'B', 'C', 'D', 'E', 'F'].map((sec) {
                            return DropdownMenuItem(value: sec, child: Text('Sec $sec'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedSection = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Semester Dropdown
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: (selectedSemester >= 1 && selectedSemester <= 8) ? selectedSemester : 1,
                          decoration: InputDecoration(
                            labelText: 'Semester *',
                            prefixIcon: const Icon(Icons.history_edu_outlined),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.cardDark
                                : AppColors.cardLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: List.generate(8, (i) => i + 1).map((sem) {
                            return DropdownMenuItem(value: sem, child: Text('Sem $sem'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedSemester = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: phoneCtrl,
                    labelText: 'Phone Number',
                    hintText: '+91 98765 43210',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: bioCtrl,
                    labelText: 'Bio / About',
                    hintText: 'Share your academic interests...',
                    prefixIcon: Icons.edit_note_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      try {
                        final newName = nameCtrl.text.trim();
                        final newBio = bioCtrl.text.trim();
                        final newPhone = phoneCtrl.text.trim();
                        final batchYear = DateTime.now().year;
                        final newBatchId = 'batch_${selectedCourseId}_${batchYear}_${selectedSection.toLowerCase()}';

                        final req = ProfileUpdateRequestModel(
                          id: const Uuid().v4(),
                          studentUid: student.user.id,
                          studentName: student.user.name,
                          studentRollNo: student.studentId,
                          currentData: {
                            'name': student.user.name,
                            'courseId': student.courseId,
                            'batchId': student.batchId,
                            'section': student.section,
                            'semester': student.semester,
                            'phone': student.user.phone ?? '',
                            'bio': student.user.bio ?? '',
                          },
                          requestedData: {
                            'name': newName,
                            'courseId': selectedCourseId,
                            'batchId': newBatchId,
                            'section': selectedSection,
                            'semester': selectedSemester,
                            'phone': newPhone,
                            'bio': newBio,
                          },
                          status: 'pending',
                          createdAt: DateTime.now(),
                        );

                        await ref.read(firestoreServiceProvider).createProfileUpdateRequest(req);

                        if (dialogCtx.mounted) {
                          Navigator.of(dialogCtx).pop();
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile change request sent to faculty for approval!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (stfCtx.mounted) {
                          setDialogState(() => isSaving = false);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to submit profile update: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit for Approval'),
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

      final updatedUser = user.copyWith(
        avatarUrl: dataUri,
        updatedAt: DateTime.now(),
      );

      ref.read(authStatusProvider.notifier).updateLocalUser(updatedUser);
      ref.read(studentProfileProvider.notifier).updateUserData(
        avatarUrl: dataUri,
      );

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
    final courses = ref.watch(allCoursesCatalogProvider);
    final pendingReq = ref.watch(studentProfileRequestStreamProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (student == null) {
      return const LoadingState();
    }

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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending Approval Alert Banner
          if (pendingReq != null && pendingReq.isPending) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(isDark ? 30 : 20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withAlpha(100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile Changes Pending Approval',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.warning),
                            ),
                            Text(
                              'Submitted on ${DateFormat('d MMM, hh:mm a').format(pendingReq.createdAt)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Awaiting Faculty',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Requested: ${pendingReq.requestedName != student.user.name ? "Name: ${pendingReq.requestedName} • " : ""}'
                    'Course: ${pendingReq.requestedCourseId.replaceAll("course-", "").toUpperCase()} • '
                    'Sec ${pendingReq.requestedSection} • Sem ${pendingReq.requestedSemester}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Profile Header Card
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(
                      avatarUrl: student.user.avatarUrl,
                      initials: student.user.initials,
                      radius: 36,
                      showEditBadge: true,
                      onTap: () => _pickAndUploadProfilePicture(context, ref, student.user),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  student.user.name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => _showEditProfileDialog(context, ref, student),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Edit Profile & Academics',
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student.user.email,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.elevatedDark : AppColors.slate200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${student.studentId} • Sem ${student.semester} • Sec ${student.section}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Academic details (Clean, responsive multi-card layout so course name is never hidden)
                Column(
                  children: [
                    _ProfileInfoCard(
                      label: 'Enrolled Course',
                      value: courseObj.name,
                      icon: Icons.school_outlined,
                      fullWidth: true,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileInfoCard(
                            label: 'Batch & Section',
                            value: 'Batch ${student.batchId.replaceAll('batch-', '').toUpperCase()} (Sec ${student.section})',
                            icon: Icons.group_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ProfileInfoCard(
                            label: 'Current Semester',
                            value: 'Semester ${student.semester}',
                            icon: Icons.history_edu_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileInfoCard(
                            label: 'Phone Number',
                            value: student.user.phone?.isNotEmpty == true ? student.user.phone! : 'Not provided',
                            icon: Icons.phone_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ProfileInfoCard(
                            label: 'Enrollment Date',
                            value: DateFormat('d MMM yyyy').format(student.enrollmentDate),
                            icon: Icons.calendar_today_outlined,
                          ),
                        ),
                      ],
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
          const SizedBox(height: 16),

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
          const SizedBox(height: 16),

          // Achievements & Milestones Showcase
          Text(
            'Achievements & Milestones',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final ach = achievements[index];
              return AppCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: (ach.isUnlocked ? ach.color : AppColors.slate400).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            ach.icon,
                            color: ach.isUnlocked ? ach.color : AppColors.slate400,
                            size: 16,
                          ),
                        ),
                        Icon(
                          ach.isUnlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
                          size: 14,
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
                                fontSize: 12,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ach.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 9,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Settings Section
          Text(
            'Settings & Preferences',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),

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
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool fullWidth;

  const _ProfileInfoCard({
    required this.label,
    required this.value,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevatedDark : AppColors.slate100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
