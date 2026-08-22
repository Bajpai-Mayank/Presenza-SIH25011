import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/models/app_models.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/data/models/course_model.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/data/models/auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:presenza/data/services/firestore_service.dart';
import 'package:presenza/data/services/auth_service.dart';

// ══════════════════════════════════════════════════════════════════════
// THEME
// ══════════════════════════════════════════════════════════════════════

/// Persisted theme mode.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('themeMode') ?? 'dark';
    state = ThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => ThemeMode.dark,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
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

/// Authentication state — holds the current [AuthState] with status tracking.
final authStateProvider =
    StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier(ref);
});

/// Detailed auth status for routing decisions.
final authStatusProvider =
    StateNotifierProvider<AuthStatusNotifier, AuthState>((ref) {
  return AuthStatusNotifier(ref);
});

class AuthStatusNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  AuthStatusNotifier(this._ref) : super(const AuthState.initializing()) {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        state = const AuthState.unauthenticated();
      } else {
        try {
          final firestoreService = _ref.read(firestoreServiceProvider);
          final userModel = await firestoreService.getUserModel(user.uid);
          if (userModel != null) {
            state = AuthState.authenticated(userModel);
          } else {
            state = const AuthState.profileMissing();
          }
        } catch (e) {
          debugPrint('AuthStatusNotifier: Failed to load profile: $e');
          state = AuthState.error(
            'Failed to load your profile. Please try again.',
          );
        }
      }
    });
  }

  /// Refresh the user profile from Firestore.
  Future<void> refreshProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = const AuthState.unauthenticated();
      return;
    }
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
}

class AuthNotifier extends StateNotifier<UserModel?> {
  final Ref _ref;
  AuthNotifier(this._ref) : super(null) {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        state = null;
      } else {
        try {
          final firestoreService = _ref.read(firestoreServiceProvider);
          final userModel = await firestoreService.getUserModel(user.uid);
          if (userModel != null) {
            state = userModel;
            return;
          }
        } catch (e) {
          debugPrint('AuthNotifier: Firestore getUserModel failed: $e');
        }
        // No fallback — if Firestore profile doesn't exist, state stays null.
        // The router will redirect to the no-profile screen.
        state = null;
      }
    });
  }

  /// Login with email/password using Firebase Auth.
  /// Returns an error message on failure, or null on success.
  Future<String?> login(String email, String password) async {
    final authService = _ref.read(authServiceProvider);
    final result = await authService.signIn(email: email, password: password);
    if (result.success) {
      return null; // Auth state listener will update the state.
    }
    return result.errorMessage;
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}

/// Current user's role.
final currentRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authStateProvider)?.role;
});

// ══════════════════════════════════════════════════════════════════════
// STUDENT DATA
// ══════════════════════════════════════════════════════════════════════

/// Current student profile (if role == student).
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
      // If profile is null, state remains null — UI handles this.
    } catch (e) {
      debugPrint('StudentProfileNotifier: Firestore getStudentProfile failed: $e');
    }
  }
}

/// Stream student attendance records.
final studentAttendanceRecordsProvider =
    StreamProvider<List<AttendanceRecordModel>>((ref) {
  final student = ref.watch(studentProfileProvider);
  if (student == null) return Stream.value([]);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamStudentAttendanceRecords(student.user.id);
});

/// Subject attendance for current student — fully Firestore-backed.
final subjectAttendanceProvider = Provider<List<SubjectAttendance>>((ref) {
  final student = ref.watch(studentProfileProvider);
  if (student == null) return [];

  final subjects = ref.watch(subjectsProvider).value ?? [];
  final recordsAsync = ref.watch(studentAttendanceRecordsProvider);
  final records = recordsAsync.value ?? [];

  // Filter subjects for student's course
  final studentSubjects =
      subjects.where((sub) => sub.courseId == student.courseId).toList();

  // Group records by subject
  final Map<String, List<AttendanceRecordModel>> grouped = {};
  for (final r in records) {
    grouped.putIfAbsent(r.subjectId, () => []).add(r);
  }

  return studentSubjects.map((sub) {
    final subRecords = grouped[sub.id] ?? [];

    if (subRecords.isEmpty) {
      return SubjectAttendance(
        subjectId: sub.id,
        subjectName: sub.name,
        subjectCode: sub.code,
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
      totalClasses: subRecords.length,
      present: present,
      absent: absent,
      late: late,
      excused: excused,
      currentStreak: present > 0 ? 1 : 0,
    );
  }).toList();
});

/// Overall attendance percentage.
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

/// Today's class schedule — Firestore-backed.
final todayScheduleProvider =
    StreamProvider<List<ClassScheduleEntry>>((ref) {
  final student = ref.watch(studentProfileProvider);
  if (student == null) return Stream.value([]);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService
      .streamSchedule(student.courseId, student.batchId)
      .map((list) => list.map((m) => ClassScheduleEntry.fromJson(m)).toList());
});

/// Current attendance streak — computed from attendance records.
final attendanceStreakProvider = Provider<int>((ref) {
  final recordsAsync = ref.watch(studentAttendanceRecordsProvider);
  final records = recordsAsync.valueOrNull ?? [];
  if (records.isEmpty) return 0;

  // Sort by timestamp descending
  final sorted = List<AttendanceRecordModel>.from(records)
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  int streak = 0;
  for (final record in sorted) {
    if (record.status.name == 'present' || record.status.name == 'late') {
      streak++;
    } else {
      break;
    }
  }
  return streak;
});

// ══════════════════════════════════════════════════════════════════════
// TEACHER DATA
// ══════════════════════════════════════════════════════════════════════

/// Current teacher profile (if role == teacher).
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
}

