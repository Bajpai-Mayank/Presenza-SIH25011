import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/providers/app_providers.dart';

/// Shown when a user is authenticated via Firebase Auth but
/// their Firestore profile has not been initialized.
class NoProfileScreen extends ConsumerStatefulWidget {
  const NoProfileScreen({super.key});

  @override
  ConsumerState<NoProfileScreen> createState() => _NoProfileScreenState();
}

class _NoProfileScreenState extends ConsumerState<NoProfileScreen> {
  bool _isAutoProvisioning = false;

  Future<void> _autoInitializeStudentProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isAutoProvisioning = true);
    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      final now = DateTime.now();
      final userModel = UserModel(
        id: user.uid,
        email: user.email ?? 'student@presenza.edu',
        name: user.displayName ?? 'Student Scholar',
        role: UserRole.student,
        bio: 'Computer Science Undergraduate',
        department: 'Computer Science & Engineering',
        createdAt: now,
        updatedAt: now,
      );
      await firestoreService.saveUserModel(userModel);

      final studentModel = StudentModel(
        user: userModel,
        studentId: 'STU-${user.uid.substring(0, 6).toUpperCase()}',
        courseId: 'course-btech-cse',
        batchId: 'batch-2024-a',
        semester: 4,
        enrollmentDate: now,
      );
      await firestoreService.saveStudentProfile(studentModel);
      await firestoreService.seedInitialAcademicData();

      await ref.read(authStatusProvider.notifier).refreshProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set up profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAutoProvisioning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer,
                      border: Border.all(
                        color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                      ),
                    ),
                    child: Icon(
                      Icons.person_pin_circle_rounded,
                      size: 38,
                      color: isDark ? AppColors.primaryDark : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Setup Profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your account authentication was verified, but your academic profile record is not yet linked.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                        ),
                  ),
                  const SizedBox(height: 28),

                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 22,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '1-Tap Student Profile Creation',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Initialize your default student dashboard and enroll in B.Tech CSE subjects immediately.',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppButton.primary(
                          label: 'Initialize Student Profile',
                          isLoading: _isAutoProvisioning,
                          onPressed: _autoInitializeStudentProfile,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ref.read(authStatusProvider.notifier).refreshProfile(),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Refresh Status'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () => ref.read(authStateProvider.notifier).logout(),
                          child: const Text('Sign Out'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
