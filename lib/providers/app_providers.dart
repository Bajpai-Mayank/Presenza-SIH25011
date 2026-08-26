import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/models/activity_model.dart';
import 'package:presenza/data/models/app_models.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/data/models/course_model.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/data/models/user_session_model.dart';
import 'package:presenza/data/models/auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:presenza/data/services/firestore_service.dart';
import 'package:presenza/data/services/auth_service.dart';
import 'package:uuid/uuid.dart';

// ══════════════════════════════════════════════════════════════════════
// THEME (System, Light, Dark with Persistence)
// ══════════════════════════════════════════════════════════════════════

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString('themeMode') ?? 'system';
      state = ThemeMode.values.firstWhere(
        (m) => m.name == value,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', mode.name);
    } catch (_) {}
  }
}

// ══════════════════════════════════════════════════════════════════════
// SERVICES (singletons)
// ══════════════════════════════════════════════════════════════════════

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

// ══════════════════════════════════════════════════════════════════════
// AUTH
// ══════════════════════════════════════════════════════════════════════

final authStatusProvider =
    StateNotifierProvider<AuthStatusNotifier, AuthState>((ref) {
  return AuthStatusNotifier(ref);
});

final authStateProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStatusProvider).user;
});

class AuthStatusNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  StreamSubscription? _authSubscription;
  StreamSubscription? _sessionSubscription;

  AuthStatusNotifier(this._ref) : super(const AuthState.initializing()) {
    _init();
  }

  void _init() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      _sessionSubscription?.cancel();
      if (user == null) {
        state = const AuthState.unauthenticated();
      } else {
        state = const AuthState.fetchingProfile();
        try {
          final firestoreService = _ref.read(firestoreServiceProvider);
          final userModel = await firestoreService.getUserModel(user.uid).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Profile fetch timeout'),
          );
          
          if (userModel != null) {
            state = AuthState.authenticated(userModel);

            // Start session monitor in background, do not block
            _monitorSession(firestoreService);
          } else {
            state = const AuthState.profileMissing();
          }
        } catch (e) {
          debugPrint('AuthStatusNotifier: Failed to load profile: $e');
          state = AuthState.error(
            'Failed to load your profile. Please check your connection and try again.',
          );
        }
      }
    });
  }

  void _monitorSession(FirestoreService firestoreService) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeSessionId = prefs.getString('active_session_id');
      if (activeSessionId != null) {
        _sessionSubscription = firestoreService
            .streamUserSession(activeSessionId)
            .listen((session) {
          if (session == null || !session.isActive) {
            // Session invalidated by another login
            FirebaseAuth.instance.signOut();
          }
        });
      }
    } catch (e) {
      debugPrint('Session monitor error: $e');
    }
  }

  Future<String?> login(String email, String password) async {
    state = const AuthState.authenticating();
    final authService = _ref.read(authServiceProvider);
    
    try {
      // Use timeout for auth sign in
      final result = await authService.signIn(email: email, password: password).timeout(
        const Duration(seconds: 15),
        onTimeout: () => AuthResult.error('Login timed out. Check your internet connection.'),
      );
      
      if (result.success && result.user != null) {
        final firestoreService = _ref.read(firestoreServiceProvider);
        
        final prefs = await SharedPreferences.getInstance();
        String? deviceId = prefs.getString('persistent_device_id');
        if (deviceId == null) {
          deviceId = const Uuid().v4();
          await prefs.setString('persistent_device_id', deviceId);
        }

        final hasOtherActiveSession = await firestoreService.hasActiveSession(result.user!.uid, deviceId);
        if (hasOtherActiveSession) {
          await FirebaseAuth.instance.signOut();
          state = const AuthState.unauthenticated();
          return 'This account is already active on another device.';
        }

        unawaited(_performSessionBookkeeping(result.user!.uid, deviceId));
        return null; // success
      }
      state = const AuthState.unauthenticated(); // Reset on error
      return result.errorMessage;
    } catch (e) {
      state = const AuthState.unauthenticated();
      return 'An unexpected error occurred: $e';
    }
  }

  Future<void> _performSessionBookkeeping(String uid, String deviceId) async {
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      final sessionId = const Uuid().v4();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_session_id', sessionId);

      final session = UserSessionModel(
        sessionId: sessionId,
        userId: uid,
        deviceId: deviceId, 
        loginAt: DateTime.now(),
        isActive: true,
      );
      // Execute in parallel
      await Future.wait([
        firestoreService.createUserSession(session),
        firestoreService.invalidateOtherSessions(uid, sessionId),
      ]);
    } catch (e) {
      debugPrint('Session bookkeeping failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeSessionId = prefs.getString('active_session_id');
      if (activeSessionId != null) {
        final firestoreService = _ref.read(firestoreServiceProvider);
        await firestoreService.deactivateSession(activeSessionId);
        await prefs.remove('active_session_id');
      }
    } catch (e) {
      debugPrint('Logout session deactivation failed: $e');
    }
    await FirebaseAuth.instance.signOut();
  }

  Future<void> refreshProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    state = const AuthState.fetchingProfile();
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      final userModel = await firestoreService.getUserModel(user.uid);
      if (userModel != null) {
        state = AuthState.authenticated(userModel);
      } else {
        state = const AuthState.profileMissing();
      }
    } catch (e) {
      state = AuthState.error('Failed to refresh profile: $e');
    }
  }

  void updateLocalUser(UserModel updatedUser) {
    if (state.isAuthenticated) {
      state = AuthState.authenticated(updatedUser);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _sessionSubscription?.cancel();
    super.dispose();
  }
}

final currentRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authStateProvider)?.role;
});

// ══════════════════════════════════════════════════════════════════════
// STUDENT DATA
// ══════════════════════════════════════════════════════════════════════

final studentProfileProvider =
    StateNotifierProvider<StudentProfileNotifier, StudentModel?>((ref) {
  final user = ref.watch(authStateProvider);
  return StudentProfileNotifier(ref, user);
});

class StudentProfileNotifier extends StateNotifier<StudentModel?> {
  final Ref _ref;
  final UserModel? _user;
  StudentProfileNotifier(this._ref, this._user) : super(null) {
    if (_user != null && _user.role == UserRole.student) {
      _load(_user.id);
    }
  }

  Future<void> _load(String uid) async {
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      final profile = await firestoreService.getStudentProfile(uid);
      if (profile != null) {
        state = profile;
      }
    } catch (e) {
      debugPrint('StudentProfileNotifier: Firestore getStudentProfile failed: $e');
    }
  }

  Future<void> refresh() async {
    if (_user != null) {
      await _load(_user.id);
    }
  }
}

final studentAttendanceRecordsProvider =
    StreamProvider<List<AttendanceRecordModel>>((ref) {
  final student = ref.watch(studentProfileProvider);
  if (student == null) return Stream.value([]);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamStudentAttendanceRecords(student.user.id);
});

final enrolledStudentsCountProvider = FutureProvider<int>((ref) async {
  final student = ref.watch(studentProfileProvider);
  if (student == null) return 0;
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getEnrolledStudentCount(student.batchId);
});

final subjectAttendanceProvider = Provider<List<SubjectAttendance>>((ref) {
  final student = ref.watch(studentProfileProvider);
  if (student == null) return [];

  final subjects = ref.watch(subjectsProvider).value ?? [];
  final teachers = ref.watch(allTeachersProvider);
  final recordsAsync = ref.watch(studentAttendanceRecordsProvider);
  final records = recordsAsync.value ?? [];

  final studentSubjects =
      subjects.where((sub) => sub.courseId == student.courseId).toList();

  final Map<String, List<AttendanceRecordModel>> grouped = {};
  for (final r in records) {
    grouped.putIfAbsent(r.subjectId, () => []).add(r);
  }

  return studentSubjects.map((sub) {
    final subRecords = grouped[sub.id] ?? [];
    final teacherName = teachers
        .where((t) => t.user.id == sub.teacherId || t.employeeId == sub.teacherId)
        .firstOrNull
        ?.user
        .name;

    if (subRecords.isEmpty) {
      return SubjectAttendance(
        subjectId: sub.id,
        subjectName: sub.name,
        subjectCode: sub.code,
        teacherName: teacherName,
        credits: sub.credits,
        totalClasses: 0,
        present: 0,
        absent: 0,
        late: 0,
        excused: 0,
      );
    }

    final present =
        subRecords.where((r) => r.status.name == 'present').length;
    final absent = subRecords.where((r) => r.status.name == 'absent').length;
    final late = subRecords.where((r) => r.status.name == 'late').length;
    final excused =
        subRecords.where((r) => r.status.name == 'excused').length;

    return SubjectAttendance(
      subjectId: sub.id,
      subjectName: sub.name,
      subjectCode: sub.code,
      teacherName: teacherName,
      credits: sub.credits,
      totalClasses: subRecords.length,
      present: present,
      absent: absent,
      late: late,
      excused: excused,
      currentStreak: present > 0 ? 1 : 0,
    );
  }).toList();
});

