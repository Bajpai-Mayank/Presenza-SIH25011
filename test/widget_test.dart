import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:presenza/config/theme/app_colors.dart';
import 'package:presenza/config/theme/app_theme.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/models/activity_model.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/data/models/user_model.dart';
import 'package:presenza/core/services/security_service.dart';
import 'package:presenza/features/auth/screens/register_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

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
        bio: 'CS Student',
        department: 'CSE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(user1.initials, equals('MB'));
      expect(user1.bio, equals('CS Student'));

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
  });

  group('ActivityPostModel Presenza V2 Tests', () {
    test('ActivityPostModel serializes reactions, bookmarks, and interest counts accurately', () {
      final now = DateTime.now();
      final post = ActivityPostModel(
        id: 'act-v2-1',
        title: 'Presenza AI & Cloud Hackathon 2026',
        description: 'Compete in 36-hour challenge build.',
        category: ActivityCategory.hackathon,
        authorId: 'stu-1',
        authorName: 'Alex Rivera',
        authorRole: 'student',
        isOfficial: false,
        status: ActivityStatus.approved,
        reactionCounts: {'like': 12, 'fire': 8},
        userReactions: {'stu-1': 'fire', 'stu-2': 'like'},
        interestedUids: ['stu-1', 'stu-2', 'stu-3'],
        bookmarkedUids: ['stu-1'],
        commentCount: 5,
        createdAt: now,
        updatedAt: now,
      );

      expect(post.totalReactions, equals(20));
      expect(post.isInterested('stu-1'), isTrue);
      expect(post.isInterested('stu-99'), isFalse);
      expect(post.isBookmarked('stu-1'), isTrue);
      expect(post.getUserReaction('stu-1'), equals('fire'));

      final json = post.toJson();
      final restored = ActivityPostModel.fromJson(json);

      expect(restored.id, equals('act-v2-1'));
      expect(restored.category, equals(ActivityCategory.hackathon));
      expect(restored.totalReactions, equals(20));
      expect(restored.interestedUids.length, equals(3));
    });
  });

  group('AppTheme & Presenza Brand System Tests', () {
    test('AppTheme light and dark mode initialize with valid color schemes', () {
      final light = AppTheme.light;
      final dark = AppTheme.dark;

      expect(light.brightness, equals(Brightness.light));
      expect(dark.brightness, equals(Brightness.dark));

      expect(AppColors.primary, equals(const Color(0xFF4F46E5)));
      expect(AppColors.primaryNavy, equals(const Color(0xFF1E3A8A)));
      expect(AppColors.secondary, equals(const Color(0xFF0D9488)));
      expect(AppColors.backgroundDark, equals(const Color(0xFF0B1120)));
    });
  });

  group('RegisterScreen Course & Selection Tests', () {
    testWidgets('RegisterScreen renders fields and selects Course, Year 2026, Section D', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify basic fields exist
      expect(find.textContaining('Account'), findsAtLeast(1));
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Enter Full Name, Email, Password, Confirm Password
      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Nyctophile');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'nycto.moon@sau.edu');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'pass@123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'pass@123');
      await tester.pumpAndSettle();

      // Tap Course picker to open bottom sheet
      expect(find.text('Select Course / Degree Program'), findsOneWidget);
      await tester.tap(find.text('Select Course / Degree Program'));
      await tester.pumpAndSettle();

      // Bottom sheet is open
      expect(find.text('Select Course / Program'), findsOneWidget);
      final searchField = find.widgetWithText(TextField, 'Search course (e.g. BS-MS, CSE, MBA, Law)...');
      expect(searchField, findsOneWidget);

      // Search for BS-MS
      await tester.enterText(searchField, 'BS-MS');
      await tester.pumpAndSettle();

      // Find the BS-MS course in the list and tap it
      expect(find.text('BS-MS Dual Degree (Integrated Sciences)'), findsOneWidget);
      await tester.tap(find.text('BS-MS Dual Degree (Integrated Sciences)'));
      await tester.pumpAndSettle();

      // Verify selected course is shown on the main screen
      expect(find.text('BS-MS Dual Degree (Integrated Sciences)'), findsOneWidget);

      // Test Year picker
      expect(find.text('2026'), findsOneWidget);
      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();
      expect(find.text('Select Admission / Batch Year'), findsOneWidget);
      await tester.tap(find.text('2026').last);
      await tester.pumpAndSettle();

      // Test Section picker
      expect(find.text('Sec D'), findsOneWidget);
      await tester.tap(find.text('Sec D'));
      await tester.pumpAndSettle();
      expect(find.text('Select Section'), findsOneWidget);
      await tester.tap(find.text('Sec D').last);
      await tester.pumpAndSettle();

      // Test Semester chips
      expect(find.text('Sem 1'), findsOneWidget);
      await tester.tap(find.text('Sem 2'));
      await tester.pumpAndSettle();
    });
  });
}






