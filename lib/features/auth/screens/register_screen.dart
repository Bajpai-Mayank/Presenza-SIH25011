import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presenza/config/theme/app_colors.dart';
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
  static const List<CourseModel> _defaultCourses = [
    // Engineering & Technology
    CourseModel(
      id: 'course-btech-cse',
      name: 'B.Tech Computer Science & Engineering (CSE)',
      code: 'BTECH-CSE',
      departmentId: 'dept-cse',
      totalSemesters: 8,
    ),
    CourseModel(
      id: 'course-btech-aids',
      name: 'B.Tech Artificial Intelligence & Data Science (AI/DS)',
      code: 'BTECH-AIDS',
      departmentId: 'dept-cse',
      totalSemesters: 8,
    ),
    CourseModel(
      id: 'course-btech-it',
      name: 'B.Tech Information Technology (IT)',
      code: 'BTECH-IT',
      departmentId: 'dept-it',
      totalSemesters: 8,
    ),
    CourseModel(
      id: 'course-btech-ece',
      name: 'B.Tech Electronics & Communication (ECE)',
      code: 'BTECH-ECE',
      departmentId: 'dept-ece',
      totalSemesters: 8,
    ),
    CourseModel(
      id: 'course-btech-ee',
      name: 'B.Tech Electrical Engineering (EE)',
      code: 'BTECH-EE',
      departmentId: 'dept-ee',
      totalSemesters: 8,
    ),
    CourseModel(
      id: 'course-btech-me',
      name: 'B.Tech Mechanical Engineering (ME)',
      code: 'BTECH-ME',
      departmentId: 'dept-me',
      totalSemesters: 8,
    ),
    CourseModel(
      id: 'course-btech-ce',
      name: 'B.Tech Civil Engineering (CE)',
      code: 'BTECH-CE',
      departmentId: 'dept-ce',
      totalSemesters: 8,
    ),
    CourseModel(
      id: 'course-btech-bt',
      name: 'B.Tech Biotechnology (BT)',
      code: 'BTECH-BT',
      departmentId: 'dept-bt',
      totalSemesters: 8,
    ),
    CourseModel(
      id: 'course-mtech-cse',
      name: 'M.Tech Computer Science & Engineering',
      code: 'MTECH-CSE',
      departmentId: 'dept-cse',
      totalSemesters: 4,
    ),
    CourseModel(
      id: 'course-mtech-dsai',
      name: 'M.Tech Data Science & AI',
      code: 'MTECH-DSAI',
      departmentId: 'dept-cse',
      totalSemesters: 4,
    ),
    CourseModel(
      id: 'course-mtech-vlsi',
      name: 'M.Tech VLSI & Embedded Systems',
      code: 'MTECH-VLSI',
      departmentId: 'dept-ece',
      totalSemesters: 4,
    ),

    // Computer Applications
    CourseModel(
      id: 'course-bca',
      name: 'Bachelor of Computer Applications (BCA)',
      code: 'BCA',
      departmentId: 'dept-ca',
      totalSemesters: 6,
    ),
    CourseModel(
      id: 'course-mca',
      name: 'Master of Computer Applications (MCA)',
      code: 'MCA',
      departmentId: 'dept-ca',
      totalSemesters: 4,
    ),

    // Management & Business
    CourseModel(
      id: 'course-bba',
      name: 'Bachelor of Business Administration (BBA)',
      code: 'BBA',
      departmentId: 'dept-mgmt',
      totalSemesters: 6,
    ),
    CourseModel(
      id: 'course-mba',
      name: 'Master of Business Administration (MBA)',
      code: 'MBA',
      departmentId: 'dept-mgmt',
      totalSemesters: 4,
    ),
    CourseModel(
      id: 'course-bcom',
      name: 'Bachelor of Commerce (B.Com Hons)',
      code: 'BCOM',
      departmentId: 'dept-commerce',
      totalSemesters: 6,
    ),
    CourseModel(
      id: 'course-mcom',
      name: 'Master of Commerce (M.Com)',
      code: 'MCOM',
      departmentId: 'dept-commerce',
      totalSemesters: 4,
    ),

    // Law & Legal Studies
    CourseModel(
      id: 'course-bba-llb',
      name: 'BBA LL.B. (Integrated Honours)',
      code: 'BBA-LLB',
      departmentId: 'dept-law',
      totalSemesters: 10,
    ),
    CourseModel(
      id: 'course-ba-llb',
      name: 'BA LL.B. (Integrated Honours)',
      code: 'BA-LLB',
      departmentId: 'dept-law',
      totalSemesters: 10,
    ),
    CourseModel(
      id: 'course-llb',
      name: 'Bachelor of Laws (LL.B.)',
      code: 'LLB',
      departmentId: 'dept-law',
      totalSemesters: 6,
    ),
    CourseModel(
      id: 'course-llm',
      name: 'Master of Laws (LL.M.)',
      code: 'LLM',
      departmentId: 'dept-law',
      totalSemesters: 4,
    ),

    // Sciences & Integrated Dual Degrees
    CourseModel(
      id: 'course-bs-ms',
      name: 'BS-MS Dual Degree (Integrated Sciences)',
      code: 'BS-MS',
      departmentId: 'dept-science',
      totalSemesters: 10,
    ),
    CourseModel(
      id: 'course-bsc-cs',
      name: 'B.Sc Computer Science / Data Science',
      code: 'BSC-CS',
      departmentId: 'dept-science',
      totalSemesters: 6,
    ),
    CourseModel(
      id: 'course-bsc-pcm',
      name: 'B.Sc Physical Sciences (PCM)',
      code: 'BSC-PCM',
      departmentId: 'dept-science',
      totalSemesters: 6,
    ),
    CourseModel(
      id: 'course-msc-ds',
      name: 'M.Sc Data Science & Analytics',
      code: 'MSC-DS',
      departmentId: 'dept-science',
      totalSemesters: 4,
    ),

    // Pharmacy & Health Sciences
    CourseModel(
      id: 'course-bpharm',
      name: 'Bachelor of Pharmacy (B.Pharm)',
      code: 'BPHARM',
      departmentId: 'dept-pharmacy',
      totalSemesters: 8,
    ),
    CourseModel(
      id: 'course-mpharm',
      name: 'Master of Pharmacy (M.Pharm)',
      code: 'MPHARM',
      departmentId: 'dept-pharmacy',
      totalSemesters: 4,
    ),

    // Design & Architecture
    CourseModel(
      id: 'course-bdes',
      name: 'Bachelor of Design (B.Des)',
      code: 'BDES',
      departmentId: 'dept-design',
      totalSemesters: 8,
    ),
    CourseModel(
      id: 'course-mdes',
      name: 'Master of Design (M.Des)',
      code: 'MDES',
      departmentId: 'dept-design',
      totalSemesters: 4,
    ),

    // Doctoral Research
    CourseModel(
      id: 'course-phd',
      name: 'Ph.D. / Doctoral Research',
      code: 'PHD',
      departmentId: 'dept-research',
      totalSemesters: 6,
    ),
  ];

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: Color(0xFF4A72FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
    final firestoreCourses = ref.watch(coursesProvider).valueOrNull ?? [];
    final List<CourseModel> courses = (firestoreCourses.isNotEmpty ? firestoreCourses : _defaultCourses)
        .whereType<CourseModel>()
        .toList();
    final batches = ref.watch(batchesProvider).valueOrNull ?? [];

    // Filter batches by selected course
    final availableBatches = batches.where((b) => b.courseId == _selectedCourseId).toList();
    
    // Academic years (2021 to 2027)
    final defaultYears = [2021, 2022, 2023, 2024, 2025, 2026, 2027];
    final batchYears = availableBatches.map((b) => b.year).toSet().toList();
    final availableYears = (batchYears.isNotEmpty ? batchYears : defaultYears)..sort();
    
    // Sections
    final defaultSections = ['A', 'B', 'C', 'D'];
    final batchSections = availableBatches
        .where((b) => b.year == _selectedYear)
        .map((b) => b.section)
        .toSet()
        .toList();
    final availableSections = (batchSections.isNotEmpty ? batchSections : defaultSections)..sort();

    // Get max semesters
    final selectedCourse = courses.where((c) => c.id == _selectedCourseId).firstOrNull;
    final maxSemesters = selectedCourse?.totalSemesters ?? 8;
    if (_selectedSemester != null && _selectedSemester! > maxSemesters) {
      _selectedSemester = 1;
    }

    if (_selectedRole == UserRole.student) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPillTextField(
            controller: _idController,
            hintText: 'Roll Number / Student ID',
            isDark: isDark,
            validator: (v) => v == null || v.trim().isEmpty ? 'Student ID is required' : null,
          ),
          const SizedBox(height: 16),
          _buildCoursePickerField(isDark, courses, selectedCourse),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildPillDropdown<int>(
                  value: _selectedYear,
                  hintText: 'Year',
                  isDark: isDark,
                  items: availableYears.map((y) {
                    return DropdownMenuItem<int>(
                      value: y,
                      child: Text(
                        y.toString(),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedYear = val;
                        // Auto match or update batch
                        final match = availableBatches.where(
                          (b) => b.year == val && b.section == (_selectedSection ?? 'A'),
                        ).firstOrNull;
                        _selectedBatchId = match?.id ?? 'batch_${_selectedCourseId ?? 'cse'}_${val}_${(_selectedSection ?? 'a').toLowerCase()}';
                      });
                    }
                  },
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildPillDropdown<String>(
                  value: _selectedSection,
                  hintText: 'Section',
                  isDark: isDark,
                  items: availableSections.map((s) {
                    return DropdownMenuItem<String>(
                      value: s,
                      child: Text(
                        'Sec $s',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedSection = val;
                        final year = _selectedYear ?? DateTime.now().year;
                        final match = availableBatches.where(
                          (b) => b.year == year && b.section == val,
                        ).firstOrNull;
                        _selectedBatchId = match?.id ?? 'batch_${_selectedCourseId ?? 'cse'}_${year}_${val.toLowerCase()}';
                      });
                    }
                  },
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildPillDropdown<int>(
                  value: _selectedSemester,
                  hintText: 'Sem',
                  isDark: isDark,
                  items: List.generate(maxSemesters, (i) => i + 1).map((sem) {
                    return DropdownMenuItem<int>(
                      value: sem,
                      child: Text(
                        'Sem $sem',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSemester = val);
                  },
                  validator: (v) => v == null ? 'Required' : null,
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
            hintText: 'Department (e.g. Computer Science)',
            isDark: isDark,
            validator: (v) => v == null || v.trim().isEmpty ? 'Department is required' : null,
          ),
        ],
      );
    }
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
            color: hasSelection ? const Color(0xFF4A72FF) : Colors.transparent,
            width: hasSelection ? 1.5 : 0,
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
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredCourses = courses.where((c) {
              final q = searchQuery.toLowerCase();
              return c.name.toLowerCase().contains(q) ||
                  c.code.toLowerCase().contains(q) ||
                  c.departmentId.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
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
                      hintText: 'Search course (e.g. CSE, B.Tech, MBA)...',
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
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredCourses.isEmpty
                        ? Center(
                            child: Text(
                              'No matching courses found',
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredCourses.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final course = filteredCourses[idx];
                              final isSelected = course.id == _selectedCourseId;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCourseId = course.id;
                                    _selectedSemester = 1;
                                    final year = _selectedYear ?? DateTime.now().year;
                                    final section = _selectedSection ?? 'A';
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
                              );
                            },
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
    final validValue = items.any((i) => i.value == value) ? value : null;

    return DropdownButtonFormField<T>(
      key: ValueKey(validValue),
      initialValue: validValue,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      menuMaxHeight: 320,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 13,
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF5F6F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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



