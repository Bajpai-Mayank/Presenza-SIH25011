import 'package:presenza/core/enums/attendance_status.dart';
import 'package:presenza/core/enums/enums.dart';
import 'package:presenza/core/enums/user_role.dart';
import 'package:presenza/data/models/app_models.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/data/models/course_model.dart';
import 'package:presenza/data/models/user_model.dart';

/// Realistic demo data for the Smart Circular app.
class SeedData {
  SeedData._();

  static final DateTime _now = DateTime.now();
  static DateTime _today(int hour, int minute) =>
      DateTime(_now.year, _now.month, _now.day, hour, minute);
  static DateTime _daysAgo(int days) => _now.subtract(Duration(days: days));

  // ── Users ──────────────────────────────────────────────────────────

  static final List<UserModel> users = [
    // Students
    UserModel(id: 'student-1', email: 'arun.kumar@college.edu', name: 'Arun Kumar', role: UserRole.student, phone: '+91 9876543210', createdAt: _daysAgo(365), updatedAt: _now),
    UserModel(id: 'student-2', email: 'priya.sharma@college.edu', name: 'Priya Sharma', role: UserRole.student, phone: '+91 9876543211', createdAt: _daysAgo(365), updatedAt: _now),
    UserModel(id: 'student-3', email: 'rahul.verma@college.edu', name: 'Rahul Verma', role: UserRole.student, createdAt: _daysAgo(365), updatedAt: _now),
    UserModel(id: 'student-4', email: 'sneha.patel@college.edu', name: 'Sneha Patel', role: UserRole.student, createdAt: _daysAgo(300), updatedAt: _now),
    UserModel(id: 'student-5', email: 'vikram.singh@college.edu', name: 'Vikram Singh', role: UserRole.student, createdAt: _daysAgo(300), updatedAt: _now),
    // Teachers
    UserModel(id: 'teacher-1', email: 'dr.mehta@college.edu', name: 'Dr. Rajesh Mehta', role: UserRole.teacher, phone: '+91 9876500001', createdAt: _daysAgo(730), updatedAt: _now),
    UserModel(id: 'teacher-2', email: 'prof.nair@college.edu', name: 'Prof. Lakshmi Nair', role: UserRole.teacher, phone: '+91 9876500002', createdAt: _daysAgo(730), updatedAt: _now),
    UserModel(id: 'teacher-3', email: 'dr.gupta@college.edu', name: 'Dr. Anita Gupta', role: UserRole.teacher, createdAt: _daysAgo(500), updatedAt: _now),
    // Admin
    UserModel(id: 'admin-1', email: 'admin@college.edu', name: 'Admin User', role: UserRole.admin, createdAt: _daysAgo(1000), updatedAt: _now),
  ];

  // ── Students ────────────────────────────────────────────────────────

  static final List<StudentModel> students = [
    StudentModel(user: users[0], studentId: 'CS2024001', courseId: 'course-1', batchId: 'batch-1', semester: 4, enrollmentDate: _daysAgo(365)),
    StudentModel(user: users[1], studentId: 'CS2024002', courseId: 'course-1', batchId: 'batch-1', semester: 4, enrollmentDate: _daysAgo(365)),
    StudentModel(user: users[2], studentId: 'CS2024003', courseId: 'course-1', batchId: 'batch-1', semester: 4, enrollmentDate: _daysAgo(365)),
    StudentModel(user: users[3], studentId: 'CS2024004', courseId: 'course-1', batchId: 'batch-1', semester: 4, enrollmentDate: _daysAgo(300)),
    StudentModel(user: users[4], studentId: 'EC2024001', courseId: 'course-2', batchId: 'batch-2', semester: 4, enrollmentDate: _daysAgo(300)),
  ];

  // ── Teachers ────────────────────────────────────────────────────────

  static final List<TeacherModel> teachers = [
    TeacherModel(user: users[5], employeeId: 'EMP001', departmentId: 'dept-cs', subjectIds: ['sub-1', 'sub-2']),
    TeacherModel(user: users[6], employeeId: 'EMP002', departmentId: 'dept-cs', subjectIds: ['sub-3', 'sub-4']),
    TeacherModel(user: users[7], employeeId: 'EMP003', departmentId: 'dept-cs', subjectIds: ['sub-5', 'sub-6']),
  ];

  // ── Courses ─────────────────────────────────────────────────────────

  static const List<CourseModel> courses = [
    CourseModel(id: 'course-1', name: 'Computer Science & Engineering', code: 'CSE', departmentId: 'dept-cs', totalSemesters: 8, description: 'B.Tech in Computer Science'),
    CourseModel(id: 'course-2', name: 'Electronics & Communication', code: 'ECE', departmentId: 'dept-ec', totalSemesters: 8, description: 'B.Tech in Electronics'),
    CourseModel(id: 'course-3', name: 'Mechanical Engineering', code: 'ME', departmentId: 'dept-me', totalSemesters: 8),
    CourseModel(id: 'course-4', name: 'Information Technology', code: 'IT', departmentId: 'dept-it', totalSemesters: 8),
  ];