final overallAttendanceProvider = Provider<double>((ref) {
  final subjects = ref.watch(subjectAttendanceProvider);
  if (subjects.isEmpty) return 0.0;
  int totalPresent = 0;
  int totalClasses = 0;
  for (final sa in subjects) {
    totalPresent += sa.present + sa.late;
    totalClasses += sa.totalClasses;
  }
  return totalClasses > 0 ? (totalPresent / totalClasses) * 100 : 0.0;
});

final todayScheduleProvider =
    StreamProvider<List<ClassScheduleEntry>>((ref) {
  final student = ref.watch(studentProfileProvider);
  if (student == null) return Stream.value([]);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService
      .streamSchedule(student.courseId, student.batchId)
      .map((list) => list.map((m) => ClassScheduleEntry.fromJson(m)).toList());
});

final attendanceStreakProvider = Provider<int>((ref) {
  final recordsAsync = ref.watch(studentAttendanceRecordsProvider);
  final records = recordsAsync.valueOrNull ?? [];
  if (records.isEmpty) return 0;

  final recordsByDay = <DateTime, bool>{};
  for (final r in records) {
    final date = DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day);
    final isPresent = (r.status.name == 'present' || r.status.name == 'late');
    if (!recordsByDay.containsKey(date) || isPresent) {
      recordsByDay[date] = isPresent || (recordsByDay[date] ?? false);
    }
  }

  final sortedDays = recordsByDay.keys.toList()..sort((a, b) => b.compareTo(a));
  
  int streak = 0;
  for (final day in sortedDays) {
    if (recordsByDay[day] == true) {
      streak++;
    } else {
      break;
    }
  }

  // Enforce the 3-day minimum streak eligibility rule
  return streak >= 3 ? streak : 0;
});

// ══════════════════════════════════════════════════════════════════════
// TEACHER DATA
// ══════════════════════════════════════════════════════════════════════

final teacherProfileProvider =
    StateNotifierProvider<TeacherProfileNotifier, TeacherModel?>((ref) {
  final user = ref.watch(authStateProvider);
  return TeacherProfileNotifier(ref, user);
});

class TeacherProfileNotifier extends StateNotifier<TeacherModel?> {
  final Ref _ref;
  final UserModel? _user;
  TeacherProfileNotifier(this._ref, this._user) : super(null) {
    if (_user != null && _user.role == UserRole.teacher) {
      _load(_user.id);
    }
  }

  Future<void> _load(String uid) async {
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      final profile = await firestoreService.getTeacherProfile(uid);
      if (profile != null) {
        state = profile;
      }
    } catch (e) {
      debugPrint('TeacherProfileNotifier: Firestore getTeacherProfile failed: $e');
    }
  }

  Future<void> refresh() async {
    if (_user != null) {
      await _load(_user.id);
    }
  }
}

final teacherSubjectsProvider = Provider<List<SubjectModel>>((ref) {
  final teacher = ref.watch(teacherProfileProvider);
  if (teacher == null) return [];

  final allSubjects = ref.watch(subjectsProvider).valueOrNull ?? [];
  return allSubjects
      .where((s) =>
          teacher.subjectIds.contains(s.id) ||
          s.teacherId == teacher.user.id ||
          (s.teacherId.isNotEmpty && s.teacherId == teacher.employeeId))
      .toList();
});

// ══════════════════════════════════════════════════════════════════════
// CAMPUS ACTIVITIES & CIRCULARS
// ══════════════════════════════════════════════════════════════════════

final activitiesStreamProvider = StreamProvider<List<ActivityPostModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamApprovedActivities();
});

final pendingActivitiesStreamProvider =
    StreamProvider<List<ActivityPostModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamPendingActivities();
});

final circularsStreamProvider = StreamProvider<List<CircularModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamCirculars();
});

final circularsProvider = Provider<List<CircularModel>>((ref) {
  return ref.watch(circularsStreamProvider).valueOrNull ?? [];
});

// ══════════════════════════════════════════════════════════════════════
// EVENTS
// ══════════════════════════════════════════════════════════════════════

final eventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamEvents();
});

final eventsProvider = Provider<List<EventModel>>((ref) {
  return ref.watch(eventsStreamProvider).valueOrNull ?? [];
});

final upcomingEventsProvider = Provider<List<EventModel>>((ref) {
  return ref.watch(eventsProvider).where((e) => e.isUpcoming).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
});

