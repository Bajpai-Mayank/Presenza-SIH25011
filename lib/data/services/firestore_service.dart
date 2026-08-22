import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/data/models/app_models.dart';
import 'package:presenza/data/models/course_model.dart';
import 'package:presenza/core/enums/attendance_status.dart';
import 'package:presenza/core/enums/enums.dart';
import 'package:uuid/uuid.dart';

/// Result of a transaction-based attendance marking operation.
class AttendanceResult {
  final bool success;
  final String? errorMessage;
  final AttendanceRecordModel? record;

  const AttendanceResult.success(this.record)
      : success = true,
        errorMessage = null;
  const AttendanceResult.failure(this.errorMessage)
      : success = false,
        record = null;
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _uuid = Uuid();

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
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
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
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AuditLogModel.fromJson(doc.data()))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
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
    return _db
        .collection('schedules')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => doc.data()).toList();
      return list.where((item) => item['batchId'] == batchId).toList();
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

  // ══════════════════════════════════════════════════════════════════════
  // TRANSACTION-BASED ATTENDANCE
  // ══════════════════════════════════════════════════════════════════════

  /// Marks attendance using a Firestore transaction for atomicity.
  ///
  /// Validates: session exists & active, session not expired, student's
  /// course/batch matches, and no duplicate attendance record exists.
  Future<AttendanceResult> markAttendanceWithTransaction({
    required String sessionId,
    required String studentUid,
    required String studentDisplayId,
    required String studentCourseId,
    required String studentBatchId,
    bool locationVerified = false,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final result = await _db.runTransaction<AttendanceResult>((txn) async {
        // 1. Read the session document
        final sessionDoc =
            await txn.get(_db.collection('sessions').doc(sessionId));
        if (!sessionDoc.exists || sessionDoc.data() == null) {
          return const AttendanceResult.failure(
            'No session found for this QR code.',
          );
        }
        final session = AttendanceSessionModel.fromJson(sessionDoc.data()!);

        // 2. Validate session is still active
        if (!session.isActive) {
          return const AttendanceResult.failure(
            'This attendance session has been closed.',
          );
        }

        // 3. Validate session hasn't expired
        if (DateTime.now().isAfter(session.endTime)) {
          return const AttendanceResult.failure(
            'This attendance session has expired.',
          );
        }

        // 4. Validate course and batch
        if (session.courseId != studentCourseId ||
            session.batchId != studentBatchId) {
          return const AttendanceResult.failure(
            'This session is not for your class/batch.',
          );
        }

        // 5. Check for duplicate attendance
        final existingRecords = await _db
            .collection('attendance_records')
            .where('attendanceSessionId', isEqualTo: sessionId)
            .where('studentId', isEqualTo: studentUid)
            .limit(1)
            .get();
        if (existingRecords.docs.isNotEmpty) {
          return const AttendanceResult.failure(
            'You have already marked attendance for this session.',
          );
        }

        // 6. Create the attendance record with a secure UUID
        final now = DateTime.now();
        final recordId = _uuid.v4();
        final record = AttendanceRecordModel(
          id: recordId,
          studentId: studentUid,
          attendanceSessionId: session.id,
          subjectId: session.subjectId,
          courseId: session.courseId,
          teacherId: session.teacherId,
          status: AttendanceStatus.present,
          verificationMethod: VerificationMethod.qr,
          timestamp: now,
          locationVerified: locationVerified,
          faceVerified: false,
          latitude: latitude,
          longitude: longitude,
          createdAt: now,
          updatedAt: now,
        );

        txn.set(
          _db.collection('attendance_records').doc(recordId),
          record.toJson(),
        );

        return AttendanceResult.success(record);
      });

      return result;
    } catch (e) {
      return AttendanceResult.failure('Failed to mark attendance: $e');
    }
  }

  /// Get the number of students enrolled in a specific batch.
  Future<int> getEnrolledStudentCount(String batchId) async {
    final snapshot = await _db
        .collection('students')
        .where('batchId', isEqualTo: batchId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Stream session history for a teacher (all sessions, newest first).
  Stream<List<AttendanceSessionModel>> streamSessionHistory(
      String teacherId) {
    return _db
        .collection('sessions')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AttendanceSessionModel.fromJson(doc.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Convenience: create an audit log entry for admin actions.
  Future<void> logAdminAction({
    required String userId,
    required String userName,
    required String action,
    String entityType = 'USER',
    String entityId = '',
    String? details,
  }) async {
    final id = _uuid.v4();
    final log = AuditLogModel(
      id: id,
      userId: userId,
      userName: userName,
      action: action,
      entityType: entityType,
      entityId: entityId.isNotEmpty ? entityId : id,
      details: details,
      timestamp: DateTime.now(),
    );
    await createAuditLog(log);
  }

  /// Get total attendance records count for computing admin stats.
  Future<Map<String, int>> getAttendanceStats() async {
    final allRecords = await _db.collection('attendance_records').get();
    int totalPresent = 0;
    int totalAbsent = 0;
    int totalLate = 0;
    int total = allRecords.docs.length;

    for (final doc in allRecords.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? '';
      switch (status) {
        case 'present':
          totalPresent++;
          break;
        case 'absent':
          totalAbsent++;
          break;
        case 'late':
          totalLate++;
          break;
      }
    }

    return {
      'total': total,
      'present': totalPresent,
      'absent': totalAbsent,
      'late': totalLate,
    };
  }

  /// Seed initial academic data (courses, batches, subjects, policies) if not already created.
  Future<void> seedInitialAcademicData() async {
    try {
      final coursesSnap = await _db.collection('courses').limit(1).get();
      if (coursesSnap.docs.isEmpty) {
        final now = DateTime.now();
        // 1. Create Default Course
        const course = CourseModel(
          id: 'course-btech-cse',
          name: 'B.Tech Computer Science & Engineering',
          code: 'BTECH-CSE',
          departmentId: 'dept-cse',
          totalSemesters: 8,
        );
        await saveCourse(course);

        // 2. Create Default Batches
        const batchA = BatchModel(
          id: 'batch-2024-a',
          name: 'Batch 2024 - Section A',
          courseId: 'course-btech-cse',
          year: 2024,
          section: 'A',
        );
        const batchB = BatchModel(
          id: 'batch-2024-b',
          name: 'Batch 2024 - Section B',
          courseId: 'course-btech-cse',
          year: 2024,
          section: 'B',
        );
        await saveBatch(batchA);
        await saveBatch(batchB);

        // 3. Create Default Subjects
        const subjects = [
          SubjectModel(
            id: 'sub-cs401',
            name: 'Data Structures & Algorithms',
            code: 'CS401',
            courseId: 'course-btech-cse',
            semester: 4,
            credits: 4,
            teacherId: '',
          ),
          SubjectModel(
            id: 'sub-cs402',
            name: 'Operating Systems',
            code: 'CS402',
            courseId: 'course-btech-cse',
            semester: 4,
            credits: 4,
            teacherId: '',
          ),
          SubjectModel(
            id: 'sub-cs403',
            name: 'Database Management Systems',
            code: 'CS403',
            courseId: 'course-btech-cse',
            semester: 4,
            credits: 3,
            teacherId: '',
          ),
          SubjectModel(
            id: 'sub-cs404',
            name: 'Computer Networks',
            code: 'CS404',
            courseId: 'course-btech-cse',
            semester: 4,
            credits: 3,
            teacherId: '',
          ),
        ];
        for (final sub in subjects) {
          await saveSubject(sub);
        }

        // 4. Create Default Attendance Policy
        const policy = AttendancePolicyModel(
          id: 'policy-cse',
          courseId: 'course-btech-cse',
          minimumAttendancePercent: 75.0,
          qrExpiryMinutes: 5,
          locationRequired: false,
          faceVerificationMode: FaceVerificationMode.disabled,
          campusLat: 28.6139,
          campusLng: 77.2090,
          allowedRadiusMeters: 100.0,
        );
        await saveAttendancePolicy(policy);

        // 5. Create Welcome Circular
        final circular = CircularModel(
          id: _uuid.v4(),
          title: 'Welcome to Presenza Academic Portal',
          content: 'The smart circular and dynamic attendance verification system is live. Students can check schedules and scan class QR codes.',
          category: CircularCategory.academic,
          priority: CircularPriority.important,
          authorId: 'admin',
          authorName: 'Academic Office',
          targetCourseIds: ['course-btech-cse'],
          publishDate: now,
          createdAt: now,
          updatedAt: now,
        );
        await saveCircular(circular);
      }
    } catch (e) {
      // Ignore if offline
    }
  }
}
