import 'package:flutter_test/flutter_test.dart';
import 'package:presenza/core/enums/enums.dart';
import 'package:presenza/core/enums/attendance_status.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/data/models/app_models.dart';
import 'package:presenza/core/services/security_service.dart';

void main() {
  group('SubjectAttendance Model Tests & Edge Cases', () {
    test('Calculates attendance percentage accurately', () {
      const sa = SubjectAttendance(
        subjectId: 'sub-1',
        subjectName: 'Mathematics',
        subjectCode: 'MATH101',
        totalClasses: 20,
        present: 15,
        absent: 5,
        late: 0,
        excused: 0,
      );

      expect(sa.percentage, equals(75.0));
      expect(sa.isBelowThreshold(75.0), isFalse);
      expect(sa.isBelowThreshold(80.0), isTrue);
    });

    test('Calculates classes needed to reach threshold', () {
      const sa = SubjectAttendance(
        subjectId: 'sub-2',
        subjectName: 'Physics',
        subjectCode: 'PHY101',
        totalClasses: 10,
        present: 5,
        absent: 5,
        late: 0,
        excused: 0,
      );

      // Current is 50%, target is 75%
      // (5 + x) / (10 + x) >= 0.75 => x >= (7.5 - 5) / 0.25 = 10
      expect(sa.classesNeededForThreshold(75.0), equals(10));
    });

    test('Calculates classes can miss before dropping below threshold', () {
      const sa = SubjectAttendance(
        subjectId: 'sub-3',
        subjectName: 'Chemistry',
        subjectCode: 'CHEM101',
        totalClasses: 10,
        present: 10,
        absent: 0,
        late: 0,
        excused: 0,
      );

      // Current is 100%, threshold is 75%
      // 10 / 0.75 - 10 = 13.33 - 10 = 3
      expect(sa.classesCanMiss(75.0), equals(3));
    });

    test('getStatusMessage handles 0 classes cleanly without confusing messages', () {
      const emptySa = SubjectAttendance(
        subjectId: 'sub-zero',
        subjectName: 'Operating Systems',
        subjectCode: 'CS301',
        totalClasses: 0,
        present: 0,
        absent: 0,
        late: 0,
        excused: 0,
      );

      expect(emptySa.percentage, equals(0.0));
      expect(emptySa.getStatusMessage(threshold: 75.0), equals('No classes conducted yet'));
    });

    test('getStatusMessage handles 100% attendance and buffer classes', () {
      const perfectSa = SubjectAttendance(
        subjectId: 'sub-perf',
        subjectName: 'Software Engineering',
        subjectCode: 'CS401',
        totalClasses: 8,
        present: 8,
        absent: 0,
        late: 0,
        excused: 0,
      );

      expect(perfectSa.getStatusMessage(threshold: 75.0), contains('Can miss 2 more classes'));
    });

    test('getStatusMessage handles at-risk attendance correctly', () {
      const atRiskSa = SubjectAttendance(
        subjectId: 'sub-risk',
        subjectName: 'Database Management Systems',
        subjectCode: 'CS302',
        totalClasses: 10,
        present: 5,
        absent: 5,
        late: 0,
        excused: 0,
      );

      expect(atRiskSa.getStatusMessage(threshold: 75.0), contains('Need 10 classes to reach 75%'));
    });
  });

  group('UserModel Tests', () {
    test('Extracts initials correctly for single and multi-word names', () {
      final user1 = UserModel(
        id: 'u1',
        email: 'mayank@test.com',
        name: 'Mayank Bajpai',
        role: UserRole.student,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(user1.initials, equals('MB'));

      final user2 = UserModel(
        id: 'u2',
        email: 'alice@test.com',
        name: 'Alice',
        role: UserRole.teacher,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(user2.initials, equals('A'));
    });
  });

  group('AttendanceSessionModel & AttendanceRecordModel Tests', () {
    test('Correctly identifies expired sessions', () {
      final pastSession = AttendanceSessionModel(
        id: 's1',
        subjectId: 'sub-1',
        teacherId: 't1',
        courseId: 'c1',
        batchId: 'b1',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().subtract(const Duration(hours: 1)),
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(pastSession.isExpired, isTrue);

      final activeSession = AttendanceSessionModel(
        id: 's2',
        subjectId: 'sub-1',
        teacherId: 't1',
        courseId: 'c1',
        batchId: 'b1',
        date: DateTime.now(),
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 15)),
        isActive: true,
        createdAt: DateTime.now(),
      );
      expect(activeSession.isExpired, isFalse);
    });

    test('Serializes session with rich metadata (subjectName, room, teacherName)', () {
      final now = DateTime.now();
      final session = AttendanceSessionModel(
        id: 'session-v2',
        subjectId: 'sub-cloud',
        subjectName: 'Cloud Computing & DevOps',
        subjectCode: 'CS502',
        teacherId: 'teacher-1',
        teacherName: 'Dr. Alan Turing',
        courseId: 'course-btech-cse',
        batchId: 'batch-2024-a',
        room: 'Lab 402',
        date: now,
        startTime: now,
        endTime: now.add(const Duration(minutes: 10)),
        isActive: true,
        createdAt: now,
      );

      final json = session.toJson();
      final restored = AttendanceSessionModel.fromJson(json);

      expect(restored.subjectName, equals('Cloud Computing & DevOps'));
      expect(restored.subjectCode, equals('CS502'));
      expect(restored.teacherName, equals('Dr. Alan Turing'));
      expect(restored.room, equals('Lab 402'));
    });

    test('AttendanceRecordModel stores rich session context', () {
      final now = DateTime.now();
      final record = AttendanceRecordModel(
        id: 'rec-1',
        studentId: 'std-1',
        attendanceSessionId: 'sess-1',
        subjectId: 'sub-1',
        subjectName: 'Algorithms',
        courseId: 'course-btech-cse',
        teacherId: 'teach-1',
        teacherName: 'Prof. Donald Knuth',
        room: 'Hall B',
        status: AttendanceStatus.present,
        verificationMethod: VerificationMethod.qr,
        timestamp: now,
        locationVerified: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = record.toJson();
      final restored = AttendanceRecordModel.fromJson(json);

      expect(restored.subjectName, equals('Algorithms'));
      expect(restored.teacherName, equals('Prof. Donald Knuth'));
      expect(restored.room, equals('Hall B'));
      expect(restored.locationVerified, isTrue);
    });
  });

  group('CircularModel & Activities Tests', () {
    test('Differentiates official announcements from student activities', () {
      final now = DateTime.now();
      final official = CircularModel(
        id: 'circ-1',
        title: 'Mid-term Exams Schedule',
        content: 'Exams begin next week.',
        category: CircularCategory.academic,
        priority: CircularPriority.urgent,
        authorId: 'faculty-1',
        authorName: 'Academic Dean',
        authorRole: 'teacher',
        isOfficial: true,
        publishDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final studentActivity = CircularModel(
        id: 'act-1',
        title: 'Presenza Hackathon 2026',
        content: 'Join team formation meet.',
        category: CircularCategory.events,
        priority: CircularPriority.normal,
        authorId: 'student-1',
        authorName: 'Alex Doe',
        authorRole: 'student',
        isOfficial: false,
        location: 'CS Lab 3',
        organizer: 'Coding Club',
        publishDate: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(official.isOfficial, isTrue);
      expect(official.isUrgent, isTrue);

      expect(studentActivity.isOfficial, isFalse);
      expect(studentActivity.organizer, equals('Coding Club'));
      expect(studentActivity.location, equals('CS Lab 3'));

      final json = studentActivity.toJson();
      final restored = CircularModel.fromJson(json);
      expect(restored.isOfficial, isFalse);
      expect(restored.organizer, equals('Coding Club'));
    });
  });

  group('SecurityService Tests', () {
    test('SecurityService safe execution on non-Android test environment', () async {
      // In host test environment (Windows), it safely returns false without throwing exceptions
      final enabled = await SecurityService.enableScreenshotProtection();
      expect(enabled, isFalse);

      final disabled = await SecurityService.disableScreenshotProtection();
      expect(disabled, isFalse);

      final isProtected = await SecurityService.isProtectionEnabled();
      expect(isProtected, isFalse);
    });
  });
}