/// Teacher's subjects — Firestore-backed.
final teacherSubjectsProvider = Provider<List<SubjectModel>>((ref) {
  final teacher = ref.watch(teacherProfileProvider);
  if (teacher == null) return [];

  final allSubjects = ref.watch(subjectsProvider).valueOrNull ?? [];
  return allSubjects
      .where((s) => teacher.subjectIds.contains(s.id))
      .toList();
});

// ══════════════════════════════════════════════════════════════════════
// CIRCULARS
// ══════════════════════════════════════════════════════════════════════

final circularsStreamProvider = StreamProvider<List<CircularModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamCirculars();
});

final circularsProvider =
    StateNotifierProvider<CircularsNotifier, List<CircularModel>>((ref) {
  final streamData = ref.watch(circularsStreamProvider);
  return CircularsNotifier(streamData.valueOrNull ?? []);
});

class CircularsNotifier extends StateNotifier<List<CircularModel>> {
  CircularsNotifier(super.initial);

  final Set<String> _readIds = {};
  final Set<String> _bookmarkedIds = {};

  bool isRead(String id) => _readIds.contains(id);
  bool isBookmarked(String id) => _bookmarkedIds.contains(id);

  void markAsRead(String id) {
    _readIds.add(id);
    state = [...state]; // Trigger rebuild
  }

  void toggleBookmark(String id) {
    if (_bookmarkedIds.contains(id)) {
      _bookmarkedIds.remove(id);
    } else {
      _bookmarkedIds.add(id);
    }
    state = [...state];
  }

  /// Update the list when Firestore stream emits new data.
  void updateFromStream(List<CircularModel> circulars) {
    state = circulars;
  }
}

/// Read status accessor.
final circularReadStatusProvider = Provider.family<bool, String>((ref, id) {
  ref.watch(circularsProvider); // Ensure rebuild on state change
  return ref.read(circularsProvider.notifier).isRead(id);
});

final circularBookmarkStatusProvider =
    Provider.family<bool, String>((ref, id) {
  ref.watch(circularsProvider);
  return ref.read(circularsProvider.notifier).isBookmarked(id);
});

// ══════════════════════════════════════════════════════════════════════
// EVENTS
// ══════════════════════════════════════════════════════════════════════

final eventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamEvents();
});

final eventsProvider = Provider<List<EventModel>>((ref) {
  final streamData = ref.watch(eventsStreamProvider);
  return streamData.valueOrNull ?? [];
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
  final streamData = ref.watch(leaderboardStreamProvider);
  return streamData.valueOrNull ?? [];
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
  final asyncVal = ref.watch(firestoreStudentsStreamProvider);
  return asyncVal.value ?? [];
});

final firestoreTeachersStreamProvider =
    StreamProvider<List<TeacherModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamAllTeachers();
});

final allTeachersProvider = Provider<List<TeacherModel>>((ref) {
  final asyncVal = ref.watch(firestoreTeachersStreamProvider);
  return asyncVal.value ?? [];
});

final attendancePoliciesStreamProvider =
    StreamProvider<List<AttendancePolicyModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamAttendancePolicies();
});

final attendancePoliciesProvider =
    Provider<List<AttendancePolicyModel>>((ref) {
  final streamData = ref.watch(attendancePoliciesStreamProvider);
  return streamData.value ?? [];
});

final auditLogsStreamProvider = StreamProvider<List<AuditLogModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamAuditLogs();
});

final auditLogsProvider = Provider<List<AuditLogModel>>((ref) {
  final streamData = ref.watch(auditLogsStreamProvider);
  return streamData.value ?? [];
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
    // Force a state change to trigger UI rebuilds
    if (state != null) {
      state = state!.copyWith(id: state!.id);
    }
  }
}
