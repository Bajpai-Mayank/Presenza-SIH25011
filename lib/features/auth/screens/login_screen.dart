import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final errorMessage = await ref
        .read(authStateProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text.trim());

    if (mounted) {
      setState(() => _isLoading = false);
      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 1-Click Fast Access: Signs in or automatically provisions demo test accounts on Firebase.
  Future<void> _quickTestLogin(UserRole role) async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    String email;
    String name;
    const password = 'Password@123';

    switch (role) {
      case UserRole.student:
        email = 'student@presenza.edu';
        name = 'Alex Rivera';
        break;
      case UserRole.teacher:
        email = 'teacher@presenza.edu';
        name = 'Dr. Robert Lang';
        break;
      case UserRole.admin:
        email = 'admin@presenza.edu';
        name = 'Campus Administrator';
        break;
    }

    _emailController.text = email;
    _passwordController.text = password;

    final authService = ref.read(authServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      // 1. Try standard sign in
      final signinResult = await authService.signIn(
        email: email,
        password: password,
      );

      if (signinResult.success && signinResult.user != null) {
        await ref.read(authStatusProvider.notifier).refreshProfile();
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. If account does not exist, auto-provision real account on Firebase
      final createResult = await authService.createUser(
        email: email,
        password: password,
      );

      if (createResult.success && createResult.user != null) {
        final uid = createResult.user!.uid;
        final now = DateTime.now();

        final userModel = UserModel(
          id: uid,
          email: email,
          name: name,
          role: role,
          bio: role == UserRole.student
              ? 'Computer Science Undergraduate & Open Source Enthusiast'
              : 'Senior Professor of Computer Science & Engineering',
          department: 'Computer Science & Engineering',
          createdAt: now,
          updatedAt: now,
        );
        await firestoreService.saveUserModel(userModel);

        if (role == UserRole.student) {
          final studentModel = StudentModel(
            user: userModel,
            studentId: 'STU-2024-001',
            courseId: 'course-btech-cse',
            batchId: 'batch-2024-a',
            semester: 4,
            enrollmentDate: now,
          );
          await firestoreService.saveStudentProfile(studentModel);
        } else if (role == UserRole.teacher) {
          final teacherModel = TeacherModel(
            user: userModel,
            employeeId: 'EMP-CSE-101',
            departmentId: 'dept-cse',
            subjectIds: ['sub-cs401', 'sub-cs402'],
          );
          await firestoreService.saveTeacherProfile(teacherModel);
        }

        // Seed default academic records & sample posts
        await firestoreService.seedInitialAcademicData();

        await ref.read(authStatusProvider.notifier).refreshProfile();
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(signinResult.errorMessage ?? 'Unable to connect to Firebase.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Authentication error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Logo Icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                        ),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        size: 38,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Presenza',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Academic Attendance & Activity Portal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Login Card
                    AppCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign In',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter your university credentials to continue',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 20),

                          AppTextField(
                            controller: _emailController,
                            labelText: 'Email Address',
                            hintText: 'name@presenza.edu',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          AppTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            hintText: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: 20),

                          AppButton.primary(
                            label: 'Sign In',
                            isLoading: _isLoading,
                            onPressed: _handleLogin,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Demo Roles Quick Access
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.flash_on_rounded,
                                size: 16,
                                color: isDark ? AppColors.secondaryDark : AppColors.secondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Quick Demo Sign-In',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.secondaryDark : AppColors.secondary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : () => _quickTestLogin(UserRole.student),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: const Text('Student', style: TextStyle(fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : () => _quickTestLogin(UserRole.teacher),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: const Text('Teacher', style: TextStyle(fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : () => _quickTestLogin(UserRole.admin),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: const Text('Admin', style: TextStyle(fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Create Account Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('Create Account'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
