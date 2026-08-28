import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/constants/academic_defaults.dart';
import 'package:presenza/core/enums/enums.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/data/models/course_model.dart';
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
  int? _selectedYear;
  String? _selectedSection;
  int? _selectedSemester;

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

    if (_selectedRole == UserRole.student) {
      if (_selectedCourseId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your Course / Degree Program.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
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
        final year = _selectedYear ?? now.year;
        final section = _selectedSection ?? 'A';
        final batchId = _selectedBatchId ?? 'batch_${_selectedCourseId}_${year}_${section.toLowerCase()}';
        final semester = _selectedSemester ?? 1;

        final studentModel = StudentModel(
          user: userModel,
          studentId: idNumber.isNotEmpty ? idNumber : 'STU-${now.millisecondsSinceEpoch.toString().substring(7)}',
          courseId: _selectedCourseId!,
          batchId: batchId,
          semester: semester,
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
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Account registered successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Direct routing based on registered role
        if (_selectedRole == UserRole.student) {
          context.go('/student');
        } else if (_selectedRole == UserRole.teacher) {
          context.go('/teacher');
        } else {
          context.go('/admin');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('An error occurred during registration: $e'),
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
            const WavyHeader(
              title: 'PRESENZA',
              logo: Icon(
                Icons.person_add_alt_1_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
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
                                  return const Color(0xFF4A72FF).withValues(alpha: 0.1);
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
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: Color(0xFF4A72FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
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
          validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
        ),
        const SizedBox(height: 16),
        _buildPillTextField(
          controller: _emailController,
          hintText: 'Email Address',
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter your email';
            if (!v.contains('@') || !v.contains('.')) return 'Please enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
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
    final courses = ref.watch(allCoursesCatalogProvider);
    final selectedCourse = courses.where((c) => c.id == _selectedCourseId).firstOrNull;
    final maxSemesters = selectedCourse?.totalSemesters ?? 8;
    if (_selectedSemester != null && _selectedSemester! > maxSemesters) {
      _selectedSemester = 1;
    }

    // Default values if not yet picked
    final currentYear = _selectedYear ?? 2026;
    final currentSection = _selectedSection ?? 'D';
    final currentSemester = _selectedSemester ?? 1;

    if (_selectedRole == UserRole.student) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPillTextField(
            controller: _idController,
            hintText: 'Roll Number / Student ID (Optional)',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          
          // ── Course Selection ──────────────────────────────────────────
          Text(
            'Academic Program / Course *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildCoursePickerField(isDark, courses, selectedCourse),
          const SizedBox(height: 16),

          // ── Year & Section Selectors ──────────────────────────────────
          Row(
            children: [
              // Academic Year
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admission Year *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildYearPickerTile(isDark, currentYear),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Section *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSectionPickerTile(isDark, currentSection),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Semester Selector ─────────────────────────────────────────
          Text(
            'Current Semester * (1 to $maxSemesters)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: maxSemesters,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final sem = index + 1;
                final isSelected = currentSemester == sem;
                return InkWell(
                  onTap: () {
                    setState(() => _selectedSemester = sem);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4A72FF)
                          : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4A72FF)
                            : (isDark ? Colors.white12 : Colors.black12),
                      ),
                    ),
                    child: Text(
                      'Sem $sem',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                );
              },
            ),
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
            hintText: 'Department (e.g. Computer Science)',
            isDark: isDark,
            validator: (v) => v == null || v.trim().isEmpty ? 'Department is required' : null,
          ),
        ],
      );
    }
  }

  Widget _buildYearPickerTile(bool isDark, int currentYear) {
    return InkWell(
      onTap: () => _showYearPickerSheet(context, isDark),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF4A72FF).withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF4A72FF)),
                const SizedBox(width: 8),
                Text(
                  _selectedYear != null ? '$_selectedYear' : '$currentYear',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: isDark ? Colors.white70 : Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionPickerTile(bool isDark, String currentSection) {
    return InkWell(
      onTap: () => _showSectionPickerSheet(context, isDark),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF4A72FF).withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.group_outlined, size: 16, color: Color(0xFF4A72FF)),
                const SizedBox(width: 8),
                Text(
                  'Sec ${_selectedSection ?? currentSection}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: isDark ? Colors.white70 : Colors.black54),
          ],
        ),
      ),
    );
  }

  void _showYearPickerSheet(BuildContext context, bool isDark) {
    final years = AcademicDefaults.defaultYears;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Admission / Batch Year',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                itemCount: years.length,
                itemBuilder: (context, index) {
                  final y = years[index];
                  final isSelected = (_selectedYear ?? 2026) == y;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedYear = y;
                        final section = _selectedSection ?? 'D';
                        _selectedBatchId = 'batch_${_selectedCourseId ?? 'bsms'}_${y}_${section.toLowerCase()}';
                      });
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4A72FF)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF4A72FF) : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '$y',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSectionPickerSheet(BuildContext context, bool isDark) {
    final sections = AcademicDefaults.defaultSections;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Section',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.8,
                ),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final s = sections[index];
                  final isSelected = (_selectedSection ?? 'D') == s;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedSection = s;
                        final year = _selectedYear ?? 2026;
                        _selectedBatchId = 'batch_${_selectedCourseId ?? 'bsms'}_${year}_${s.toLowerCase()}';
                      });
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4A72FF)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF4A72FF) : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        'Sec $s',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoursePickerField(bool isDark, List<CourseModel> courses, CourseModel? selectedCourse) {
    final hasSelection = selectedCourse != null;
    
    return InkWell(
      onTap: () => _showCourseSelectionSheet(context, isDark, courses),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: hasSelection ? const Color(0xFF4A72FF) : (isDark ? Colors.white12 : Colors.black12),
            width: hasSelection ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.school_rounded,
              size: 20,
              color: hasSelection ? const Color(0xFF4A72FF) : (isDark ? Colors.white54 : Colors.black38),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedCourse?.name ?? 'Select Course / Degree Program',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasSelection ? FontWeight.w600 : FontWeight.normal,
                  color: hasSelection
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  void _showCourseSelectionSheet(BuildContext context, bool isDark, List<CourseModel> courses) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        String selectedCategory = 'All';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredCourses = courses.where((c) {
              final q = searchQuery.toLowerCase();
              final matchesQuery = c.name.toLowerCase().contains(q) ||
                  c.code.toLowerCase().contains(q) ||
                  c.departmentId.toLowerCase().contains(q);

              return matchesQuery && AcademicDefaults.matchesCategory(c, selectedCategory);
            }).toList();

            final categories = AcademicDefaults.courseCategories;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Course / Program',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: isDark ? Colors.white70 : Colors.black54,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search Bar
                  TextField(
                    autofocus: false,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search course (e.g. BS-MS, CSE, MBA, Law)...',
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : Colors.black38),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setSheetState(() => searchQuery = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  // Category Filter Chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = selectedCategory == cat;
                        return InkWell(
                          onTap: () => setSheetState(() => selectedCategory = cat),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF4A72FF)
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        if (filteredCourses.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No courses match "$searchQuery"',
                                style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                              ),
                            ),
                          )
                        else
                          ...filteredCourses.map((course) {
                            final isSelected = course.id == _selectedCourseId;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCourseId = course.id;
                                    _selectedSemester = 1;
                                    final year = _selectedYear ?? 2026;
                                    final section = _selectedSection ?? 'D';
                                    _selectedBatchId = 'batch_${course.id}_${year}_${section.toLowerCase()}';
                                  });
                                  Navigator.pop(ctx);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF4A72FF).withValues(alpha: 0.12)
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF4A72FF) : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4A72FF).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          course.code,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4A72FF),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              course.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${course.totalSemesters} Semesters',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.white54 : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF4A72FF),
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 12),
                        // Custom Course Option
                        InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _showCustomCourseDialog(context, isDark);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A72FF).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF4A72FF).withValues(alpha: 0.4),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, color: Color(0xFF4A72FF), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Other Degree / Custom Program',
                                  style: TextStyle(
                                    color: Color(0xFF4A72FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCustomCourseDialog(BuildContext context, bool isDark) {
    final customNameController = TextEditingController();
    final customCodeController = TextEditingController();
    int customSemesters = 8;

    showDialog(
      context: context,
      builder: (dCtx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Enter Custom Degree / Course',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: customNameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Program Name (e.g. BS-MS Physics, B.Arch)',
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: customCodeController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Degree Code (e.g. BSMS-PHY, BARCH)',
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Semesters: $customSemesters',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: customSemesters > 1 ? () => setDlgState(() => customSemesters--) : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: customSemesters < 12 ? () => setDlgState(() => customSemesters++) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = customNameController.text.trim();
                    final code = customCodeController.text.trim();
                    if (name.isNotEmpty) {
                      final generatedId = 'course-custom-${DateTime.now().millisecondsSinceEpoch}';
                      final newCourse = CourseModel(
                        id: generatedId,
                        name: name,
                        code: code.isNotEmpty ? code.toUpperCase() : 'CUSTOM',
                        departmentId: 'dept-general',
                        totalSemesters: customSemesters,
                      );
                      setState(() {
                        _selectedCourseId = newCourse.id;
                        _selectedSemester = 1;
                        final year = _selectedYear ?? 2026;
                        final section = _selectedSection ?? 'D';
                        _selectedBatchId = 'batch_${newCourse.id}_${year}_${section.toLowerCase()}';
                      });
                      Navigator.pop(dCtx);
                    }
                  },
                  child: const Text('Select Course'),
                ),
              ],
            );
          },
        );
      },
    );
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
}




