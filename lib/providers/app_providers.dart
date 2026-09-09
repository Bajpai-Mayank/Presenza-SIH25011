import 'dart:async';
import 'dart:math' as math;
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
import 'package:presenza/data/models/profile_update_request_model.dart';
import 'package:presenza/data/models/auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:presenza/data/services/firestore_service.dart';
import 'package:presenza/data/services/auth_service.dart';
import 'package:presenza/data/services/notification_service.dart';
import 'package:presenza/core/constants/academic_defaults.dart';
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

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authStatusProvider,
      (_, _) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));

class AuthStatusNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  StreamSubscription? _authSubscription;
  StreamSubscription? _sessionSubscription;

  AuthStatusNotifier(this._ref) : super(_initialAuthState()) {
    _init();
  }

  static AuthState _initialAuthState() {
    final currentFirebaseUser = FirebaseAuth.instance.currentUser;
    if (currentFirebaseUser != null) {
      return const AuthState.fetchingProfile();
    }
    return const AuthState.initializing();
  }

  void _init() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      _sessionSubscription?.cancel();
      if (user == null) {
        state = const AuthState.unauthenticated();
      } else {
        if (!state.isAuthenticated) {
          state = const AuthState.fetchingProfile();
        }
        try {
          final firestoreService = _ref.read(firestoreServiceProvider);
          final userModel = await firestoreService.resolveUserProfile(user).timeout(
            const Duration(seconds: 12),
          );
          
          state = AuthState.authenticated(userModel);
          NotificationService().syncUserToken(user.uid);
          firestoreService.updateUserActivity(user.uid, isOnline: true);
          _monitorSession(firestoreService);
        } catch (e) {
          debugPrint('AuthStatusNotifier: Failed to resolve profile: $e');
          final email = (user.email ?? '').trim().toLowerCase();
          UserRole role;
          if (email == 'admin@presenza.edu' || email.startsWith('admin@')) {
            role = UserRole.admin;
          } else if (email.contains('faculty') || email.contains('teacher') || email.contains('prof')) {
            role = UserRole.teacher;
          } else {
            role = UserRole.student;
          }
          final fallback = UserModel(
            id: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? (email.isNotEmpty ? email.split('@').first : 'User'),
            role: role,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          state = AuthState.authenticated(fallback);
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
          if (session != null && !session.isActive) {
            // Session explicitly deactivated by another login
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
    final firestoreService = _ref.read(firestoreServiceProvider);
    
    try {
      final result = await authService.signIn(email: email, password: password).timeout(
        const Duration(seconds: 15),
        onTimeout: () => AuthResult.error('Login timed out. Please check your internet connection.'),
      );
      
      if (result.success && result.user != null) {
        // Resolve the authentic user profile from Firestore BEFORE reporting login success
        state = const AuthState.fetchingProfile();
        try {
          final userModel = await firestoreService.resolveUserProfile(result.user!).timeout(
            const Duration(seconds: 10),
          );
          state = AuthState.authenticated(userModel);
        } catch (e) {
          debugPrint('Login profile resolution warning: $e');
        }

        final prefs = await SharedPreferences.getInstance();
        String? deviceId = prefs.getString('persistent_device_id');
        if (deviceId == null) {
          deviceId = const Uuid().v4();
          await prefs.setString('persistent_device_id', deviceId);
        }

        // Register active session & deactivate old sessions smoothly
        await _performSessionBookkeeping(result.user!.uid, deviceId);
        return null; // success
      }
      state = const AuthState.unauthenticated(); // Reset on error
      return result.errorMessage ?? 'Invalid email or password.';
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
        firestoreService.recordUserLogin(uid),
      ]);
    } catch (e) {
      debugPrint('Session bookkeeping failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final firestoreService = _ref.read(firestoreServiceProvider);
      if (uid != null) {
        await firestoreService.updateUserOnlineStatus(uid, false);
      }
      final prefs = await SharedPreferences.getInstance();
      final activeSessionId = prefs.getString('active_session_id');
      if (activeSessionId != null) {
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
    // Only transition to fetchingProfile if not already authenticated,
    // avoiding destructive tear down of current screens / shell widgets.
    if (!state.isAuthenticated) {
      state = const AuthState.fetchingProfile();
    }
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      final userModel = await firestoreService.resolveUserProfile(user);
      state = AuthState.authenticated(userModel);
    } catch (e) {
      debugPrint('AuthStatusNotifier: Failed to refresh profile: $e');
      if (!state.isAuthenticated) {
        state = AuthState.error('Failed to refresh profile: $e');
      }
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
      final profile = await firestoreService.getStudentProfile(uid).timeout(
        const Duration(seconds: 8),
        onTimeout: () => null,
      );
      if (profile != null) {
        state = profile;
      } else if (_user != null) {
        // Fallback synthesize student profile from _user so dashboard loads instantly
        final fallbackStudent = StudentModel(
          user: _user,
          studentId: 'STU-${_user.id.length >= 6 ? _user.id.substring(0, 6).toUpperCase() : "001"}',
          courseId: 'course-btech-cse',
          batchId: 'batch-2024-a',
          semester: 1,
          enrollmentDate: DateTime.now(),
        );
        state = fallbackStudent;
        try {
          await firestoreService.saveStudentProfile(fallbackStudent);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('StudentProfileNotifier: Firestore getStudentProfile failed: $e');
      if (_user != null && state == null) {
        state = StudentModel(
          user: _user,
          studentId: 'STU-${_user.id.length >= 6 ? _user.id.substring(0, 6).toUpperCase() : "001"}',
          courseId: 'course-btech-cse',
          batchId: 'batch-2024-a',
          semester: 1,
          enrollmentDate: DateTime.now(),
        );
      }
    }
  }

  Future<void> refresh() async {
    if (_user != null) {
      await _load(_user.id);
    }
  }

  void updateUserData({String? name, String? bio, String? phone, String? avatarUrl}) {
    if (state != null) {
      final updatedUser = state!.user.copyWith(
        name: name,
        bio: bio,
        phone: phone,
        avatarUrl: avatarUrl,
        updatedAt: DateTime.now(),
      );
      state = state!.copyWith(user: updatedUser);
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

final studentBatchSessionsProvider =
    StreamProvider<List<AttendanceSessionModel>>((ref) {
  final student = ref.watch(studentProfileProvider);
  if (student == null) return Stream.value([]);
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.streamAllSessionsForBatch(student.courseId, student.batchId);
});

final subjectAttendanceProvider = Provider<List<SubjectAttendance>>((ref) {
  final student = ref.watch(studentProfileProvider);
  if (student == null) return [];

  final subjects = ref.watch(subjectsProvider).value ?? [];
  final teachers = ref.watch(allTeachersProvider);
  final recordsAsync = ref.watch(studentAttendanceRecordsProvider);
  final records = recordsAsync.value ?? [];
  final allSessions = ref.watch(studentBatchSessionsProvider).value ?? [];

  final studentSubjects =
      subjects.where((sub) => sub.courseId == student.courseId).toList();

  final Map<String, List<AttendanceRecordModel>> grouped = {};
  for (final r in records) {
    grouped.putIfAbsent(r.subjectId, () => []).add(r);
  }

  // Count concluded sessions for this batch by subject
  final Map<String, int> conductedSessionsBySubject = {};
  for (final s in allSessions) {
    if (!s.isActive || s.isExpired) {
      conductedSessionsBySubject[s.subjectId] =
          (conductedSessionsBySubject[s.subjectId] ?? 0) + 1;
    }
  }

  return studentSubjects.map((sub) {
    final subRecords = grouped[sub.id] ?? [];
    final teacherName = teachers
        .where((t) => t.user.id == sub.teacherId || t.employeeId == sub.teacherId)
        .firstOrNull
        ?.user
        .name;

    final presentCount =
        subRecords.where((r) => r.status.name == 'present').length;
    final lateCount =
        subRecords.where((r) => r.status.name == 'late').length;
    final recordedAbsentCount =
        subRecords.where((r) => r.status.name == 'absent').length;
    final excusedCount =
        subRecords.where((r) => r.status.name == 'excused').length;

    // Total sessions conducted by faculty for this subject
    final totalConducted = conductedSessionsBySubject[sub.id] ?? 0;
    // Unscanned sessions are treated as absents
    final unattendedConcluded =
        math.max(0, totalConducted - (presentCount + lateCount + excusedCount));
    final absentCount =
        math.max(recordedAbsentCount, unattendedConcluded);

    final totalClasses =
        math.max(subRecords.length, presentCount + lateCount + excusedCount + absentCount);

    if (totalClasses == 0) {
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

    return SubjectAttendance(
      subjectId: sub.id,
      subjectName: sub.name,
      subjectCode: sub.code,
      teacherName: teacherName,
      credits: sub.credits,
      totalClasses: totalClasses,
      present: presentCount,
      absent: absentCount,
      late: lateCount,
      excused: excusedCount,
      currentStreak: presentCount > 0 ? 1 : 0,
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

  void updateUserData({String? name, String? bio, String? phone, String? avatarUrl}) {
    if (state != null) {
      final updatedUser = state!.user.copyWith(
        name: name,
        bio: bio,
        phone: phone,
        avatarUrl: avatarUrl,
        updatedAt: DateTime.now(),
      );
      state = state!.copyWith(user: updatedUser);
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

final userActivitiesStreamProvider =
    StreamProvider.family<List<ActivityPostModel>, String>((ref, userId) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.streamActivitiesForUser(userId);
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
  final initialData = ref.watch(notificationsStreamProvider).valueOrNull ?? [];
  final notifier = NotificationsNotifier(ref, initialData);
  ref.listen<AsyncValue<List<NotificationModel>>>(
    notificationsStreamProvider,
    (_, next) {
      if (next.hasValue && next.value != null) {
        notifier.updateFromStream(next.value!);
      }
    },
  );
  return notifier;
});

class NotificationsNotifier extends StateNotifier<List<NotificationModel>> {
  final Ref _ref;
  final Set<String> _seenNotificationIds = {};

  NotificationsNotifier(this._ref, List<NotificationModel> initial)
      : super(initial) {
    for (final n in initial) {
      _seenNotificationIds.add(n.id);
    }
  }

  void updateFromStream(List<NotificationModel> incoming) {
    for (final n in incoming) {
      if (!_seenNotificationIds.contains(n.id)) {
        _seenNotificationIds.add(n.id);
        if (!n.isRead) {
          final age = DateTime.now().difference(n.createdAt);
          if (age.inMinutes < 5) {
            NotificationService().showInAppNotification(
              title: n.title,
              body: n.body,
              data: {'id': n.id, 'type': n.type.name},
            );
          }
        }
      }
    }
    state = incoming;
  }

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

/// Combined provider that merges standard academic catalogue defaults with live Firestore courses.
final allCoursesCatalogProvider = Provider<List<CourseModel>>((ref) {
  final firestoreCourses = ref.watch(coursesProvider).valueOrNull ?? [];
  final Map<String, CourseModel> courseMap = {
    for (final c in AcademicDefaults.defaultCourses) c.id: c,
    for (final c in firestoreCourses) c.id: c,
  };
  return courseMap.values.toList();
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

  void markExpired() {
    if (state != null) {
      state = state!.copyWith(isActive: false);
    }
  }

  void clearSession() {
    state = null;
    _liveCount = 0;
  }

  void incrementLiveCount() {
    _liveCount++;
    if (state != null) {
      state = state!.copyWith(id: state!.id);
    }
  }
}

final teacherActiveSessionStreamProvider =
    StreamProvider<AttendanceSessionModel?>((ref) {
  final teacher = ref.watch(teacherProfileProvider);
  if (teacher == null) return Stream.value(null);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamActiveTeacherSession(teacher.user.id);
});

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

// ══════════════════════════════════════════════════════════════════════
// PROFILE UPDATE REQUESTS (TEACHER APPROVAL WORKFLOW)
// ══════════════════════════════════════════════════════════════════════

final pendingProfileRequestsStreamProvider =
    StreamProvider<List<ProfileUpdateRequestModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.streamPendingProfileRequests();
});

final pendingProfileRequestsProvider =
    Provider<List<ProfileUpdateRequestModel>>((ref) {
  return ref.watch(pendingProfileRequestsStreamProvider).valueOrNull ?? [];
});

final studentProfileRequestStreamProvider =
    StreamProvider<ProfileUpdateRequestModel?>((ref) {
  final student = ref.watch(studentProfileProvider);
  if (student == null) return Stream.value(null);
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.streamStudentProfileRequest(student.user.id);
});

