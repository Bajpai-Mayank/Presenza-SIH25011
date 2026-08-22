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

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
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

  /// 1-Click Fast Access: Signs in or automatically provisions the test account in Firebase.
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

        // Seed standard courses, batches, subjects, and policies if empty
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.backgroundDark,
                    const Color(0xFF0F0F0F),
                    const Color(0xFF111111),
                  ]
                : [
                    AppColors.backgroundLight,
                    const Color(0xFFEAEAEC),
                    AppColors.backgroundLight,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? AppColors.white.withAlpha(13)
                                  : AppColors.black.withAlpha(8),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.white.withAlpha(25)
                                    : AppColors.black.withAlpha(15),
                              ),
                            ),
                            child: Icon(
                              Icons.school_rounded,
                              size: 40,
                              color: isDark ? AppColors.white : AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Presenza',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Academic Attendance & Activity Portal',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? AppColors.gray400
                                      : AppColors.gray600,
                                ),
                          ),
                          const SizedBox(height: 32),

                          // Login Card
                          GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                GlassTextField(
                                  controller: _emailController,
                                  labelText: 'Email Address',
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
                                GlassTextField(
                                  controller: _passwordController,
                                  labelText: 'Password',
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
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () =>
                                        context.push('/forgot-password'),
                                    child: const Text('Forgot password?'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GlassButton(
                                  label: 'Sign In',
                                  isLoading: _isLoading,
                                  onPressed: _handleLogin,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              TextButton(
                                onPressed: () => context.push('/register'),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 1-Click Evaluation / Test Access
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.white.withAlpha(10)
                                  : AppColors.black.withAlpha(8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.white.withAlpha(20)
                                    : AppColors.black.withAlpha(15),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Quick Evaluation Access',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppColors.gray400,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _QuickAccessChip(
                                      label: 'Student',
                                      icon: Icons.school,
                                      onTap: _isLoading ? null : () => _quickTestLogin(UserRole.student),
                                    ),
                                    _QuickAccessChip(
                                      label: 'Teacher',
                                      icon: Icons.person_outline,
                                      onTap: _isLoading ? null : () => _quickTestLogin(UserRole.teacher),
                                    ),
                                    _QuickAccessChip(
                                      label: 'Admin',
                                      icon: Icons.security,
                                      onTap: _isLoading ? null : () => _quickTestLogin(UserRole.admin),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAccessChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _QuickAccessChip({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.white.withAlpha(15)
              : AppColors.black.withAlpha(10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
