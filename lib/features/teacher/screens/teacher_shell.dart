import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
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
                  label: 'Today\'s Classes',
                  value: '2',
                  icon: Icons.calendar_today,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Subjects List
          Text(
            'Your Subjects',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...subjects.map(
            (sub) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${sub.code} • ${sub.credits} Credits',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gray400),
                  ],
                ),
              ),
            ),
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
  final _durationController = TextEditingController(text: '5');

  final FirestoreService _firestoreService = FirestoreService();

  void _startSession(String teacherId, String courseId) {
    if (_selectedSubjectId == null || _selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject and batch.')),
      );
      return;
    }

    final duration = int.tryParse(_durationController.text) ?? 5;

    setState(() {
      _isGenerating = true;
    });

    final now = DateTime.now();
    final session = AttendanceSessionModel(
      id: 'session-${now.millisecondsSinceEpoch}',
      subjectId: _selectedSubjectId!,
      teacherId: teacherId,
      courseId: courseId,
      batchId: _selectedBatchId!,
      date: now,
      startTime: now,
      endTime: now.add(Duration(minutes: duration)),
      isActive: true,
      qrToken: 'session-${now.millisecondsSinceEpoch}', // QR is the session ID itself
      createdAt: now,
      locationRequired: true,
      allowedRadiusMeters: 100,
    );

    // Save to Firestore
    _firestoreService.createAttendanceSession(session);
    ref.read(activeAttendanceSessionProvider.notifier).startSession(session);

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
    setState(() {
      _isGenerating = false;
      _secondsRemaining = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance session closed.')),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeAttendanceSessionProvider);
    final teacher = ref.watch(teacherProfileProvider);
    final subjects = ref.watch(teacherSubjectsProvider);

    if (teacher == null) return const LoadingState();

    // Default select first subject if not set
    if (_selectedSubjectId == null && subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
    }

    // Find course of selected subject
    final selectedSubject = subjects.firstWhere(
      (s) => s.id == _selectedSubjectId,
      orElse: () => subjects.isNotEmpty ? subjects.first : const SubjectModel(id: '', name: '', code: '', courseId: '', semester: 0, credits: 0, teacherId: ''),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (!_isGenerating) ...[
            // Setup session view
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Setup Attendance Session',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Subject Selection Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubjectId,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      prefixIcon: const Icon(Icons.book_outlined),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: subjects.map((sub) {
                      return DropdownMenuItem(
                        value: sub.id,
                        child: Text(sub.name),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSubjectId = val),
                  ),
                  const SizedBox(height: 16),

                  // Batch Selection Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBatchId,
                    decoration: InputDecoration(
                      labelText: 'Batch',
                      prefixIcon: const Icon(Icons.group_outlined),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: (ref.watch(batchesProvider).value ?? []).where((b) => b.courseId == selectedSubject.courseId).map((batch) {
                      return DropdownMenuItem(
                        value: batch.id,
                        child: Text(batch.name),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedBatchId = val),
                  ),
                  const SizedBox(height: 16),

                  GlassTextField(
                    controller: _durationController,
                    labelText: 'Duration (Minutes)',
                    hintText: '5',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  GlassButton(
                    label: 'Generate Attendance QR',
                    onPressed: () => _startSession(teacher.user.id, selectedSubject.courseId),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Active QR View
            if (activeSession != null) ...[
              Text(
                selectedSubject.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Live Session Active',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.success),
              ),
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  children: [
                    QrImageView(
                      data: activeSession.qrToken ?? '',
                      version: QrVersions.auto,
                      size: 200.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.white,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Time Remaining: ${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Real-time Attendees List Stream Builder
              StreamBuilder<List<AttendanceRecordModel>>(
                stream: _firestoreService.streamAttendanceRecordsForSession(activeSession.id),
                builder: (context, snapshot) {
                  final records = snapshot.data ?? [];
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Scanned / Registered',
                              value: '${records.length} Present',
                              icon: Icons.people,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (records.isNotEmpty) ...[
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Checked-In Students:',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: records.length,
                                separatorBuilder: (context, index) => const Divider(height: 12),
                                itemBuilder: (context, index) {
                                  final rec = records[index];
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        rec.studentId, // Shows Roll No (e.g. CS2024001)
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Verified',
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
                        const SizedBox(height: 24),
                      ],
                    ],
                  );
                }
              ),
              GlassButton(
                label: 'Close Attendance Session',
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
// TAB 2: CIRCULARS
// ══════════════════════════════════════════════════════════════════════
class _TeacherCircularsTab extends ConsumerWidget {
  const _TeacherCircularsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(circularsProvider);

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final c = list[index];
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(
                    label: c.category.displayName,
                    color: c.isUrgent ? AppColors.error : AppColors.info,
                    small: true,
                  ),
                  Text(
                    '${c.publishDate.day}/${c.publishDate.month}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                c.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                c.content,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
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
