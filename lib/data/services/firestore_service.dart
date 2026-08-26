import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/data/models/app_models.dart';
import 'package:presenza/data/models/activity_model.dart';
import 'package:presenza/data/models/course_model.dart';
import 'package:presenza/core/enums/attendance_status.dart';
import 'package:presenza/core/enums/enums.dart';
import 'package:presenza/data/models/user_session_model.dart';
import 'package:presenza/data/services/supabase_backup_service.dart';
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

/// Provides all Cloud Firestore operations for Presenza.
/// Acts as the primary backend implementation for database access.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SupabaseBackupService _supabaseBackup = SupabaseBackupService();
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

  /// Updates a user's profile info (bio, phone, name, avatar).
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? bio,
    String? phone,
    String? avatarUrl,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name;
    if (bio != null) updates['bio'] = bio;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

    await _db.collection('users').doc(uid).update(updates);

    // Also update nested user document in students/teachers collection if present
    final studentDoc = await _db.collection('students').doc(uid).get();
    if (studentDoc.exists && studentDoc.data() != null) {
      final current = studentDoc.data()!;
      final userMap = Map<String, dynamic>.from(current['user'] as Map? ?? {});
      userMap.addAll(updates);
      await _db.collection('students').doc(uid).update({'user': userMap});
    }

    final teacherDoc = await _db.collection('teachers').doc(uid).get();
    if (teacherDoc.exists && teacherDoc.data() != null) {
      final current = teacherDoc.data()!;
      final userMap = Map<String, dynamic>.from(current['user'] as Map? ?? {});
      userMap.addAll(updates);
      await _db.collection('teachers').doc(uid).update({'user': userMap});
    }
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

  /// Save a subject (admin/teacher operation).
  Future<void> saveSubject(SubjectModel subject) async {
    await _db.collection('subjects').doc(subject.id).set(subject.toJson());
  }

  /// Adds a new subject created by a teacher and associates it with their profile.
  Future<void> addTeacherSubject({
    required String teacherUid,
    required SubjectModel subject,
  }) async {
    await saveSubject(subject);

    final teacherRef = _db.collection('teachers').doc(teacherUid);
    final teacherDoc = await teacherRef.get();
    if (teacherDoc.exists && teacherDoc.data() != null) {
      final currentList = List<String>.from(teacherDoc.data()!['subjectIds'] ?? []);
      if (!currentList.contains(subject.id)) {
        currentList.add(subject.id);
        await teacherRef.update({'subjectIds': currentList});
      }
    }
  }

  /// Save a batch (admin operation).
  Future<void> saveBatch(BatchModel batch) async {
    await _db.collection('batches').doc(batch.id).set(batch.toJson());
  }

  // ══════════════════════════════════════════════════════════════════════
  // CIRCULARS & CAMPUS ACTIVITIES
  // ══════════════════════════════════════════════════════════════════════

  /// Stream all circulars (legacy compatibility).
  Stream<List<CircularModel>> streamCirculars() {
    return _db
        .collection('circulars')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CircularModel.fromJson(doc.data()))
          .toList();
      list.sort((a, b) => b.publishDate.compareTo(a.publishDate));
      return list;
    });
  }

  /// Save a circular.
  Future<void> saveCircular(CircularModel circular) async {
    await _db.collection('circulars').doc(circular.id).set(circular.toJson());
  }

  /// Stream all approved campus activities and official circulars.
  Stream<List<ActivityPostModel>> streamApprovedActivities() {
    return _db.collection('circulars').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ActivityPostModel.fromJson(doc.data()))
          .where((p) => p.status == ActivityStatus.approved || p.isOfficial)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream pending activity submissions (for teacher/admin review).
  Stream<List<ActivityPostModel>> streamPendingActivities() {
    return _db
        .collection('circulars')
        .where('status', isEqualTo: ActivityStatus.pending.name)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ActivityPostModel.fromJson(doc.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Create or update a campus activity post.
  Future<void> saveActivityPost(ActivityPostModel post) async {
    await _db.collection('circulars').doc(post.id).set(post.toJson());
  }

  /// Approve a pending student post.
  Future<void> approveActivityPost(String postId) async {
    await _db.collection('circulars').doc(postId).update({
      'status': ActivityStatus.approved.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Reject a pending student post.
  Future<void> rejectActivityPost(String postId) async {
    await _db.collection('circulars').doc(postId).update({
      'status': ActivityStatus.rejected.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Toggle reaction (like, clap, fire) on an activity post.
  Future<void> toggleReaction({
    required String postId,
    required String userId,
    required String reactionType,
  }) async {
    final docRef = _db.collection('circulars').doc(postId);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      if (!snap.exists || snap.data() == null) return;

      final post = ActivityPostModel.fromJson(snap.data()!);
      final userReactions = Map<String, String>.from(post.userReactions);
      final reactionCounts = Map<String, int>.from(post.reactionCounts);

      final currentReaction = userReactions[userId];
      if (currentReaction == reactionType) {
        // Remove reaction
        userReactions.remove(userId);
        reactionCounts[reactionType] = ((reactionCounts[reactionType] ?? 1) - 1).clamp(0, 99999);
      } else {
        // If user already had a different reaction, decrement it first
        if (currentReaction != null) {
          reactionCounts[currentReaction] =
              ((reactionCounts[currentReaction] ?? 1) - 1).clamp(0, 99999);
        }
        // Set new reaction
        userReactions[userId] = reactionType;
        reactionCounts[reactionType] = (reactionCounts[reactionType] ?? 0) + 1;
      }

      txn.update(docRef, {
        'userReactions': userReactions,
        'reactionCounts': reactionCounts,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  /// Toggle "Interested / Going" for an event post.
  Future<void> toggleInterested({
    required String postId,
    required String userId,
  }) async {
    final docRef = _db.collection('circulars').doc(postId);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      if (!snap.exists || snap.data() == null) return;

      final post = ActivityPostModel.fromJson(snap.data()!);
      final interested = List<String>.from(post.interestedUids);

      if (interested.contains(userId)) {
        interested.remove(userId);
      } else {
        interested.add(userId);
      }

      txn.update(docRef, {
        'interestedUids': interested,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  /// Toggle bookmark for a user on a post.
  Future<void> togglePostBookmark({
    required String postId,
    required String userId,
  }) async {
    final docRef = _db.collection('circulars').doc(postId);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      if (!snap.exists || snap.data() == null) return;

      final post = ActivityPostModel.fromJson(snap.data()!);
      final bookmarks = List<String>.from(post.bookmarkedUids);

      if (bookmarks.contains(userId)) {
        bookmarks.remove(userId);
      } else {
        bookmarks.add(userId);
      }

      txn.update(docRef, {
        'bookmarkedUids': bookmarks,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  /// Stream comments for an activity post.
  Stream<List<ActivityCommentModel>> streamActivityComments(String postId) {
    return _db
        .collection('circulars')
        .doc(postId)
        .collection('comments')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ActivityCommentModel.fromJson(doc.data()))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  /// Add a comment to an activity post.
  Future<void> addActivityComment(ActivityCommentModel comment) async {
    final commentRef = _db
        .collection('circulars')
        .doc(comment.activityId)
        .collection('comments')
        .doc(comment.id);
    final postRef = _db.collection('circulars').doc(comment.activityId);

    await _db.runTransaction((txn) async {
      txn.set(commentRef, comment.toJson());
      txn.update(postRef, {
        'commentCount': FieldValue.increment(1),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  // ══════════════════════════════════════════════════════════════════════
  // EVENTS
  // ══════════════════════════════════════════════════════════════════════

  /// Stream all events, ordered by date.
  Stream<List<EventModel>> streamEvents() {
    return _db.collection('events').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => EventModel.fromJson(doc.data()))
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
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

  /// Create a notification.
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
        ..sort((a, b) {
          final percCmp = b.attendancePercentage.compareTo(a.attendancePercentage);
          if (percCmp != 0) return percCmp;
          final streakCmp = b.streak.compareTo(a.streak);
          if (streakCmp != 0) return streakCmp;
          return a.studentName.compareTo(b.studentName);
        });
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
    return _db.collection('audit_logs').snapshots().map((snapshot) {
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

  /// Stream of all currently active attendance sessions (for admin monitor).
  Stream<List<AttendanceSessionModel>> streamActiveAttendanceSessions() {
    return _db
        .collection('sessions')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceSessionModel.fromJson(doc.data()))
          .toList();
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
            'No active session found for this QR code.',
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
            'This session is for another class/batch.',
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
            'You have already marked attendance for this class.',
          );
        }

        // 6. Create the attendance record
        final now = DateTime.now();
        final recordId = '${sessionId}_$studentUid'; // Deterministic Idempotency
        final record = AttendanceRecordModel(
          id: recordId,
          studentId: studentUid,
          attendanceSessionId: session.id,
          subjectId: session.subjectId,
          subjectName: session.subjectName,
          courseId: session.courseId,
          teacherId: session.teacherId,
          teacherName: session.teacherName,
          room: session.room,
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

      // Trigger Supabase Backup if transaction was successful
      if (result.success && result.record != null) {
        _supabaseBackup.backupAttendanceRecord(result.record!);
      }

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

  /// Seed initial academic data and rich sample activities if not already created.
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
          qrExpiryMinutes: 10,
          locationRequired: false,
          faceVerificationMode: FaceVerificationMode.disabled,
          campusLat: 28.6139,
          campusLng: 77.2090,
          allowedRadiusMeters: 100.0,
        );
        await saveAttendancePolicy(policy);

        // 5. Create Sample Campus Activities
        final initialActivities = [
          ActivityPostModel(
            id: _uuid.v4(),
            title: 'Welcome to Presenza V2 Academic Portal',
            description: 'Presenza V2 is now officially deployed with dynamic attendance verification, interactive campus feeds, and smart schedule integration.',
            category: ActivityCategory.notice,
            authorId: 'admin',
            authorName: 'Academic Office',
            authorRole: 'admin',
            isOfficial: true,
            status: ActivityStatus.approved,
            eventDate: now.add(const Duration(days: 2)),
            location: 'Main Auditorium & Online',
            organizer: 'Office of Dean Academics',
            reactionCounts: {'like': 24, 'clap': 15, 'fire': 9},
            interestedUids: ['admin'],
            commentCount: 2,
            createdAt: now,
            updatedAt: now,
          ),
          ActivityPostModel(
            id: _uuid.v4(),
            title: 'Smart India Hackathon 2025 Internal Round',
            description: 'Registrations are open for the internal college round of SIH 2025. Submit your team details and problem statement proposals by this Friday.',
            category: ActivityCategory.hackathon,
            authorId: 'faculty-01',
            authorName: 'Dr. Robert Lang',
            authorRole: 'teacher',
            isOfficial: true,
            status: ActivityStatus.approved,
            eventDate: now.add(const Duration(days: 5)),
            location: 'Computing Lab 3 & IoT Lab',
            organizer: 'Department of Computer Science',
            reactionCounts: {'like': 42, 'fire': 31, 'clap': 18},
            interestedUids: [],
            commentCount: 5,
            createdAt: now.subtract(const Duration(hours: 4)),
            updatedAt: now,
          ),
          ActivityPostModel(
            id: _uuid.v4(),
            title: 'Hands-on Workshop: Flutter & Mobile Cloud Architecture',
            description: 'Join us for a 3-hour weekend masterclass covering modern Flutter architecture, Riverpod state management, and real-time cloud data pipelines.',
            category: ActivityCategory.workshop,
            authorId: 'student-tech-club',
            authorName: 'Alex Rivera',
            authorRole: 'student',
            isOfficial: false,
            status: ActivityStatus.approved,
            eventDate: now.add(const Duration(days: 7)),
            location: 'Seminar Hall B',
            organizer: 'Developer Student Society',
            reactionCounts: {'like': 19, 'clap': 12},
            interestedUids: [],
            commentCount: 1,
            createdAt: now.subtract(const Duration(hours: 12)),
            updatedAt: now,
          ),
        ];

        for (final act in initialActivities) {
          await saveActivityPost(act);
        }
      }
    } catch (_) {}
  }

  /// Seed sample campus activity announcements.
  Future<void> seedSampleActivities() async {
    await seedInitialAcademicData();
  }

  // ══════════════════════════════════════════════════════════════════════
  // USER SESSIONS (One Account = One Session)
  // ══════════════════════════════════════════════════════════════════════

  /// Creates a new active session for the user.
  Future<void> createUserSession(UserSessionModel session) async {
    await _db.collection('user_sessions').doc(session.sessionId).set(session.toMap());
  }

  /// Invalidates all other active sessions for this user.
  Future<void> invalidateOtherSessions(String userId, String activeSessionId) async {
    final batch = _db.batch();
    final docs = await _db
        .collection('user_sessions')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();
    for (final doc in docs.docs) {
      if (doc.id != activeSessionId) {
        batch.update(doc.reference, {'isActive': false});
      }
    }
    await batch.commit();
  }

  /// Streams a specific session to watch for invalidation.
  Stream<UserSessionModel?> streamUserSession(String sessionId) {
    return _db.collection('user_sessions').doc(sessionId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserSessionModel.fromMap(doc.data()!);
    });
  }

  // ══════════════════════════════════════════════════════════════════════
  // ATTENDANCE CORRECTION
  // ══════════════════════════════════════════════════════════════════════

  /// Administratively correct an attendance record and generate an audit log.
  Future<void> correctAttendanceRecord({
    required String recordId,
    required String studentId,
    required AttendanceStatus newStatus,
    required String reason,
    required String correctedByUid,
    required String correctedByName,
  }) async {
    final recordRef = _db.collection('students').doc(studentId).collection('attendance').doc(recordId);
    
    await _db.runTransaction((txn) async {
      final snap = await txn.get(recordRef);
      if (!snap.exists || snap.data() == null) return;
      
      final oldData = snap.data()!;
      final oldStatus = oldData['status'];
      
      txn.update(recordRef, {
        'status': newStatus.name,
        'locationVerified': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      final auditRef = _db.collection('audit_logs').doc();
      txn.set(auditRef, {
        'type': 'attendance_correction',
        'recordId': recordId,
        'studentId': studentId,
        'oldStatus': oldStatus,
        'newStatus': newStatus.name,
        'reason': reason,
        'correctedByUid': correctedByUid,
        'correctedByName': correctedByName,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }
}
