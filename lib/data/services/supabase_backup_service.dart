import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:flutter/foundation.dart';

class SupabaseBackupService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Backs up a newly created attendance record to Supabase.
  /// This operation runs asynchronously and independently of the main Firestore flow
  /// to avoid slowing down the check-in process.
  Future<void> backupAttendanceRecord(AttendanceRecordModel record) async {
    try {
      // We assume there is a table named 'attendance_records_backup'
      // or similar in the Supabase schema. We'll use 'attendance_records'.
      await _supabase.from('attendance_records').insert({
        'id': record.id,
        'student_id': record.studentId,
        'attendance_session_id': record.attendanceSessionId,
        'subject_id': record.subjectId,
        'subject_name': record.subjectName,
        'course_id': record.courseId,
        'teacher_id': record.teacherId,
        'teacher_name': record.teacherName,
        'room': record.room,
        'status': record.status.name,
        'verification_method': record.verificationMethod.name,
        'timestamp': record.timestamp.toIso8601String(),
        'location_verified': record.locationVerified,
        'face_verified': record.faceVerified,
        'latitude': record.latitude,
        'longitude': record.longitude,
        'created_at': record.createdAt.toIso8601String(),
        'updated_at': record.updatedAt.toIso8601String(),
      });
      debugPrint('Successfully backed up attendance record to Supabase: ${record.id}');
    } catch (e) {
      // Silently fail or log it since this is just a backup mechanism
      // and we don't want to crash the app or alert the user if backup fails.
      debugPrint('Failed to backup attendance record to Supabase: $e');
    }
  }
}