// ══════════════════════════════════════════════════════════════════════
// NOTIFICATIONS
// ══════════════════════════════════════════════════════════════════════

final notificationsStreamProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(authStateProvider);
  if (user == null) return Stream.value([]);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamNotifications(user.id);
});

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
        (ref) {
  final streamData = ref.watch(notificationsStreamProvider);
  return NotificationsNotifier(ref, streamData.valueOrNull ?? []);
});

class NotificationsNotifier extends StateNotifier<List<NotificationModel>> {
  final Ref _ref;
  NotificationsNotifier(this._ref, List<NotificationModel> initial)
      : super(initial);

  int get unreadCount => state.where((n) => !n.isRead).length;

  void markAsRead(String id) {
    final firestoreService = _ref.read(firestoreServiceProvider);
    firestoreService.markNotificationRead(id);
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    final user = _ref.read(authStateProvider);
    if (user != null) {
      final firestoreService = _ref.read(firestoreServiceProvider);
      firestoreService.markAllNotificationsRead(user.id);
    }
    state = [for (final n in state) n.copyWith(isRead: true)];
  }
}

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});

// ══════════════════════════════════════════════════════════════════════
// LEADERBOARD
// ══════════════════════════════════════════════════════════════════════

final leaderboardStreamProvider =
    StreamProvider<List<LeaderboardEntryModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamLeaderboard();
});

final leaderboardProvider = Provider<List<LeaderboardEntryModel>>((ref) {
  return ref.watch(leaderboardStreamProvider).valueOrNull ?? [];
});

// ══════════════════════════════════════════════════════════════════════
// COURSES & SUBJECTS
// ══════════════════════════════════════════════════════════════════════

final coursesProvider = StreamProvider<List<CourseModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamCourses();
});

final subjectsProvider = StreamProvider<List<SubjectModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamSubjects();
});

final batchesProvider = StreamProvider<List<BatchModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamBatches();
});

// ══════════════════════════════════════════════════════════════════════
// ADMIN
// ══════════════════════════════════════════════════════════════════════

final firestoreStudentsStreamProvider =
    StreamProvider<List<StudentModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamAllStudents();
});

final allStudentsProvider = Provider<List<StudentModel>>((ref) {
  return ref.watch(firestoreStudentsStreamProvider).value ?? [];
});

final firestoreTeachersStreamProvider =
    StreamProvider<List<TeacherModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamAllTeachers();
});

final allTeachersProvider = Provider<List<TeacherModel>>((ref) {
  return ref.watch(firestoreTeachersStreamProvider).value ?? [];
});

final attendancePoliciesStreamProvider =
    StreamProvider<List<AttendancePolicyModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamAttendancePolicies();
});

final attendancePoliciesProvider =
    Provider<List<AttendancePolicyModel>>((ref) {
  return ref.watch(attendancePoliciesStreamProvider).value ?? [];
});

final auditLogsStreamProvider = StreamProvider<List<AuditLogModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamAuditLogs();
});

final auditLogsProvider = Provider<List<AuditLogModel>>((ref) {
  return ref.watch(auditLogsStreamProvider).value ?? [];
});

// ══════════════════════════════════════════════════════════════════════
// ATTENDANCE SESSIONS (Teacher)
// ══════════════════════════════════════════════════════════════════════

final activeAttendanceSessionProvider =
    StateNotifierProvider<AttendanceSessionNotifier, AttendanceSessionModel?>(
        (ref) {
  return AttendanceSessionNotifier();
});

class AttendanceSessionNotifier
    extends StateNotifier<AttendanceSessionModel?> {
  AttendanceSessionNotifier() : super(null);

  int _liveCount = 0;
  int get liveCount => _liveCount;

  void startSession(AttendanceSessionModel session) {
    state = session;
    _liveCount = 0;
  }

  void closeSession() {
    if (state != null) {
      state = state!.copyWith(isActive: false);
    }
  }

  void incrementLiveCount() {
    _liveCount++;
    if (state != null) {
      state = state!.copyWith(id: state!.id);
    }
  }
}

final currentUserProvider = authStateProvider;

final allActiveSessionsStreamProvider =
    StreamProvider<List<AttendanceSessionModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamActiveAttendanceSessions();
});

final allActiveSessionsProvider =
    Provider<List<AttendanceSessionModel>>((ref) {
  return ref.watch(allActiveSessionsStreamProvider).valueOrNull ?? [];
});

