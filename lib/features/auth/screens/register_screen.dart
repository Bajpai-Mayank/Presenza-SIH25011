import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/enums.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/data/models/app_models.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:uuid/uuid.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _idController = TextEditingController(); // Roll No or Employee ID
  final _deptController = TextEditingController(text: 'Computer Science & Engineering');

  UserRole _selectedRole = UserRole.student;
  String _selectedCourseId = 'course-btech-cse';
  String _selectedBatchId = 'batch-2024-a';
  int _selectedSemester = 1;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _idController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    final authService = ref.read(authServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final idNumber = _idController.text.trim();
    final department = _deptController.text.trim();

    try {
      // 1. Create Firebase Auth account
      final result = await authService.createUser(
        email: email,
        password: password,
      );

      if (!result.success || result.user == null) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Registration failed.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final uid = result.user!.uid;
      final now = DateTime.now();

      // 2. Create Base UserModel
      final userModel = UserModel(
        id: uid,
        email: email,
        name: name,
        role: _selectedRole,
        createdAt: now,
        updatedAt: now,
      );
      await firestoreService.saveUserModel(userModel);

      // 3. Create Role-Specific Document
      if (_selectedRole == UserRole.student) {
        final studentModel = StudentModel(
          user: userModel,
          studentId: idNumber.isNotEmpty ? idNumber : 'STU-${now.millisecondsSinceEpoch.toString().substring(7)}',
          courseId: _selectedCourseId,
          batchId: _selectedBatchId,
          semester: _selectedSemester,
          enrollmentDate: now,
        );
        await firestoreService.saveStudentProfile(studentModel);
      } else if (_selectedRole == UserRole.teacher) {
        final teacherModel = TeacherModel(
          user: userModel,
          employeeId: idNumber.isNotEmpty ? idNumber : 'FAC-${now.millisecondsSinceEpoch.toString().substring(7)}',
          departmentId: department.isNotEmpty ? department.toLowerCase().replaceAll(' ', '-') : 'dept-cse',
          subjectIds: [],
        );
        await firestoreService.saveTeacherProfile(teacherModel);
      }

      // 4. Create Initial Welcome Notification
      final notifId = const Uuid().v4();
      final welcomeNotif = NotificationModel(
        id: notifId,
        userId: uid,
        title: 'Welcome to Presenza!',
        body: 'Your ${_selectedRole.displayName} account has been created. You can now manage academic attendance and circulars.',
        type: NotificationType.system,
        isRead: false,
        createdAt: now,
      );
      await firestoreService.createNotification(welcomeNotif);

      // 5. Refresh profile state
      await ref.read(authStatusProvider.notifier).refreshProfile();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Registration error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final courses = ref.watch(coursesProvider).valueOrNull ?? [];
    final batches = ref.watch(batchesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Presenza Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Header
                      Text(
                        'Join Presenza',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create an official academic portal account',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gray400,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Form Card
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Account Type Selector
                            Text(
                              'Account Role',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<UserRole>(
                              segments: const [
                                ButtonSegment(
                                  value: UserRole.student,
                                  label: Text('Student'),
                                  icon: Icon(Icons.school, size: 16),
                                ),
                                ButtonSegment(
                                  value: UserRole.teacher,
                                  label: Text('Teacher'),
                                  icon: Icon(Icons.person_outline, size: 16),
                                ),
                                ButtonSegment(
                                  value: UserRole.admin,
                                  label: Text('Admin'),
                                  icon: Icon(Icons.security, size: 16),
                                ),
                              ],
                              selected: {_selectedRole},
                              onSelectionChanged: (set) {
                                setState(() => _selectedRole = set.first);
                              },
                            ),
                            const SizedBox(height: 20),

                            // Full Name
                            GlassTextField(
                              controller: _nameController,
                              labelText: 'Full Name',
                              prefixIcon: Icons.badge_outlined,
                              hintText: 'e.g. Mayank Bajpai',
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Please enter your full name'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Email
                            GlassTextField(
                              controller: _emailController,
                              labelText: 'Email Address',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              hintText: 'e.g. student@college.edu',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!v.contains('@') || !v.contains('.')) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Role-specific ID (Roll No or Employee ID)
                            if (_selectedRole != UserRole.admin) ...[
                              GlassTextField(
                                controller: _idController,
                                labelText: _selectedRole == UserRole.student
                                    ? 'Roll Number / Student ID'
                                    : 'Employee ID',
                                prefixIcon: Icons.numbers_outlined,
                                hintText: _selectedRole == UserRole.student
                                    ? 'e.g. CS2024001'
                                    : 'e.g. EMP-902',
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required for academic identification'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Student-specific fields (Course, Batch & Semester)
                            if (_selectedRole == UserRole.student) ...[
                              if (courses.isNotEmpty) ...[
                                DropdownButtonFormField<String>(
                                  initialValue: courses.any((c) => c.id == _selectedCourseId)
                                      ? _selectedCourseId
                                      : courses.first.id,
                                  decoration: InputDecoration(
                                    labelText: 'Course / Degree',
                                    prefixIcon: const Icon(Icons.menu_book_outlined),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: courses.map((c) {
                                    return DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedCourseId = val);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (batches.isNotEmpty) ...[
                                DropdownButtonFormField<String>(
                                  initialValue: batches.any((b) => b.id == _selectedBatchId)
                                      ? _selectedBatchId
                                      : batches.first.id,
                                  decoration: InputDecoration(
                                    labelText: 'Batch / Section',
                                    prefixIcon: const Icon(Icons.groups_outlined),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: batches.map((b) {
                                    return DropdownMenuItem(
                                      value: b.id,
                                      child: Text(b.name),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedBatchId = val);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                              DropdownButtonFormField<int>(
                                initialValue: _selectedSemester,
                                decoration: InputDecoration(
                                  labelText: 'Current Semester',
                                  prefixIcon: const Icon(Icons.timeline_outlined),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: List.generate(8, (i) => i + 1).map((sem) {
                                  return DropdownMenuItem(
                                    value: sem,
                                    child: Text('Semester $sem'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedSemester = val);
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Teacher Department
                            if (_selectedRole == UserRole.teacher) ...[
                              GlassTextField(
                                controller: _deptController,
                                labelText: 'Department',
                                prefixIcon: Icons.account_balance_outlined,
                                hintText: 'e.g. Computer Science',
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Password
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
                                if (v == null || v.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password
                            GlassTextField(
                              controller: _confirmPasswordController,
                              labelText: 'Confirm Password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword),
                              ),
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            GlassButton(
                              label: 'Create Account',
                              icon: Icons.person_add_outlined,
                              isLoading: _isLoading,
                              onPressed: _handleRegister,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Back to Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Sign In'),
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
      ),
    );
  }
}