  // ── Subjects ────────────────────────────────────────────────────────

  static const List<SubjectModel> subjects = [
    SubjectModel(id: 'sub-1', name: 'Data Structures', code: 'CS301', courseId: 'course-1', semester: 4, credits: 4, teacherId: 'teacher-1'),
    SubjectModel(id: 'sub-2', name: 'Operating Systems', code: 'CS302', courseId: 'course-1', semester: 4, credits: 4, teacherId: 'teacher-1'),
    SubjectModel(id: 'sub-3', name: 'Database Systems', code: 'CS303', courseId: 'course-1', semester: 4, credits: 3, teacherId: 'teacher-2'),
    SubjectModel(id: 'sub-4', name: 'Computer Networks', code: 'CS304', courseId: 'course-1', semester: 4, credits: 3, teacherId: 'teacher-2'),
    SubjectModel(id: 'sub-5', name: 'Mathematics IV', code: 'MA401', courseId: 'course-1', semester: 4, credits: 4, teacherId: 'teacher-3'),
    SubjectModel(id: 'sub-6', name: 'English Communication', code: 'HS201', courseId: 'course-1', semester: 4, credits: 2, teacherId: 'teacher-3'),
  ];

  // ── Batches ─────────────────────────────────────────────────────────

  static const List<BatchModel> batches = [
    BatchModel(id: 'batch-1', name: 'CSE 2024 A', courseId: 'course-1', year: 2024, section: 'A'),
    BatchModel(id: 'batch-2', name: 'ECE 2024 A', courseId: 'course-2', year: 2024, section: 'A'),
  ];

  // ── Subject Attendance (for student-1) ──────────────────────────────

  static const List<SubjectAttendance> studentAttendance = [
    SubjectAttendance(subjectId: 'sub-1', subjectName: 'Data Structures', subjectCode: 'CS301', totalClasses: 48, present: 42, absent: 4, late: 2, excused: 0, currentStreak: 12),
    SubjectAttendance(subjectId: 'sub-2', subjectName: 'Operating Systems', subjectCode: 'CS302', totalClasses: 45, present: 38, absent: 5, late: 1, excused: 1, currentStreak: 5),
    SubjectAttendance(subjectId: 'sub-3', subjectName: 'Database Systems', subjectCode: 'CS303', totalClasses: 40, present: 36, absent: 3, late: 1, excused: 0, currentStreak: 8),
    SubjectAttendance(subjectId: 'sub-4', subjectName: 'Computer Networks', subjectCode: 'CS304', totalClasses: 42, present: 34, absent: 6, late: 2, excused: 0, currentStreak: 3),
    SubjectAttendance(subjectId: 'sub-5', subjectName: 'Mathematics IV', subjectCode: 'MA401', totalClasses: 50, present: 37, absent: 10, late: 2, excused: 1, currentStreak: 1),
    SubjectAttendance(subjectId: 'sub-6', subjectName: 'English Communication', subjectCode: 'HS201', totalClasses: 30, present: 27, absent: 2, late: 1, excused: 0, currentStreak: 15),
  ];

  // ── Today's Schedule ────────────────────────────────────────────────

  static List<ClassScheduleEntry> get todaySchedule => [
    ClassScheduleEntry(subjectId: 'sub-1', subjectName: 'Data Structures', teacherName: 'Dr. Rajesh Mehta', room: 'Room 301', startTime: _today(9, 0), endTime: _today(10, 0), attendanceStatus: AttendanceStatus.present),
    ClassScheduleEntry(subjectId: 'sub-5', subjectName: 'Mathematics IV', teacherName: 'Dr. Anita Gupta', room: 'Room 205', startTime: _today(10, 15), endTime: _today(11, 15)),
    ClassScheduleEntry(subjectId: 'sub-3', subjectName: 'Database Systems', teacherName: 'Prof. Lakshmi Nair', room: 'Lab 102', startTime: _today(11, 30), endTime: _today(12, 30)),
    ClassScheduleEntry(subjectId: 'sub-4', subjectName: 'Computer Networks', teacherName: 'Prof. Lakshmi Nair', room: 'Room 401', startTime: _today(14, 0), endTime: _today(15, 0)),
    ClassScheduleEntry(subjectId: 'sub-6', subjectName: 'English Communication', teacherName: 'Dr. Anita Gupta', room: 'Room 108', startTime: _today(15, 15), endTime: _today(16, 15)),
  ];

  // ── Circulars ──────────────────────────────────────────────────────

