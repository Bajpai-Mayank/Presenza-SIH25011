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
  final _deptController = TextEditingController();

  UserRole _selectedRole = UserRole.student;
  String? _selectedCourseId;
  String? _selectedBatchId;
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

    if (_selectedRole == UserRole.student && (_selectedCourseId == null || _selectedBatchId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a course and batch.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

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
        department: _selectedRole == UserRole.student ? 'Student' : department,
        bio: _selectedRole == UserRole.student
            ? 'Undergraduate Scholar'
            : 'Academic Faculty Member',
        createdAt: now,
        updatedAt: now,
      );

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

      if (_selectedRole == UserRole.student) {
        final studentModel = StudentModel(
          user: userModel,
          studentId: idNumber.isNotEmpty ? idNumber : 'STU-${now.millisecondsSinceEpoch.toString().substring(7)}',
          courseId: _selectedCourseId!,
          batchId: _selectedBatchId!,
          semester: _selectedSemester,
          enrollmentDate: now,
        );
        await firestoreService.registerStudentAtomically(
          user: userModel,
          student: studentModel,
          notification: welcomeNotif,
        );
      } else if (_selectedRole == UserRole.teacher) {
        final teacherModel = TeacherModel(
          user: userModel,
          employeeId: idNumber.isNotEmpty ? idNumber : 'FAC-${now.millisecondsSinceEpoch.toString().substring(7)}',
          departmentId: department.isNotEmpty ? department.toLowerCase().replaceAll(' ', '-') : 'dept-cse',
          subjectIds: const [],
        );
        await firestoreService.registerTeacherAtomically(
          user: userModel,
          teacher: teacherModel,
          notification: welcomeNotif,
        );
      }

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

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            WavyHeader(
              title: 'PRESENZA',
              logo: Icon(
                Icons.school_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: 'Create ',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                            children: [
                              TextSpan(
                                text: 'Account !',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        SegmentedButton<UserRole>(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) {
                                  return const Color(0xFF4A72FF).withOpacity(0.1);
                                }
                                return Colors.transparent;
                              },
                            ),
                          ),
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
                          ],
                          selected: {_selectedRole},
                          onSelectionChanged: (set) {
                            setState(() => _selectedRole = set.first);
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildBasicInfoFields(isDark),
                        const SizedBox(height: 16),
                        _buildRoleSpecificFields(isDark),
                        const SizedBox(height: 16),
                        _buildPasswordFields(isDark),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF4A72FF)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A72FF)),
                                    ),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      color: Color(0xFF4A72FF),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black45,
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.pop(),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Color(0xFF4A72FF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoFields(bool isDark) {
    return Column(
      children: [
        _buildPillTextField(
          controller: _nameController,
          hintText: 'Full Name',
          isDark: isDark,
          validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
        ),
        const SizedBox(height: 16),
        _buildPillTextField(
          controller: _emailController,
          hintText: 'University Email',
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@') || !v.contains('.')) return 'Please enter a valid email';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordFields(bool isDark) {
    return Column(
      children: [
        _buildPillTextField(
          controller: _passwordController,
          hintText: 'Password',
          isDark: isDark,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
        ),
        const SizedBox(height: 16),
        _buildPillTextField(
          controller: _confirmPasswordController,
          hintText: 'Confirm Password',
          isDark: isDark,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
        ),
      ],
    );
  }

  Widget _buildRoleSpecificFields(bool isDark) {
    final courses = ref.watch(coursesProvider).valueOrNull ?? [];
    final batches = ref.watch(batchesProvider).valueOrNull ?? [];

    if (courses.isNotEmpty && _selectedCourseId == null) {
      _selectedCourseId = courses.first.id;
    }
    
    // Filter batches by selected course
    final availableBatches = batches.where((b) => b.courseId == _selectedCourseId).toList();
    if (availableBatches.isNotEmpty && (_selectedBatchId == null || !availableBatches.any((b) => b.id == _selectedBatchId))) {
      _selectedBatchId = availableBatches.first.id;
    }

    // Get max semesters
    final selectedCourse = courses.where((c) => c.id == _selectedCourseId).firstOrNull;
    final maxSemesters = selectedCourse?.totalSemesters ?? 8;
    if (_selectedSemester > maxSemesters) {
      _selectedSemester = 1;
    }

    if (_selectedRole == UserRole.student) {
      return Column(
        children: [
          _buildPillTextField(
            controller: _idController,
            hintText: 'Roll Number / Student ID',
            isDark: isDark,
            validator: (v) => v == null || v.trim().isEmpty ? 'Student ID is required' : null,
          ),
          const SizedBox(height: 16),
          _buildPillDropdown<String>(
            value: _selectedCourseId,
            hintText: 'Course / Degree Program',
            isDark: isDark,
            items: courses.map((c) {
              return DropdownMenuItem(
                value: c.id,
                child: Text(c.name, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedCourseId = val;
                  _selectedBatchId = null; // reset batch when course changes
                  _selectedSemester = 1;
                });
              }
            },
            validator: (v) => v == null ? 'Course is required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildPillDropdown<String>(
                  value: _selectedBatchId,
                  hintText: 'Class Section',
                  isDark: isDark,
                  items: availableBatches.map((b) {
                    return DropdownMenuItem(
                      value: b.id,
                      child: Text(b.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBatchId = val);
                  },
                  validator: (v) => v == null ? 'Batch is required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildPillDropdown<int>(
                  value: _selectedSemester,
                  hintText: 'Sem',
                  isDark: isDark,
                  items: List.generate(maxSemesters, (i) => i + 1).map((sem) {
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
        ],
      );
    } else {
      return Column(
        children: [
          _buildPillTextField(
            controller: _idController,
            hintText: 'Employee ID',
            isDark: isDark,
            validator: (v) => v == null || v.trim().isEmpty ? 'Employee ID is required' : null,
          ),
          const SizedBox(height: 16),
          _buildPillTextField(
            controller: _deptController,
            hintText: 'Department',
            isDark: isDark,
            validator: (v) => v == null || v.trim().isEmpty ? 'Department is required' : null,
          ),
        ],
      );
    }
  }

  Widget _buildPillTextField({
    required TextEditingController controller,
    required String hintText,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF5F6F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF4A72FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
    );
  }

  Widget _buildPillDropdown<T>({
    required T? value,
    required String hintText,
    required bool isDark,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF5F6F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF4A72FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
    );
  }
}

