import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/data/models/app_models.dart';
import 'package:presenza/data/models/course_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ══════════════════════════════════════════════════════════════════════
  // USER PROFILES
  // ══════════════════════════════════════════════════════════════════════

  /// Saves a base user model to the `/users/` collection.
  Future<void> saveUserModel(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toJson());
  }

  /// Fetches a base user model by UID.
  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromJson(doc.data()!);
  }

  /// Updates a user's role (admin operation).
  Future<void> updateUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({
      'role': role,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Saves a student profile.
  Future<void> saveStudentProfile(StudentModel student) async {
    await saveUserModel(student.user);
    await _db.collection('students').doc(student.user.id).set(student.toJson());
  }

  /// Fetches a student profile by UID.
  Future<StudentModel?> getStudentProfile(String uid) async {
    final doc = await _db.collection('students').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return StudentModel.fromJson(doc.data()!);
  }

  /// Saves a teacher profile.
  Future<void> saveTeacherProfile(TeacherModel teacher) async {
    await saveUserModel(teacher.user);
    await _db.collection('teachers').doc(teacher.user.id).set(teacher.toJson());
  }

  /// Fetches a teacher profile by UID.
  Future<TeacherModel?> getTeacherProfile(String uid) async {
    final doc = await _db.collection('teachers').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return TeacherModel.fromJson(doc.data()!);
  }

  // ══════════════════════════════════════════════════════════════════════
  // COURSES, SUBJECTS, BATCHES
  // ══════════════════════════════════════════════════════════════════════

  /// Stream all courses.
  Stream<List<CourseModel>> streamCourses() {
    return _db.collection('courses').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CourseModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Stream all subjects, optionally filtered by courseId.
  Stream<List<SubjectModel>> streamSubjects({String? courseId}) {
    Query<Map<String, dynamic>> query = _db.collection('subjects');
    if (courseId != null) {
      query = query.where('courseId', isEqualTo: courseId);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => SubjectModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Stream all batches, optionally filtered by courseId.
  Stream<List<BatchModel>> streamBatches({String? courseId}) {
    Query<Map<String, dynamic>> query = _db.collection('batches');
    if (courseId != null) {
      query = query.where('courseId', isEqualTo: courseId);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BatchModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Save a course (admin operation).
  Future<void> saveCourse(CourseModel course) async {
    await _db.collection('courses').doc(course.id).set(course.toJson());
  }

  /// Save a subject (admin operation).
  Future<void> saveSubject(SubjectModel subject) async {
    await _db.collection('subjects').doc(subject.id).set(subject.toJson());
  }

  /// Save a batch (admin operation).
  Future<void> saveBatch(BatchModel batch) async {
    await _db.collection('batches').doc(batch.id).set(batch.toJson());
  }

  // ══════════════════════════════════════════════════════════════════════
  // CIRCULARS
  // ══════════════════════════════════════════════════════════════════════

  /// Stream all circulars, ordered by publish date descending.
  Stream<List<CircularModel>> streamCirculars() {
    return _db
        .collection('circulars')
        .orderBy('publishDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CircularModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Save a circular (teacher/admin operation).
  Future<void> saveCircular(CircularModel circular) async {
    await _db.collection('circulars').doc(circular.id).set(circular.toJson());
  }

  // ══════════════════════════════════════════════════════════════════════
  // EVENTS
  // ══════════════════════════════════════════════════════════════════════

  /// Stream all events, ordered by date.
  Stream<List<EventModel>> streamEvents() {
    return _db
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EventModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Save an event (admin operation).
  Future<void> saveEvent(EventModel event) async {
    await _db.collection('events').doc(event.id).set(event.toJson());
  }

  // ══════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════════════

  /// Stream notifications for a specific user, ordered by creation date.
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Mark a notification as read.
  Future<void> markNotificationRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Mark all notifications as read for a user.
  Future<void> markAllNotificationsRead(String userId) async {
    final batch = _db.batch();
    final docs = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in docs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Create a notification (teacher/admin operation).
  Future<void> createNotification(NotificationModel notification) async {
    await _db
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toJson());
  }

  // ══════════════════════════════════════════════════════════════════════
  // LEADERBOARD
  // ══════════════════════════════════════════════════════════════════════

  /// Stream leaderboard entries, optionally filtered by courseId.
  Stream<List<LeaderboardEntryModel>> streamLeaderboard({String? courseId}) {
    Query<Map<String, dynamic>> query = _db.collection('leaderboard');
    if (courseId != null) {
      query = query.where('courseId', isEqualTo: courseId);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => LeaderboardEntryModel.fromJson(doc.data()))
          .toList()
        ..sort((a, b) => a.rank.compareTo(b.rank));
    });
  }

  // ══════════════════════════════════════════════════════════════════════
  // ATTENDANCE POLICIES
  // ══════════════════════════════════════════════════════════════════════

  /// Stream all attendance policies.
  Stream<List<AttendancePolicyModel>> streamAttendancePolicies() {
    return _db.collection('policies').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendancePolicyModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Save an attendance policy (admin operation).
  Future<void> saveAttendancePolicy(AttendancePolicyModel policy) async {
    await _db.collection('policies').doc(policy.id).set(policy.toJson());
  }

  // ══════════════════════════════════════════════════════════════════════
  // AUDIT LOGS
  // ══════════════════════════════════════════════════════════════════════

  /// Stream audit logs, ordered by timestamp descending.
  Stream<List<AuditLogModel>> streamAuditLogs() {
    return _db
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AuditLogModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Create an audit log entry.
  Future<void> createAuditLog(AuditLogModel log) async {
    await _db.collection('audit_logs').doc(log.id).set(log.toJson());
  }

  // ══════════════════════════════════════════════════════════════════════
  // SCHEDULES
  // ══════════════════════════════════════════════════════════════════════

  /// Stream today's schedule for a given course and batch.
  Stream<List<Map<String, dynamic>>> streamSchedule(
      String courseId, String batchId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _db
        .collection('schedules')
        .where('courseId', isEqualTo: courseId)
        .where('batchId', isEqualTo: batchId)
        .where('date', isGreaterThanOrEqualTo: todayStart.toIso8601String())
        .where('date', isLessThan: todayEnd.toIso8601String())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // ══════════════════════════════════════════════════════════════════════
  // ATTENDANCE SESSIONS
  // ══════════════════════════════════════════════════════════════════════

  /// Creates a new attendance session.
  Future<void> createAttendanceSession(AttendanceSessionModel session) async {
    await _db.collection('sessions').doc(session.id).set(session.toJson());
  }

  /// Fetches an attendance session by ID.
  Future<AttendanceSessionModel?> getAttendanceSession(
      String sessionId) async {
    final doc = await _db.collection('sessions').doc(sessionId).get();
    if (!doc.exists || doc.data() == null) return null;
    return AttendanceSessionModel.fromJson(doc.data()!);
  }

  /// Closes an attendance session.
  Future<void> closeAttendanceSession(String sessionId) async {
    await _db
        .collection('sessions')
        .doc(sessionId)
        .update({'isActive': false});
  }

  /// Stream of active attendance sessions generated by a specific teacher.
  Stream<AttendanceSessionModel?> streamActiveTeacherSession(
      String teacherId) {
    return _db
        .collection('sessions')
        .where('teacherId', isEqualTo: teacherId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return AttendanceSessionModel.fromJson(snapshot.docs.first.data());
    });
  }

  /// Stream of active sessions matching a student's course and batch.
  Stream<List<AttendanceSessionModel>> streamActiveSessionsForBatch(
      String courseId, String batchId) {
    return _db
        .collection('sessions')
        .where('courseId', isEqualTo: courseId)
        .where('batchId', isEqualTo: batchId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceSessionModel.fromJson(doc.data()))
          .toList();
    });
  }

  // ══════════════════════════════════════════════════════════════════════
  // ATTENDANCE RECORDS
  // ══════════════════════════════════════════════════════════════════════

  /// Adds a student check-in record.
  Future<void> addAttendanceRecord(AttendanceRecordModel record) async {
    await _db
        .collection('attendance_records')
        .doc(record.id)
        .set(record.toJson());
  }

  /// Stream of attendance records for a session (for teacher live update).
  Stream<List<AttendanceRecordModel>> streamAttendanceRecordsForSession(
      String sessionId) {
    return _db
        .collection('attendance_records')
        .where('attendanceSessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceRecordModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Stream of all attendance records for a specific student.
  Stream<List<AttendanceRecordModel>> streamStudentAttendanceRecords(
      String studentId) {
    return _db
        .collection('attendance_records')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceRecordModel.fromJson(doc.data()))
          .toList();
    });
  }

  // ══════════════════════════════════════════════════════════════════════
  // ADMIN DIRECTORIES
  // ══════════════════════════════════════════════════════════════════════

  /// Stream list of all student profiles.
  Stream<List<StudentModel>> streamAllStudents() {
    return _db.collection('students').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StudentModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Stream list of all teacher profiles.
  Stream<List<TeacherModel>> streamAllTeachers() {
    return _db.collection('teachers').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TeacherModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Stream list of all user profiles (admin operation).
  Stream<List<UserModel>> streamAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    });
  }
}