  static List<CircularModel> get circulars => [
    CircularModel(id: 'circ-1', title: 'Mid-Semester Examination Schedule', content: 'The mid-semester examinations for all 4th semester courses will commence from August 25, 2026. Students are advised to collect their hall tickets from the examination cell. Detailed timetable is attached.', category: CircularCategory.examination, priority: CircularPriority.urgent, authorId: 'admin-1', authorName: 'Admin', publishDate: _daysAgo(2), createdAt: _daysAgo(2), updatedAt: _daysAgo(2), attachmentUrls: ['exam_schedule.pdf']),
    CircularModel(id: 'circ-2', title: 'Attendance Warning — Below 75%', content: 'Students with attendance below 75% in any subject will not be eligible for end-semester examinations. Kindly ensure regular attendance.', category: CircularCategory.attendance, priority: CircularPriority.important, authorId: 'admin-1', authorName: 'Admin', publishDate: _daysAgo(5), createdAt: _daysAgo(5), updatedAt: _daysAgo(5)),
    CircularModel(id: 'circ-3', title: 'Technical Fest — InnoVate 2026', content: 'The annual technical festival InnoVate 2026 will be held on September 15-17. Registrations are now open for all events including hackathon, coding competition, and paper presentation.', category: CircularCategory.events, priority: CircularPriority.normal, authorId: 'teacher-1', authorName: 'Dr. Rajesh Mehta', publishDate: _daysAgo(3), createdAt: _daysAgo(3), updatedAt: _daysAgo(3)),
    CircularModel(id: 'circ-4', title: 'Data Structures Lab Assignment', content: 'Lab assignment on Binary Search Trees is due by August 22. Submit via the online portal. Late submissions will not be accepted.', category: CircularCategory.assignment, priority: CircularPriority.important, authorId: 'teacher-1', authorName: 'Dr. Rajesh Mehta', publishDate: _daysAgo(1), createdAt: _daysAgo(1), updatedAt: _daysAgo(1), targetCourseIds: ['course-1']),
    CircularModel(id: 'circ-5', title: 'Library Timings Extended', content: 'The central library will remain open until 10:00 PM during the examination period for student convenience.', category: CircularCategory.general, priority: CircularPriority.normal, authorId: 'admin-1', authorName: 'Admin', publishDate: _daysAgo(7), createdAt: _daysAgo(7), updatedAt: _daysAgo(7)),
    CircularModel(id: 'circ-6', title: 'Fee Payment Deadline', content: 'Last date for payment of 4th semester fees is August 30, 2026. Late fee of ₹500/day will be applicable after the deadline.', category: CircularCategory.fees, priority: CircularPriority.urgent, authorId: 'admin-1', authorName: 'Admin', publishDate: _daysAgo(4), createdAt: _daysAgo(4), updatedAt: _daysAgo(4)),
    CircularModel(id: 'circ-7', title: 'Guest Lecture on AI/ML', content: 'A guest lecture on "Applications of AI in Healthcare" by Dr. Sundar from IIT Delhi will be held on August 20 in the Main Auditorium.', category: CircularCategory.academic, priority: CircularPriority.normal, authorId: 'teacher-2', authorName: 'Prof. Lakshmi Nair', publishDate: _daysAgo(6), createdAt: _daysAgo(6), updatedAt: _daysAgo(6)),
    CircularModel(id: 'circ-8', title: 'Campus Placement Drive', content: 'TCS and Infosys will be conducting campus placement drives on September 5-6. Eligible students should register through the placement cell.', category: CircularCategory.general, priority: CircularPriority.important, authorId: 'admin-1', authorName: 'Admin', publishDate: _daysAgo(8), createdAt: _daysAgo(8), updatedAt: _daysAgo(8)),
  ];

  // ── Events ─────────────────────────────────────────────────────────

  static List<EventModel> get events => [
    EventModel(id: 'event-1', title: 'Mid-Semester Exam', type: EventType.exam, date: _now.add(const Duration(days: 7)), startTime: _today(9, 0), endTime: _today(12, 0), location: 'Examination Hall', createdAt: _daysAgo(10)),
    EventModel(id: 'event-2', title: 'DS Assignment Due', type: EventType.assignment, date: _now.add(const Duration(days: 4)), createdAt: _daysAgo(5)),
    EventModel(id: 'event-3', title: 'InnoVate 2026', type: EventType.institutional, date: _now.add(const Duration(days: 28)), location: 'Campus', createdAt: _daysAgo(3)),
    EventModel(id: 'event-4', title: 'Faculty Meeting', type: EventType.meeting, date: _now.add(const Duration(days: 2)), startTime: _today(14, 0), endTime: _today(15, 30), location: 'Conference Room', createdAt: _daysAgo(1)),
    EventModel(id: 'event-5', title: 'Guest Lecture — AI in Healthcare', type: EventType.academic, date: _now.add(const Duration(days: 2)), startTime: _today(10, 0), endTime: _today(12, 0), location: 'Main Auditorium', createdAt: _daysAgo(6)),
    EventModel(id: 'event-6', title: 'Independence Day', type: EventType.holiday, date: DateTime(_now.year, 8, 15), createdAt: _daysAgo(30)),
  ];

