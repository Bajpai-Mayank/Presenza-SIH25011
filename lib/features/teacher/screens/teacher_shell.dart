import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/enums.dart';
import 'package:presenza/core/services/security_service.dart';
import 'package:presenza/data/models/app_models.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:presenza/data/services/firestore_service.dart';
import 'package:presenza/data/models/course_model.dart';

class TeacherShell extends ConsumerStatefulWidget {
  const TeacherShell({super.key});

  @override
  ConsumerState<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends ConsumerState<TeacherShell> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Teacher Dashboard',
    'Session QR Generator',
    'Manage Circulars',
    'Student Directory',
    'Teacher Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = [
      const _TeacherDashboardTab(),
      const _TeacherQRGeneratorTab(),
      const _TeacherCircularsTab(),
      const _TeacherStudentsTab(),
      const _TeacherProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () {
              ref.read(themeModeProvider.notifier).setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.white.withAlpha(20) : AppColors.black.withAlpha(10),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_outlined),
              activeIcon: Icon(Icons.qr_code),
              label: 'QR Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rate_review_outlined),
              activeIcon: Icon(Icons.rate_review),
              label: 'Circulars',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'Students',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 0: DASHBOARD
// ══════════════════════════════════════════════════════════════════════
class _TeacherDashboardTab extends ConsumerWidget {
  const _TeacherDashboardTab();

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref, String teacherUid) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final courses = ref.read(coursesProvider).valueOrNull ?? [];
    String selectedCourseId = courses.isNotEmpty ? courses.first.id : 'course-btech-cse';
    int selectedSemester = 4;
    int selectedCredits = 4;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Academic Subject'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subject Name',
                      hintText: 'e.g. Cloud Computing & DevOps',
                      prefixIcon: Icon(Icons.book_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subject Code',
                      hintText: 'e.g. CS502',
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  if (courses.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: selectedCourseId,
                      decoration: const InputDecoration(
                        labelText: 'Course / Degree',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedCourseId = val);
                      },
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedSemester,
                          decoration: const InputDecoration(labelText: 'Semester'),
                          items: List.generate(8, (i) => i + 1)
                              .map((s) => DropdownMenuItem(value: s, child: Text('Sem $s')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedSemester = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedCredits,
                          decoration: const InputDecoration(labelText: 'Credits'),
                          items: List.generate(6, (i) => i + 1)
                              .map((c) => DropdownMenuItem(value: c, child: Text('$c Credits')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedCredits = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      final uuid = const Uuid().v4().substring(0, 8);
                      final newSubject = SubjectModel(
                        id: 'sub-$uuid',
                        name: nameCtrl.text.trim(),
                        code: codeCtrl.text.trim().toUpperCase(),
                        courseId: selectedCourseId,
                        semester: selectedSemester,
                        credits: selectedCredits,
                        teacherId: teacherUid,
                      );

                      final firestoreService = FirestoreService();
                      await firestoreService.addTeacherSubject(
                        teacherUid: teacherUid,
                        subject: newSubject,
                      );
                      await ref.read(teacherProfileProvider.notifier).refresh();

                      if (context.mounted) {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Subject ${newSubject.name} (${newSubject.code}) added successfully.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add Subject'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacher = ref.watch(teacherProfileProvider);
    final subjects = ref.watch(teacherSubjectsProvider);

    if (teacher == null) return const LoadingState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${teacher.user.name}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            '${teacher.employeeId} • Department: ${teacher.departmentId.replaceAll('dept-', '').toUpperCase()}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 24),

          // Overview Stats
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Assigned Subjects',
                  value: subjects.length.toString(),
                  icon: Icons.menu_book,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  label: 'Department',
                  value: teacher.departmentId.replaceAll('dept-', '').toUpperCase(),
                  icon: Icons.account_balance_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Subjects List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Curriculum Subjects',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showAddSubjectDialog(context, ref, teacher.user.id),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Subject'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (subjects.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.book_outlined, size: 40, color: AppColors.gray400),
                  const SizedBox(height: 12),
                  Text(
                    'No curriculum subjects assigned yet.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Click "+ Add Subject" above to create and manage subjects for your department.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gray400),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sub = subjects[index];
                return GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${sub.code} • ${sub.credits} Credits • Semester ${sub.semester}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gray400),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Sem ${sub.semester}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 1: QR GENERATOR & SESSION
// ══════════════════════════════════════════════════════════════════════
class _TeacherQRGeneratorTab extends ConsumerStatefulWidget {
  const _TeacherQRGeneratorTab();

  @override
  ConsumerState<_TeacherQRGeneratorTab> createState() => _TeacherQRGeneratorTabState();
}

class _TeacherQRGeneratorTabState extends ConsumerState<_TeacherQRGeneratorTab> {
  Timer? _sessionTimer;
  int _secondsRemaining = 0;
  bool _isGenerating = false;

  String? _selectedSubjectId;
  String? _selectedBatchId;
  final _roomController = TextEditingController(text: 'Room 401, CS Block');
  final _durationController = TextEditingController(text: '5');
  bool _requireLocation = false;
  static const _uuid = Uuid();

  final FirestoreService _firestoreService = FirestoreService();

  void _showAddSubjectDialog(String teacherUid) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final courses = ref.read(coursesProvider).valueOrNull ?? [];
    String selectedCourseId = courses.isNotEmpty ? courses.first.id : 'course-btech-cse';
    int selectedSemester = 4;
    int selectedCredits = 4;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Subject'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Subject Name', prefixIcon: Icon(Icons.book)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'Subject Code', prefixIcon: Icon(Icons.pin)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      final uuid = const Uuid().v4().substring(0, 8);
                      final newSubject = SubjectModel(
                        id: 'sub-$uuid',
                        name: nameCtrl.text.trim(),
                        code: codeCtrl.text.trim().toUpperCase(),
                        courseId: selectedCourseId,
                        semester: selectedSemester,
                        credits: selectedCredits,
                        teacherId: teacherUid,
                      );

                      await _firestoreService.addTeacherSubject(
                        teacherUid: teacherUid,
                        subject: newSubject,
                      );
                      await ref.read(teacherProfileProvider.notifier).refresh();

                      if (mounted) {
                        setState(() => _selectedSubjectId = newSubject.id);
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Subject ${newSubject.name} created.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _startSession(String teacherId, String teacherName, String courseId, SubjectModel subject) {
    if (_selectedSubjectId == null || _selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject and batch/section.')),
      );
      return;
    }

    final duration = int.tryParse(_durationController.text) ?? 5;

    setState(() {
      _isGenerating = true;
    });

    final now = DateTime.now();
    final sessionId = _uuid.v4();
    final session = AttendanceSessionModel(
      id: sessionId,
      subjectId: subject.id,
      subjectName: subject.name,
      subjectCode: subject.code,
      teacherId: teacherId,
      teacherName: teacherName,
      courseId: courseId,
      batchId: _selectedBatchId!,
      room: _roomController.text.trim(),
      date: now,
      startTime: now,
      endTime: now.add(Duration(minutes: duration)),
      isActive: true,
      qrToken: sessionId,
      createdAt: now,
      locationRequired: _requireLocation,
      campusLat: 28.5355,
      campusLng: 77.3910,
      allowedRadiusMeters: 200,
    );

    // Save to Firestore
    _firestoreService.createAttendanceSession(session);
    ref.read(activeAttendanceSessionProvider.notifier).startSession(session);
    SecurityService.enableScreenshotProtection();

    _secondsRemaining = duration * 60;
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _closeSession(session.id);
      }
    });
  }

  void _closeSession(String sessionId) {
    _sessionTimer?.cancel();
    _firestoreService.closeAttendanceSession(sessionId);
    ref.read(activeAttendanceSessionProvider.notifier).closeSession();
    SecurityService.disableScreenshotProtection();
    setState(() {
      _isGenerating = false;
      _secondsRemaining = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance session closed successfully.')),
    );
  }

  @override
  void dispose() {
    SecurityService.disableScreenshotProtection();
    _sessionTimer?.cancel();
    _durationController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeAttendanceSessionProvider);
    final teacher = ref.watch(teacherProfileProvider);
    final subjects = ref.watch(teacherSubjectsProvider);
    final allStudents = ref.watch(allStudentsProvider);

    if (teacher == null) return const LoadingState();

    // Default select first subject if not set
    if (_selectedSubjectId == null && subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
    }

    final selectedSubject = subjects.firstWhere(
      (s) => s.id == _selectedSubjectId,
      orElse: () => subjects.isNotEmpty
          ? subjects.first
          : const SubjectModel(id: '', name: '', code: '', courseId: '', semester: 0, credits: 0, teacherId: ''),
    );

    final batches = (ref.watch(batchesProvider).valueOrNull ?? [])
        .where((b) => b.courseId == selectedSubject.courseId || selectedSubject.courseId.isEmpty)
        .toList();

    if (_selectedBatchId == null && batches.isNotEmpty) {
      _selectedBatchId = batches.first.id;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isGenerating) ...[
            // Setup session card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create Attendance Session',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddSubjectDialog(teacher.user.id),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Subject'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Subject Dropdown
                  if (subjects.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: subjects.any((s) => s.id == _selectedSubjectId)
                          ? _selectedSubjectId
                          : subjects.first.id,
                      decoration: InputDecoration(
                        labelText: 'Academic Subject',
                        prefixIcon: const Icon(Icons.book_outlined),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        ...subjects.map((sub) {
                          return DropdownMenuItem(
                            value: sub.id,
                            child: Text('${sub.name} (${sub.code})'),
                          );
                        }),
                        const DropdownMenuItem(
                          value: '__manual_entry__',
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline, size: 16, color: AppColors.info),
                              SizedBox(width: 8),
                              Text(
                                'Other / Enter Subject Manually...',
                                style: TextStyle(color: AppColors.info, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == '__manual_entry__') {
                          _showAddSubjectDialog(teacher.user.id);
                        } else if (val != null) {
                          setState(() => _selectedSubjectId = val);
                        }
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.error.withAlpha(100)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No subjects available. Click "New Subject" to create one.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Batch Selection Dropdown
                  if (batches.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: batches.any((b) => b.id == _selectedBatchId)
                          ? _selectedBatchId
                          : batches.first.id,
                      decoration: InputDecoration(
                        labelText: 'Class / Batch / Section',
                        prefixIcon: const Icon(Icons.group_outlined),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: batches.map((batch) {
                        return DropdownMenuItem(
                          value: batch.id,
                          child: Text(batch.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedBatchId = val),
                    ),
                  const SizedBox(height: 16),

                  // Classroom Location
                  GlassTextField(
                    controller: _roomController,
                    labelText: 'Classroom / Location',
                    prefixIcon: Icons.room_outlined,
                    hintText: 'e.g. Room 401, CS Block',
                  ),
                  const SizedBox(height: 16),

                  // Duration
                  GlassTextField(
                    controller: _durationController,
                    labelText: 'Session Expiry Window (Minutes)',
                    prefixIcon: Icons.timer_outlined,
                    hintText: '5',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Geofence Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Require Classroom GPS Location'),
                    subtitle: const Text('Verifies student is within campus radius'),
                    value: _requireLocation,
                    onChanged: (val) => setState(() => _requireLocation = val),
                  ),
                  const SizedBox(height: 20),

                  // Generate QR Button
                  GlassButton(
                    label: 'Generate & Launch QR Session',
                    icon: Icons.qr_code_scanner,
                    onPressed: subjects.isEmpty
                        ? null
                        : () => _startSession(
                              teacher.user.id,
                              teacher.user.name,
                              selectedSubject.courseId.isNotEmpty ? selectedSubject.courseId : 'general',
                              selectedSubject,
                            ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Session History Section
            Text(
              'Past Session History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<AttendanceSessionModel>>(
              stream: _firestoreService.streamSessionHistory(teacher.user.id),
              builder: (context, snapshot) {
                final sessions = snapshot.data ?? [];
                if (sessions.isEmpty) {
                  return GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No past sessions recorded yet. Active sessions will log automatically.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.gray400),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final s = sessions[index];
                    return GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.subjectName ?? s.subjectId,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${DateFormat('dd MMM yyyy • hh:mm a').format(s.date)}${s.room != null && s.room!.isNotEmpty ? ' • ${s.room}' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gray400),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: s.isActive ? 'Active' : 'Closed',
                            color: s.isActive ? AppColors.success : AppColors.gray400,
                            small: true,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ] else ...[
            // Live Session View (Section 3: Real-Time Live Attendance Monitoring)
            if (activeSession != null) ...[
              Text(
                activeSession.subjectName ?? 'Live Attendance Session',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Batch: ${activeSession.batchId} • ${activeSession.room ?? 'Classroom'} • Date: ${DateFormat('dd MMM yyyy').format(activeSession.date)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gray400),
              ),
              const SizedBox(height: 16),

              // Live Attendance Stats from Firestore Stream
              StreamBuilder<List<AttendanceRecordModel>>(
                stream: _firestoreService.streamAttendanceRecordsForSession(activeSession.id),
                builder: (context, snapshot) {
                  final records = snapshot.data ?? [];
                  final batchStudents = allStudents.where((s) => s.batchId == activeSession.batchId).toList();
                  final totalEnrolled = batchStudents.isNotEmpty ? batchStudents.length : (records.isNotEmpty ? records.length : 1);
                  final presentCount = records.length;
                  final absentCount = (totalEnrolled - presentCount).clamp(0, totalEnrolled);
                  final attendancePercentage = totalEnrolled > 0 ? (presentCount / totalEnrolled) * 100 : 0.0;

                  return Column(
                    children: [
                      // Detailed Session Metadata Card
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Class: ${activeSession.batchId} • ${activeSession.room ?? 'Room 401'}',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Faculty: ${activeSession.teacherName ?? teacher.user.name} • ${DateFormat('hh:mm a').format(activeSession.startTime)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gray400),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                  label: activeSession.locationRequired ? 'QR + GPS (200m)' : 'QR Code Only',
                                  color: activeSession.locationRequired ? AppColors.success : AppColors.info,
                                  small: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.white.withAlpha(8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Enrolled: $totalEnrolled', style: Theme.of(context).textTheme.labelSmall),
                                  Text('Present: $presentCount', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                                  Text('Absent: $absentCount', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.warning)),
                                  Text('Rate: ${attendancePercentage.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.info, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3-Stat Live Monitoring Grid
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Present',
                              value: '$presentCount / $totalEnrolled',
                              icon: Icons.check_circle,
                              iconColor: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              label: 'Absent',
                              value: '$absentCount',
                              icon: Icons.cancel_outlined,
                              iconColor: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              label: 'Rate',
                              value: '${attendancePercentage.toStringAsFixed(0)}%',
                              icon: Icons.trending_up,
                              iconColor: attendancePercentage >= 75.0 ? AppColors.success : AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // QR Code Display Card
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: QrImageView(
                                data: activeSession.qrToken ?? '',
                                version: QrVersions.auto,
                                size: 210.0,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.timer_outlined, size: 20, color: AppColors.warning),
                                const SizedBox(width: 8),
                                Text(
                                  'Session Expires in: ${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _secondsRemaining < 60 ? AppColors.error : null,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Students scan this QR code using Presenza to verify attendance.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gray400),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Real-time Verified Attendees Roster
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Real-Time Verified Attendees (${records.length})',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (records.isNotEmpty)
                                  const StatusBadge(
                                    label: 'LIVE UPDATING',
                                    color: AppColors.success,
                                    small: true,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (records.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text(
                                    'Waiting for student check-ins...',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gray400),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: records.length,
                                separatorBuilder: (context, index) => const Divider(height: 12),
                                itemBuilder: (context, index) {
                                  final rec = records[index];
                                  final std = allStudents.where((s) => s.user.id == rec.studentId || s.studentId == rec.studentId).firstOrNull;

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              std != null ? std.user.name : 'Student (${rec.studentId.substring(0, 6)}...)',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              '${std?.studentId ?? rec.studentId} • ${DateFormat('hh:mm:ss a').format(rec.timestamp)}',
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.gray400),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            rec.locationVerified ? 'QR + GPS' : 'QR Verified',
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.success),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),

              GlassButton(
                label: 'Close Attendance Session',
                icon: Icons.stop_circle_outlined,
                onPressed: () => _closeSession(activeSession.id),
                filled: false,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 2: ACADEMIC ACTIVITIES & CIRCULARS
// ══════════════════════════════════════════════════════════════════════
class _TeacherCircularsTab extends ConsumerWidget {
  const _TeacherCircularsTab();

  void _showCreateAnnouncementDialog(BuildContext context, WidgetRef ref, String teacherUid, String teacherName) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    CircularCategory selectedCategory = CircularCategory.academic;
    CircularPriority selectedPriority = CircularPriority.normal;
    DateTime? selectedEventDate;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Publish Academic Notice / Event'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notice / Event Title',
                      hintText: 'e.g. Mid-Term Assessment Schedule',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CircularCategory>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: CircularCategory.values
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CircularPriority>(
                    initialValue: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: CircularPriority.values
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.displayName)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedPriority = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Event Location / Room (Optional)',
                      hintText: 'e.g. Seminar Hall 1 / Online',
                      prefixIcon: Icon(Icons.pin_drop_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notice Content / Description',
                      hintText: 'Provide detailed instructions or notice body...',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      final now = DateTime.now();
                      final uuid = const Uuid().v4().substring(0, 8);
                      final circular = CircularModel(
                        id: 'circ-$uuid',
                        title: titleCtrl.text.trim(),
                        content: contentCtrl.text.trim(),
                        category: selectedCategory,
                        priority: selectedPriority,
                        authorId: teacherUid,
                        authorName: teacherName,
                        authorRole: 'teacher',
                        isOfficial: true,
                        location: locationCtrl.text.trim().isNotEmpty ? locationCtrl.text.trim() : null,
                        eventDate: selectedEventDate ?? now,
                        publishDate: now,
                        createdAt: now,
                        updatedAt: now,
                      );

                      final firestoreService = FirestoreService();
                      await firestoreService.saveCircular(circular);

                      if (context.mounted) {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notice published to all enrolled students.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Publish Notice'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(circularsProvider);
    final teacher = ref.watch(teacherProfileProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Department Notices (${list.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              FilledButton.tonalIcon(
                onPressed: teacher != null
                    ? () => _showCreateAnnouncementDialog(context, ref, teacher.user.id, teacher.user.name)
                    : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Post Notice'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No circulars or academic notices published yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.gray400),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final c = list[index];
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              StatusBadge(
                                label: c.isOfficial ? 'OFFICIAL' : 'STUDENT EVENT',
                                color: c.isOfficial ? AppColors.info : AppColors.warning,
                                small: true,
                              ),
                              const SizedBox(width: 6),
                              StatusBadge(
                                label: c.category.displayName,
                                color: c.isUrgent ? AppColors.error : AppColors.gray400,
                                small: true,
                              ),
                            ],
                          ),
                          Text(
                            DateFormat('dd MMM yyyy').format(c.publishDate),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.gray400),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        c.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.content,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (c.location != null && c.location!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.pin_drop_outlined, size: 14, color: AppColors.gray400),
                            const SizedBox(width: 4),
                            Text(
                              c.location!,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.gray400),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Posted by: ${c.authorName}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.gray500),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 3: STUDENTS DIRECTORY
// ══════════════════════════════════════════════════════════════════════
class _TeacherStudentsTab extends ConsumerWidget {
  const _TeacherStudentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(allStudentsProvider);

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: students.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final std = students[index];
        return GlassCard(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.white.withAlpha(20),
                child: Text(
                  std.user.initials,
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      std.user.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      std.studentId,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Edit attendance/grades for ${std.user.name}')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// TAB 4: PROFILE
// ══════════════════════════════════════════════════════════════════════
class _TeacherProfileTab extends ConsumerWidget {
  const _TeacherProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacher = ref.watch(teacherProfileProvider);

    if (teacher == null) return const LoadingState();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GlassCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.white.withAlpha(20),
                  child: Text(
                    teacher.user.initials,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  teacher.user.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  teacher.user.email,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                _ProfileRow(label: 'Employee ID', value: teacher.employeeId),
                _ProfileRow(label: 'Department ID', value: teacher.departmentId.replaceAll('dept-', '').toUpperCase()),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            label: 'Logout',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
            filled: false,
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
