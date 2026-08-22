import 'package:flutter_test/flutter_test.dart';
import 'package:presenza/core/enums/attendance_status.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/data/models/app_models.dart';

void main() {
  group('SubjectAttendance Model Tests', () {
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

  group('AttendanceSessionModel Tests', () {
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
  });

  group('ClassScheduleEntry Tests', () {
    test('Serializes and deserializes correctly', () {
      final entry = ClassScheduleEntry(
        subjectId: 'sub-1',
        subjectName: 'Computer Networks',
        teacherName: 'Dr. Smith',
        room: 'Lab 3',
        startTime: DateTime(2026, 8, 22, 10, 0),
        endTime: DateTime(2026, 8, 22, 11, 0),
        attendanceStatus: AttendanceStatus.present,
      );

      final json = entry.toJson();
      final restored = ClassScheduleEntry.fromJson(json);

      expect(restored.subjectId, equals('sub-1'));
      expect(restored.subjectName, equals('Computer Networks'));
      expect(restored.teacherName, equals('Dr. Smith'));
      expect(restored.room, equals('Lab 3'));
      expect(restored.attendanceStatus, equals(AttendanceStatus.present));
    });
  });
}
