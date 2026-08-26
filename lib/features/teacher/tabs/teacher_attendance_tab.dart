import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/core/enums/enums.dart';
import 'package:presenza/core/security/attendance_security_controller.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/data/models/course_model.dart';
import 'package:presenza/providers/app_providers.dart';
import 'package:presenza/shared/widgets/shared_widgets.dart';
import 'package:presenza/data/services/location_service.dart';

class TeacherAttendanceTab extends ConsumerStatefulWidget {
  const TeacherAttendanceTab({super.key});

  @override
  ConsumerState<TeacherAttendanceTab> createState() => _TeacherAttendanceTabState();
}

class _TeacherAttendanceTabState extends ConsumerState<TeacherAttendanceTab> {
  final _roomController = TextEditingController(text: 'Room 402');
  final _customSubjectNameController = TextEditingController();
  final _customSubjectCodeController = TextEditingController();

  String? _selectedSubjectId;
  bool _isCustomSubject = false;
  String _selectedBatchId = 'batch-2024-a';
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
    ref.read(attendanceSecurityProvider.notifier).disableSecureMode();
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

  Future<void> _startAttendanceSession() async {
    final teacher = ref.read(teacherProfileProvider);
    if (teacher == null) return;

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
        courseId: 'course-btech-cse',
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
        subjectId = 'sub-cs401';
        subjectName = 'Data Structures & Algorithms';
        subjectCode = 'CS401';
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
      courseId: 'course-btech-cse',
      batchId: _selectedBatchId,
      room: _roomController.text.trim(),
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
    final subjects = ref.watch(teacherSubjectsProvider);
    final batches = ref.watch(batchesProvider).valueOrNull ?? [];
    final teacher = ref.watch(teacherProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SecurityOverlay(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(batchesProvider);
          ref.invalidate(subjectsProvider);
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
                'Select a subject or enter custom details to generate a secure QR code.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),

              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject Selection
                    Text('Subject', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      initialValue: _isCustomSubject
                          ? 'custom'
                          : (_selectedSubjectId ?? (subjects.isNotEmpty ? subjects.first.id : 'custom')),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.book_outlined, size: 20),
                      ),
                      items: [
                        ...subjects.map((s) {
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.code} — ${s.name}', overflow: TextOverflow.ellipsis),
                          );
                        }),
                        const DropdownMenuItem(
                          value: 'custom',
                          child: Text('+ Other — Enter Subject Manually',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
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
                    ),

                    if (_isCustomSubject) ...[
                      const SizedBox(height: 14),
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
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: AppTextField(
                              controller: _customSubjectCodeController,
                              labelText: 'Code',
                              hintText: 'e.g. CS501',
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Batch & Room Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: batches.any((b) => b.id == _selectedBatchId)
                                ? _selectedBatchId
                                : (batches.isNotEmpty ? batches.first.id : 'batch-2024-a'),
                            decoration: const InputDecoration(
                              labelText: 'Target Section',
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
                                      child: Text('Section A'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'batch-2024-b',
                                      child: Text('Section B'),
                                    ),
                                  ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedBatchId = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _roomController,
                            labelText: 'Room / Hall',
                            prefixIcon: Icons.meeting_room_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Expiry Time (Preset chips in seconds/minutes + Custom unit selector)
                    Row(
                      children: [
                        Text('QR Code Expiration Time', style: Theme.of(context).textTheme.labelLarge),
                        const Spacer(),
                        Text(
                          _isCustomExpiry
                              ? '${_customExpiryController.text.trim().isEmpty ? "10" : _customExpiryController.text.trim()} $_customExpiryUnit'
                              : _qrExpirySeconds < 60
                                  ? '$_qrExpirySeconds sec'
                                  : '${_qrExpirySeconds ~/ 60} min',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                            child: Container(
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
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Location Geolocation Verification Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Require Geolocation Verification (GPS)'),
                      subtitle: const Text('Ensure students are physically inside the classroom (~100m)'),
                      value: _locationRequired,
                      onChanged: (val) => setState(() => _locationRequired = val),
                    ),
                    const SizedBox(height: 16),

                    AppButton.primary(
                      label: 'Generate Session QR Code',
                      icon: Icons.qr_code_rounded,
                      isLoading: _isCreatingSession,
                      onPressed: _startAttendanceSession,
                    ),
                  ],
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Session Token: ${session.id}',
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
              return Container(
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
              );
            },
          ),
          const SizedBox(height: 16),

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
