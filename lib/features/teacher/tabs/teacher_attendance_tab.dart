import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/constants/academic_defaults.dart';
import 'package:presenza/core/enums/enums.dart';
import 'package:presenza/core/security/attendance_security_controller.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/data/models/course_model.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/data/services/location_service.dart';
import 'package:presenza/core/utils/csv_export_service.dart';

class TeacherAttendanceTab extends ConsumerStatefulWidget {
  const TeacherAttendanceTab({super.key});

  @override
  ConsumerState<TeacherAttendanceTab> createState() => _TeacherAttendanceTabState();
}

class _TeacherAttendanceTabState extends ConsumerState<TeacherAttendanceTab> {
  final _roomController = TextEditingController(text: 'Room 402');
  final _customSubjectNameController = TextEditingController();
  final _customSubjectCodeController = TextEditingController();

  String? _selectedCourseId;
  int _selectedYear = 2024;
  String _selectedSection = 'A';
  String? _selectedSubjectId;
  bool _isCustomSubject = false;

  int _qrExpirySeconds = 600; // default 10 mins (600s)
  bool _isCustomExpiry = false;
  String _customExpiryUnit = 'minutes'; // 'seconds' or 'minutes'
  final _customExpiryController = TextEditingController(text: '10');
  bool _locationRequired = false;
  final FaceVerificationMode _faceMode = FaceVerificationMode.disabled;
  bool _isCreatingSession = false;

  @override
  void initState() {
    super.initState();
    ref.read(attendanceSecurityProvider.notifier).enableSecureMode();
  }

  @override
  void dispose() {
    try {
      ref.read(attendanceSecurityProvider.notifier).disableSecureMode();
    } catch (_) {}
    _roomController.dispose();
    _customSubjectNameController.dispose();
    _customSubjectCodeController.dispose();
    _customExpiryController.dispose();
    super.dispose();
  }

