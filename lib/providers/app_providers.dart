import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/mock/seed_data.dart';
import 'package:presenza/data/models/app_models.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/data/models/course_model.dart';
import 'package:presenza/data/models/user_model.dart';

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
// AUTHENTICATION
// ══════════════════════════════════════════════════════════════════════

/// Current auth state: null = not logged in, UserModel = logged in.
final authStateProvider =
    StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(null);

  /// Demo login by role.
  Future<void> loginAs(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate API
    switch (role) {
      case UserRole.student:
        state = SeedData.demoStudent.user;
      case UserRole.teacher:
        state = SeedData.demoTeacher.user;
      case UserRole.admin:
        state = SeedData.demoAdmin;
    }
  }

  /// Login with email/password (demo).
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final user = SeedData.users.where((u) => u.email == email).firstOrNull;
    if (user != null) {
      state = user;
      return true;
    }
    return false;
  }

  void logout() => state = null;
}

/// Current user's role.
final currentRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authStateProvider)?.role;
});

// ══════════════════════════════════════════════════════════════════════
// STUDENT DATA
// ══════════════════════════════════════════════════════════════════════

/// Current student profile (if role == student).
final studentProfileProvider = Provider<StudentModel?>((ref) {
  final user = ref.watch(authStateProvider);
  if (user == null || user.role != UserRole.student) return null;
  return SeedData.students.where((s) => s.user.id == user.id).firstOrNull;
});

/// Subject attendance for current student.
final subjectAttendanceProvider = Provider<List<SubjectAttendance>>((ref) {
  final student = ref.watch(studentProfileProvider);
  if (student == null) return [];
  return SeedData.studentAttendance;
});

/// Overall attendance percentage.
final overallAttendanceProvider = Provider<double>((ref) {
  return SeedData.demoStudentOverallAttendance;
});

/// Today's class schedule.
final todayScheduleProvider = Provider<List<ClassScheduleEntry>>((ref) {
  return SeedData.todaySchedule;
});

/// Current attendance streak.
final attendanceStreakProvider = Provider<int>((ref) {
  return SeedData.demoStudentStreak;
});

// ══════════════════════════════════════════════════════════════════════
// TEACHER DATA
// ══════════════════════════════════════════════════════════════════════

/// Current teacher profile (if role == teacher).
final teacherProfileProvider = Provider<TeacherModel?>((ref) {
  final user = ref.watch(authStateProvider);
  if (user == null || user.role != UserRole.teacher) return null;
  return SeedData.teachers.where((t) => t.user.id == user.id).firstOrNull;
});

/// Teacher's subjects.
final teacherSubjectsProvider = Provider<List<SubjectModel>>((ref) {
  final teacher = ref.watch(teacherProfileProvider);
  if (teacher == null) return [];
  return SeedData.subjects
      .where((s) => teacher.subjectIds.contains(s.id))
      .toList();
});

// ══════════════════════════════════════════════════════════════════════
// CIRCULARS
// ══════════════════════════════════════════════════════════════════════

final circularsProvider =
    StateNotifierProvider<CircularsNotifier, List<CircularModel>>((ref) {
  return CircularsNotifier();
});

class CircularsNotifier extends StateNotifier<List<CircularModel>> {
  CircularsNotifier() : super(SeedData.circulars);

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

final eventsProvider = Provider<List<EventModel>>((ref) {
  return SeedData.events;
});

final upcomingEventsProvider = Provider<List<EventModel>>((ref) {
  return ref.watch(eventsProvider).where((e) => e.isUpcoming).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
});

// ══════════════════════════════════════════════════════════════════════
// NOTIFICATIONS
// ══════════════════════════════════════════════════════════════════════

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
        (ref) {
  return NotificationsNotifier();
});

class NotificationsNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationsNotifier() : super(SeedData.notifications);

  int get unreadCount => state.where((n) => !n.isRead).length;

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }
}

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});

// ══════════════════════════════════════════════════════════════════════
// LEADERBOARD
// ══════════════════════════════════════════════════════════════════════

final leaderboardProvider = Provider<List<LeaderboardEntryModel>>((ref) {
  return SeedData.leaderboard;
});

// ══════════════════════════════════════════════════════════════════════
// COURSES & SUBJECTS
// ══════════════════════════════════════════════════════════════════════

final coursesProvider = Provider<List<CourseModel>>((ref) {
  return SeedData.courses;
});

final subjectsProvider = Provider<List<SubjectModel>>((ref) {
  return SeedData.subjects;
});

final batchesProvider = Provider<List<BatchModel>>((ref) {
  return SeedData.batches;
});

// ══════════════════════════════════════════════════════════════════════
// ADMIN
// ══════════════════════════════════════════════════════════════════════

final allStudentsProvider = Provider<List<StudentModel>>((ref) {
  return SeedData.students;
});

final allTeachersProvider = Provider<List<TeacherModel>>((ref) {
  return SeedData.teachers;
});

final attendancePoliciesProvider =
    Provider<List<AttendancePolicyModel>>((ref) {
  return SeedData.policies;
});

final auditLogsProvider = Provider<List<AuditLogModel>>((ref) {
  return SeedData.auditLogs;
});

// ══════════════════════════════════════════════════════════════════════
// ATTENDANCE SESSIONS (Teacher)
// ══════════════════════════════════════════════════════════════════════

final activeAttendanceSessionProvider =
    StateNotifierProvider<AttendanceSessionNotifier, AttendanceSessionModel?>(
        (ref) {
  return AttendanceSessionNotifier();
});

class AttendanceSessionNotifier extends StateNotifier<AttendanceSessionModel?> {
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