  // ── Notifications ──────────────────────────────────────────────────

  static List<NotificationModel> get notifications => [
    NotificationModel(id: 'notif-1', userId: 'student-1', title: 'New Circular', body: 'Mid-Semester Examination Schedule has been published.', type: NotificationType.circular, referenceId: 'circ-1', createdAt: _daysAgo(2)),
    NotificationModel(id: 'notif-2', userId: 'student-1', title: 'Attendance Alert', body: 'Your Mathematics IV attendance is below 75%.', type: NotificationType.attendance, isRead: true, createdAt: _daysAgo(3)),
    NotificationModel(id: 'notif-3', userId: 'student-1', title: 'Assignment Reminder', body: 'DS Assignment is due in 4 days.', type: NotificationType.academic, createdAt: _daysAgo(1)),
    NotificationModel(id: 'notif-4', userId: 'student-1', title: 'Fee Reminder', body: 'Fee payment deadline is August 30.', type: NotificationType.system, createdAt: _daysAgo(4)),
  ];

  // ── Leaderboard ────────────────────────────────────────────────────

  static const List<LeaderboardEntryModel> leaderboard = [
    LeaderboardEntryModel(studentId: 'student-2', studentName: 'Priya Sharma', courseId: 'course-1', rank: 1, streak: 18, attendancePercentage: 96.5),
    LeaderboardEntryModel(studentId: 'student-3', studentName: 'Rahul Verma', courseId: 'course-1', rank: 2, streak: 15, attendancePercentage: 93.2),
    LeaderboardEntryModel(studentId: 'student-1', studentName: 'Arun Kumar', courseId: 'course-1', rank: 3, streak: 12, attendancePercentage: 87.8),
    LeaderboardEntryModel(studentId: 'student-4', studentName: 'Sneha Patel', courseId: 'course-1', rank: 4, streak: 10, attendancePercentage: 85.1),
  ];

  // ── Attendance Policies ─────────────────────────────────────────────

  static const List<AttendancePolicyModel> policies = [
    AttendancePolicyModel(id: 'policy-1', courseId: 'course-1', minimumAttendancePercent: 75.0, qrExpiryMinutes: 15, locationRequired: true, campusLat: 28.6139, campusLng: 77.2090, allowedRadiusMeters: 200),
    AttendancePolicyModel(id: 'policy-2', courseId: 'course-2', minimumAttendancePercent: 75.0, qrExpiryMinutes: 10),
  ];

  // ── Audit Logs ─────────────────────────────────────────────────────

  static List<AuditLogModel> get auditLogs => [
    AuditLogModel(id: 'log-1', userId: 'teacher-1', userName: 'Dr. Rajesh Mehta', action: 'MARK_ATTENDANCE', entityType: 'AttendanceRecord', entityId: 'rec-manual-1', details: 'Manually marked student-4 as present for CS301', timestamp: _daysAgo(1)),
    AuditLogModel(id: 'log-2', userId: 'admin-1', userName: 'Admin User', action: 'UPDATE_POLICY', entityType: 'AttendancePolicy', entityId: 'policy-1', details: 'Updated QR expiry from 10 to 15 minutes', timestamp: _daysAgo(3)),
    AuditLogModel(id: 'log-3', userId: 'teacher-2', userName: 'Prof. Lakshmi Nair', action: 'PUBLISH_CIRCULAR', entityType: 'Circular', entityId: 'circ-7', details: 'Published guest lecture notice', timestamp: _daysAgo(6)),
  ];

  // ── Helper ──────────────────────────────────────────────────────────

  /// Default demo student for quick login.
  static StudentModel get demoStudent => students.first;
  static TeacherModel get demoTeacher => teachers.first;
  static UserModel get demoAdmin => users.last;

  /// Overall attendance for the demo student.
  static double get demoStudentOverallAttendance {
    int totalPresent = 0;
    int totalClasses = 0;
    for (final sa in studentAttendance) {
      totalPresent += sa.present + sa.late;
      totalClasses += sa.totalClasses;
    }
    return totalClasses > 0 ? (totalPresent / totalClasses) * 100 : 0;
  }

  static int get demoStudentTotalPresent =>
      studentAttendance.fold(0, (sum, sa) => sum + sa.present);
  static int get demoStudentTotalAbsent =>
      studentAttendance.fold(0, (sum, sa) => sum + sa.absent);
  static int get demoStudentTotalLate =>
      studentAttendance.fold(0, (sum, sa) => sum + sa.late);
  static int get demoStudentStreak => 12;
}