  Widget _buildExpiryChip({required String label, required int seconds}) {
    final isSelected = !_isCustomExpiry && _qrExpirySeconds == seconds;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _isCustomExpiry = false;
            _qrExpirySeconds = seconds;
          });
        }
      },
    );
  }

  CourseModel _resolveSelectedCourse(List<CourseModel> courses) {
    if (_selectedCourseId != null) {
      final match = courses.where((c) => c.id == _selectedCourseId).firstOrNull;
      if (match != null) return match;
    }
    return courses.isNotEmpty ? courses.first : AcademicDefaults.defaultCourses.first;
  }

  String _resolveEffectiveBatchId(
      CourseModel course, List<BatchModel> batches) {
    // 1. Try to find a matching Firestore batch record
    final match = batches.where((b) {
      return b.courseId == course.id &&
          b.year == _selectedYear &&
          b.section.trim().toUpperCase() == _selectedSection.trim().toUpperCase();
    }).firstOrNull;

    if (match != null) {
      return match.id;
    }

    // 2. Synthesize structured batch ID
    return AcademicDefaults.formatBatchId(
        course.id, _selectedYear, _selectedSection);
  }

  Future<void> _startAttendanceSession(
      CourseModel course, String effectiveBatchId) async {
    final teacher = ref.read(teacherProfileProvider);
    if (teacher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faculty profile not loaded. Please log in again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String subjectId;
    String subjectName;
    String subjectCode;

    if (_isCustomSubject) {
      if (_customSubjectNameController.text.trim().isEmpty ||
          _customSubjectCodeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter custom subject name and code'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      subjectId = 'sub-custom-${const Uuid().v4().substring(0, 8)}';
      subjectName = _customSubjectNameController.text.trim();
      subjectCode = _customSubjectCodeController.text.trim().toUpperCase();

      final newSubject = SubjectModel(
        id: subjectId,
        name: subjectName,
        code: subjectCode,
        courseId: course.id,
        semester: 4,
        credits: 3,
        teacherId: teacher.user.id,
      );
      await ref.read(firestoreServiceProvider).addTeacherSubject(
            teacherUid: teacher.user.id,
            subject: newSubject,
          );
    } else {
      final subjects = ref.read(teacherSubjectsProvider);
      final match = subjects.where((s) => s.id == _selectedSubjectId).firstOrNull;
      if (match != null) {
        subjectId = match.id;
        subjectName = match.name;
        subjectCode = match.code;
      } else if (subjects.isNotEmpty) {
        subjectId = subjects.first.id;
        subjectName = subjects.first.name;
        subjectCode = subjects.first.code;
      } else {
        subjectId = 'sub-${course.code.toLowerCase()}-core';
        subjectName = '${course.name} Core Seminar';
        subjectCode = course.code;
      }
    }

    int totalExpirySeconds = _qrExpirySeconds;
    if (_isCustomExpiry) {
      final parsed = int.tryParse(_customExpiryController.text.trim());
      if (parsed == null || parsed <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid custom expiration time.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      totalExpirySeconds = _customExpiryUnit == 'seconds' ? parsed : parsed * 60;
    }

    setState(() => _isCreatingSession = true);

    double? currentLat;
    double? currentLng;
    if (_locationRequired) {
      final locService = LocationService();
      final position = await locService.getCurrentPosition();
      if (position != null) {
        currentLat = position.latitude;
        currentLng = position.longitude;
      } else {
        if (mounted) {
          setState(() => _isCreatingSession = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to acquire location. Please enable GPS and try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    final now = DateTime.now();
    final sessionId = const Uuid().v4();
    final token = 'PRE-$sessionId';

    final session = AttendanceSessionModel(
      id: sessionId,
      subjectId: subjectId,
      subjectName: subjectName,
      subjectCode: subjectCode,
      teacherId: teacher.user.id,
      teacherName: teacher.user.name,
      courseId: course.id,
      batchId: effectiveBatchId,
      room: _roomController.text.trim().isNotEmpty
          ? _roomController.text.trim()
          : 'Room 402',
      date: now,
      startTime: now,
      endTime: now.add(Duration(seconds: totalExpirySeconds)),
      qrToken: token,
      isActive: true,
      locationRequired: _locationRequired,
      faceVerificationMode: _faceMode,
      campusLat: _locationRequired ? currentLat : null,
      campusLng: _locationRequired ? currentLng : null,
      allowedRadiusMeters: _locationRequired ? 100.0 : null,
      createdAt: now,
    );

    await ref.read(firestoreServiceProvider).createAttendanceSession(session);
    ref.read(activeAttendanceSessionProvider.notifier).startSession(session);

    if (mounted) {
      setState(() => _isCreatingSession = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance session started for $subjectName!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _closeActiveSession(String sessionId) async {
    await ref.read(firestoreServiceProvider).closeAttendanceSession(sessionId);
    ref.read(activeAttendanceSessionProvider.notifier).closeSession();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance session closed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeAttendanceSessionProvider);
    final courses = ref.watch(allCoursesCatalogProvider);
    final subjects = ref.watch(teacherSubjectsProvider);
    final batches = ref.watch(batchesProvider).valueOrNull ?? [];
    final teacher = ref.watch(teacherProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedCourse = _resolveSelectedCourse(courses);
    final effectiveBatchId = _resolveEffectiveBatchId(selectedCourse, batches);

    return SecurityOverlay(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(batchesProvider);
          ref.invalidate(subjectsProvider);
          ref.invalidate(coursesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Active Session Display (If Live) ────────────────────────
              if (activeSession != null && activeSession.isActive) ...[
                _buildLiveSessionCard(context, activeSession, isDark),
                const SizedBox(height: 24),
              ],

              // ── Start New Attendance Session ────────────────────────────
              Text(
                'Start Class Attendance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select academic program, batch, and subject to generate a secure attendance QR code.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),

              AppCard(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. Course / Degree Program Selector ───────────
                        Text(
                          'Course / Degree Program *',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _buildCoursePickerTile(context, isDark, courses, selectedCourse),
                        const SizedBox(height: 16),

                        // ── 2. Academic Hierarchy: Year & Section ─────────
                        if (isNarrow) ...[
                          // Mobile: Stacked Vertical Layout
                          Text(
                            'Admission / Batch Year *',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _buildYearSelector(isDark),
                          const SizedBox(height: 14),

                          Text(
                            'Section *',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _buildSectionSelector(isDark),
                        ] else ...[
                          // Tablet / Desktop: Two-column layout
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Admission / Batch Year *',
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildYearSelector(isDark),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Section *',
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildSectionSelector(isDark),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Target Batch Summary Chip
                        _buildTargetBatchSummary(context, isDark, selectedCourse, effectiveBatchId),
                        const SizedBox(height: 18),

                        // ── 3. Subject Selection ──────────────────────────
                        Text(
                          'Subject *',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _buildSubjectDropdown(context, isDark, subjects),

                        // Custom Subject Entry Fields (Vertical on narrow screens)
                        if (_isCustomSubject) ...[
                          const SizedBox(height: 14),
                          if (isNarrow) ...[
                            AppTextField(
                              controller: _customSubjectNameController,
                              labelText: 'Subject Name',
                              hintText: 'e.g. Cloud Computing & Distributed Systems',
                            ),
                            const SizedBox(height: 10),
                            AppTextField(
                              controller: _customSubjectCodeController,
                              labelText: 'Subject Code',
                              hintText: 'e.g. CS501',
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: AppTextField(
                                    controller: _customSubjectNameController,
                                    labelText: 'Subject Name',
                                    hintText: 'e.g. Cloud Computing',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: AppTextField(
                                    controller: _customSubjectCodeController,
                                    labelText: 'Subject Code',
                                    hintText: 'e.g. CS501',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                        const SizedBox(height: 16),

                        // ── 4. Room / Hall ────────────────────────────────
                        Text(
                          'Room / Hall',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _roomController,
                          labelText: 'Classroom / Lecture Hall',
                          hintText: 'e.g. Room 402, Lab 3, Auditorium B',
                          prefixIcon: Icons.meeting_room_outlined,
                        ),
                        const SizedBox(height: 20),

                        // ── 5. Expiry Time ────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'QR Code Expiration Time',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isCustomExpiry
                                    ? '${_customExpiryController.text.trim().isEmpty ? "10" : _customExpiryController.text.trim()} $_customExpiryUnit'
                                    : _qrExpirySeconds < 60
                                        ? '$_qrExpirySeconds sec'
                                        : '${_qrExpirySeconds ~/ 60} min',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildExpiryChip(label: '30s', seconds: 30),
                            _buildExpiryChip(label: '60s', seconds: 60),
                            _buildExpiryChip(label: '2 min', seconds: 120),
                            _buildExpiryChip(label: '5 min', seconds: 300),
                            _buildExpiryChip(label: '10 min', seconds: 600),
                            _buildExpiryChip(label: '15 min', seconds: 900),
                            ChoiceChip(
                              label: const Text('Custom Time'),
                              selected: _isCustomExpiry,
                              onSelected: (val) {
                                if (val) setState(() => _isCustomExpiry = true);
                              },
                            ),
                          ],
                        ),
                        if (_isCustomExpiry) ...[
                          const SizedBox(height: 12),
                          if (isNarrow) ...[
                            AppTextField(
                              controller: _customExpiryController,
                              labelText: 'Custom Time Duration',
                              hintText: _customExpiryUnit == 'seconds' ? 'e.g. 45' : 'e.g. 10',
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 8),
                            _buildCustomExpiryUnitDropdown(isDark),
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: AppTextField(
                                    controller: _customExpiryController,
                                    labelText: 'Custom Time Duration',
                                    hintText: _customExpiryUnit == 'seconds' ? 'e.g. 45' : 'e.g. 10',
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: _buildCustomExpiryUnitDropdown(isDark),
                                ),
                              ],
                            ),
                          ],
                        ],
                        const SizedBox(height: 16),

                        // ── 6. Location Geolocation Verification Switch ───
                        Material(
                          color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                            ),
                          ),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            title: const Text(
                              'Require Geolocation Verification (GPS)',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: const Text(
                              'Validates student device is physically in the lecture room (~100m radius)',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _locationRequired,
                            onChanged: (val) => setState(() => _locationRequired = val),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── 7. Generate QR Action Button ──────────────────
                        AppButton.primary(
                          label: 'Generate Session QR Code',
                          icon: Icons.qr_code_rounded,
                          isLoading: _isCreatingSession,
                          onPressed: () => _startAttendanceSession(selectedCourse, effectiveBatchId),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Past Session History ────────────────────────────────────
              Text(
                'Recent Session History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),

              StreamBuilder<List<AttendanceSessionModel>>(
                stream: ref.read(firestoreServiceProvider).streamSessionHistory(teacher?.user.id ?? ''),
                builder: (context, snapshot) {
                  final history = snapshot.data ?? [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CardShimmer(height: 80);
                  }
                  if (history.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.history_rounded,
                      title: 'No Past Sessions',
                      subtitle: 'Sessions you start will be logged here with attendance records.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.take(5).length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.elevatedDark : AppColors.slate100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.subjectName ?? 'Subject',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${DateFormat('d MMM, hh:mm a').format(item.startTime)} • Room ${item.room ?? "A"}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              label: item.isActive ? 'Active' : 'Closed',
                              color: item.isActive ? AppColors.success : AppColors.slate400,
                              small: true,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoursePickerTile(BuildContext context, bool isDark,
      List<CourseModel> courses, CourseModel selectedCourse) {
    return InkWell(
      onTap: () => _showCourseSelectionSheet(context, isDark, courses),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4A72FF).withValues(alpha: 0.4),
            width: 1.2,
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
                selectedCourse.code,
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
                    selectedCourse.name,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${selectedCourse.totalSemesters} Semesters • Tap to change course',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelector(bool isDark) {
    final years = AcademicDefaults.defaultYears;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: years.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final year = years[index];
          final isSelected = _selectedYear == year;
          return InkWell(
            onTap: () => setState(() => _selectedYear = year),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                '$year',
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
    );
  }

  Widget _buildSectionSelector(bool isDark) {
    final sections = AcademicDefaults.defaultSections;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sec = sections[index];
          final isSelected = _selectedSection.toUpperCase() == sec.toUpperCase();
          return InkWell(
            onTap: () => setState(() => _selectedSection = sec),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                'Sec $sec',
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
    );
  }

  Widget _buildTargetBatchSummary(BuildContext context, bool isDark,
      CourseModel course, String effectiveBatchId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF4A72FF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4A72FF).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_outlined, size: 18, color: Color(0xFF4A72FF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Target: ${course.code} • Year $_selectedYear • Section $_selectedSection',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4A72FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectDropdown(
      BuildContext context, bool isDark, List<SubjectModel> subjects) {
    final validSubjectId = _isCustomSubject
        ? 'custom'
        : (_selectedSubjectId ?? (subjects.isNotEmpty ? subjects.first.id : 'custom'));

    return DropdownButtonFormField<String>(
      initialValue: validSubjectId,
      isExpanded: true,
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.book_outlined, size: 20),
      ),
      items: [
        ...subjects.map((s) {
          return DropdownMenuItem(
            value: s.id,
            child: Text(
              '${s.code} — ${s.name}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          );
        }),
        const DropdownMenuItem(
          value: 'custom',
          child: Text(
            '+ Other — Enter Subject Manually',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
        ),
      ],
      onChanged: (val) {
        if (val == 'custom') {
          setState(() {
            _isCustomSubject = true;
            _selectedSubjectId = null;
          });
        } else if (val != null) {
          setState(() {
            _isCustomSubject = false;
            _selectedSubjectId = val;
          });
        }
      },
    );
  }

  Widget _buildCustomExpiryUnitDropdown(bool isDark) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _customExpiryUnit,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: const [
            DropdownMenuItem(value: 'seconds', child: Text('Seconds (s)')),
            DropdownMenuItem(value: 'minutes', child: Text('Minutes (m)')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _customExpiryUnit = val);
            }
          },
        ),
      ),
    );
  }

  void _showCourseSelectionSheet(
      BuildContext context, bool isDark, List<CourseModel> courses) {
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

  Widget _buildLiveSessionCard(
      BuildContext context, AttendanceSessionModel session, bool isDark) {
    return AppCard(
      borderColor: AppColors.success,
      borderWidth: 2,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE ATTENDANCE SESSION',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                'Expires ${DateFormat('hh:mm:ss a').format(session.endTime)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // QR Code in White Container for contrast
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate300),
            ),
            child: QrImageView(
              data: session.id,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            session.subjectName ?? 'Subject',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Session Token: ${session.id}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                ),
          ),
          const SizedBox(height: 16),

          // Live Student Stream
          StreamBuilder<List<AttendanceRecordModel>>(
            stream: ref
                .read(firestoreServiceProvider)
                .streamAttendanceRecordsForSession(session.id),
            builder: (context, snapshot) {
              final records = snapshot.data ?? [];
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.elevatedDark : AppColors.slate100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_alt_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${records.length} Students Checked In',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (records.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.secondary(
                        label: 'Export Attendance (CSV)',
                        icon: Icons.file_download_outlined,
                        onPressed: () async {
                          final students = ref.read(allStudentsProvider);
                          final ok = await CsvExportService.exportSessionAttendance(
                            session: session,
                            records: records,
                            enrolledStudents: students,
                          );
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Attendance CSV exported successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          AppButton.outlined(
            label: 'Close Attendance Session',
            icon: Icons.stop_circle_outlined,
            onPressed: () => _closeActiveSession(session.id),
          ),
        ],
      ),
    );
  }
}
