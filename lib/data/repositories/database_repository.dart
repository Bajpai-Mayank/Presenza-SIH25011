import 'package:presenza/core/enums/attendance_status.dart';
import 'package:presenza/data/models/activity_model.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/data/models/course_model.dart';
import 'package:presenza/data/models/user_model.dart';

/// DatabaseRepository abstract interface
/// 
/// This defines the contract for our backend database operations.
/// By adhering to this interface, we can swap between Firestore and Supabase,
/// or implement dual-write fallbacks, without altering UI or provider logic.
abstract class DatabaseRepository {
  // Authentication & Users
  Future<void> createUserProfile(UserModel user);
  Future<void> updateUserProfile({required String uid, String? name, String? bio, String? phone});

  // Students
  Future<void> createStudentProfile(StudentModel student);
  Stream<StudentModel?> streamStudentProfile(String uid);
  Stream<List<StudentModel>> streamAllStudents();
  Stream<List<StudentModel>> streamStudentsByCourse(String courseId);

  // Teachers
  Future<void> createTeacherProfile(TeacherModel teacher);
  Stream<TeacherModel?> streamTeacherProfile(String uid);

  // Attendance Sessions (Teacher Side)
  Future<void> createAttendanceSession(AttendanceSessionModel session);
  Future<void> closeAttendanceSession(String sessionId);
  Stream<AttendanceSessionModel?> streamActiveAttendanceSession(String teacherId);
  Stream<List<AttendanceSessionModel>> streamSessionHistory(String teacherId);
  Stream<List<AttendanceRecordModel>> streamAttendanceRecordsForSession(String sessionId);

  // Attendance Records (Student Side)
  Future<void> markAttendance({
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
    required double distance,
    required bool isMocked,
  });
  Stream<List<AttendanceRecordModel>> streamStudentAttendanceRecords(String studentId);

  // Subjects & Courses
  Future<void> addTeacherSubject({required String teacherUid, required SubjectModel subject});
  Stream<List<SubjectModel>> streamTeacherSubjects(String teacherUid);

  // Circulars / Activities
  Future<void> saveActivityPost(ActivityPostModel post);
  Stream<List<ActivityPostModel>> streamActivities({String? targetCourseId, String? targetBatchId});
  Future<void> approveActivityPost(String postId);
  Future<void> rejectActivityPost(String postId);

  // Utilities
  Future<int> getEnrolledStudentCount(String courseId);
}
