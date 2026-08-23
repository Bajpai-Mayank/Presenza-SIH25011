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
  final _idController = TextEditingController();
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

      final userModel = UserModel(
        id: uid,
        email: email,
        name: name,
        role: _selectedRole,
        department: department,
        bio: _selectedRole == UserRole.student
            ? 'Undergraduate Scholar'
            : 'Academic Faculty Member',
        createdAt: now,
        updatedAt: now,
      );
      await firestoreService.saveUserModel(userModel);

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
          subjectIds: const [],
        );
        await firestoreService.saveTeacherProfile(teacherModel);
      }

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
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      'Join Presenza',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Register for the academic attendance & activity portal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    AppCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Role',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 10),
                          SegmentedButton<UserRole>(
                            segments: const [
                              ButtonSegment(
                                value: UserRole.student,
                                label: Text('Student'),
                                icon: Icon(Icons.school_outlined, size: 16),
                              ),
                              ButtonSegment(
                                value: UserRole.teacher,
                                label: Text('Faculty'),
                                icon: Icon(Icons.person_outline, size: 16),
                              ),
                              ButtonSegment(
                                value: UserRole.admin,
                                label: Text('Admin'),
                                icon: Icon(Icons.admin_panel_settings_outlined, size: 16),
                              ),
                            ],
                            selected: {_selectedRole},
                            onSelectionChanged: (set) {
                              setState(() => _selectedRole = set.first);
                            },
                          ),
                          const SizedBox(height: 20),

                          AppTextField(
                            controller: _nameController,
                            labelText: 'Full Name',
                            prefixIcon: Icons.badge_outlined,
                            hintText: 'e.g. Mayank Bajpai',
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          AppTextField(
                            controller: _emailController,
                            labelText: 'University Email',
                            prefixIcon: Icons.email_outlined,
                            hintText: 'name@presenza.edu',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!v.contains('@') || !v.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          if (_selectedRole == UserRole.student) ...[
                            AppTextField(
                              controller: _idController,
                              labelText: 'Roll Number / Student ID',
                              prefixIcon: Icons.fingerprint_rounded,
                              hintText: 'e.g. 21BCSE042',
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Student ID is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              initialValue: courses.any((c) => c.id == _selectedCourseId)
                                  ? _selectedCourseId
                                  : (courses.isNotEmpty ? courses.first.id : _selectedCourseId),
                              decoration: const InputDecoration(
                                labelText: 'Course / Degree Program',
                                prefixIcon: Icon(Icons.book_outlined, size: 20),
                              ),
                              items: courses.isNotEmpty
                                  ? courses.map((c) {
                                      return DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList()
                                  : const [
                                      DropdownMenuItem(
                                        value: 'course-btech-cse',
                                        child: Text('B.Tech Computer Science & Engineering'),
                                      ),
                                    ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCourseId = val);
                              },
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: batches.any((b) => b.id == _selectedBatchId)
                                        ? _selectedBatchId
                                        : (batches.isNotEmpty ? batches.first.id : _selectedBatchId),
                                    decoration: const InputDecoration(
                                      labelText: 'Class Section',
                                      prefixIcon: Icon(Icons.group_outlined, size: 20),
                                    ),
                                    items: batches.isNotEmpty
                                        ? batches.map((b) {
                                            return DropdownMenuItem(
                                              value: b.id,
                                              child: Text(b.name, overflow: TextOverflow.ellipsis),
                                            );
                                          }).toList()
                                        : const [
                                            DropdownMenuItem(
                                              value: 'batch-2024-a',
                                              child: Text('Batch 2024 - Sec A'),
                                            ),
                                          ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedBatchId = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<int>(
                                    initialValue: _selectedSemester,
                                    decoration: const InputDecoration(
                                      labelText: 'Semester',
                                    ),
                                    items: List.generate(8, (i) => i + 1).map((sem) {
                                      return DropdownMenuItem(
                                        value: sem,
                                        child: Text('Sem $sem'),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedSemester = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ] else if (_selectedRole == UserRole.teacher) ...[
                            AppTextField(
                              controller: _idController,
                              labelText: 'Employee ID',
                              prefixIcon: Icons.work_outline_rounded,
                              hintText: 'e.g. EMP-CSE-101',
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Employee ID is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _deptController,
                              labelText: 'Department',
                              prefixIcon: Icons.apartment_rounded,
                              hintText: 'e.g. Computer Science',
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Department is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          AppTextField(
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

                          AppTextField(
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
                              onPressed: () => setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            validator: (v) {
                              if (v != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          AppButton.primary(
                            label: 'Create Account',
                            isLoading: _isLoading,
                            onPressed: _handleRegister,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
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
    );
  }
}
