import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:presenza/data/models/attendance_model.dart';
import 'package:presenza/data/models/user_model.dart';

/// Service to generate and export structured RFC 4180 CSV files for attendance and academic rosters.
class CsvExportService {
  static String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Exports attendance records of a specific classroom session as a CSV file.
  static Future<bool> exportSessionAttendance({
    required AttendanceSessionModel session,
    required List<AttendanceRecordModel> records,
    List<StudentModel> enrolledStudents = const [],
  }) async {
    try {
      final buffer = StringBuffer();
      // 1. Session Metadata Header
      buffer.writeln('Presenza Attendance Session Report');
      buffer.writeln('Subject,${_escapeCsvValue(session.subjectName ?? "N/A")} (${_escapeCsvValue(session.subjectCode ?? "")})');
      buffer.writeln('Teacher,${_escapeCsvValue(session.teacherName ?? "Faculty")}');
      buffer.writeln('Date,${DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime)}');
      buffer.writeln('Room,${_escapeCsvValue(session.room ?? "Room 402")}');
      buffer.writeln('Total Checked In,${records.length}');
      buffer.writeln('');

      // 2. Column Headers
      buffer.writeln('Sl No,Student ID,Student Name,Status,Verification Method,Location Verified,Check-in Time');

      final studentMap = {for (final s in enrolledStudents) s.user.id: s};

      // 3. Record Rows
      for (var i = 0; i < records.length; i++) {
        final rec = records[i];
        final student = studentMap[rec.studentId];
        final studentId = student?.studentId ?? rec.studentId;
        final studentName = student?.user.name ?? 'Student';
        final status = rec.status.name.toUpperCase();
        final method = rec.verificationMethod.displayName;
        final loc = rec.locationVerified ? 'VERIFIED (GPS)' : 'STANDARD';
        final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(rec.timestamp);

        buffer.writeln('${i + 1},${_escapeCsvValue(studentId)},${_escapeCsvValue(studentName)},$status,${_escapeCsvValue(method)},$loc,$timeStr');
      }

      final csvContent = buffer.toString();
      final dateSlug = DateFormat('yyyyMMdd_HHmm').format(session.startTime);
      final cleanCode = (session.subjectCode ?? 'ATT').replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = 'Attendance_${cleanCode}_$dateSlug.csv';

      final bytes = Uint8List.fromList(utf8.encode(csvContent));
      final xFile = XFile.fromData(
        bytes,
        name: fileName,
        mimeType: 'text/csv',
      );

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Presenza Attendance Report for ${session.subjectName ?? "Class"} ($dateSlug)',
          subject: 'Attendance Report - ${session.subjectName ?? "Class"}',
        ),
      );

      return result.status == ShareResultStatus.success || result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('CsvExportService.exportSessionAttendance error: $e');
      return false;
    }
  }

  /// Exports enrolled student roster for a batch or department.
  static Future<bool> exportStudentRoster({
    required String batchName,
    required List<StudentModel> students,
  }) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Presenza Student Roster Report');
      buffer.writeln('Batch / Section,${_escapeCsvValue(batchName)}');
      buffer.writeln('Export Date,${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
      buffer.writeln('Total Students,${students.length}');
      buffer.writeln('');

      buffer.writeln('Sl No,Roll No / Student ID,Full Name,Email,Course,Batch,Semester,Department');

      for (var i = 0; i < students.length; i++) {
        final st = students[i];
        final rollNo = st.studentId;
        final name = st.user.name;
        final email = st.user.email;
        final course = st.courseId.replaceAll('course-', '').toUpperCase();
        final batch = st.batchId.replaceAll('batch-', '').toUpperCase();
        final sem = 'Sem ${st.semester}';
        final dept = st.user.department ?? 'Computer Science';

        buffer.writeln('${i + 1},${_escapeCsvValue(rollNo)},${_escapeCsvValue(name)},${_escapeCsvValue(email)},${_escapeCsvValue(course)},${_escapeCsvValue(batch)},$sem,${_escapeCsvValue(dept)}');
      }

      final csvContent = buffer.toString();
      final dateSlug = DateFormat('yyyyMMdd').format(DateTime.now());
      final cleanBatch = batchName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = 'Roster_${cleanBatch}_$dateSlug.csv';

      final bytes = Uint8List.fromList(utf8.encode(csvContent));
      final xFile = XFile.fromData(
        bytes,
        name: fileName,
        mimeType: 'text/csv',
      );

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Presenza Student Roster for $batchName',
          subject: 'Student Roster - $batchName',
        ),
      );

      return result.status == ShareResultStatus.success || result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('CsvExportService.exportStudentRoster error: $e');
      return false;
    }
  }

  /// Exports personal attendance records for a student.
  static Future<bool> exportStudentPersonalAttendance({
    required StudentModel student,
    required List<SubjectAttendance> subjects,
    required List<AttendanceRecordModel> records,
  }) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Presenza Student Academic Attendance Statement');
      buffer.writeln('Student Name,${_escapeCsvValue(student.user.name)}');
      buffer.writeln('Student ID,${_escapeCsvValue(student.studentId)}');
      buffer.writeln('Semester,Semester ${student.semester}');
      buffer.writeln('Report Date,${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
      buffer.writeln('');

      // Subject summary
      buffer.writeln('--- SUBJECT SUMMARY ---');
      buffer.writeln('Subject Code,Subject Name,Faculty,Credits,Conducted,Present,Late,Absent,Percentage %,Status');
      for (final s in subjects) {
        final status = s.percentage >= 75.0 ? 'SAFE' : 'AT RISK';
        buffer.writeln('${_escapeCsvValue(s.subjectCode)},${_escapeCsvValue(s.subjectName)},${_escapeCsvValue(s.teacherName ?? "Faculty")},${s.credits ?? 3},${s.totalClasses},${s.present},${s.late},${s.absent},${s.percentage.toStringAsFixed(1)}%,$status');
      }
      buffer.writeln('');

      // Detailed history logs
      buffer.writeln('--- DETAILED CHECK-IN LOGS ---');
      buffer.writeln('Date & Time,Subject,Status,Method,GPS Verified');
      final sortedRecords = List<AttendanceRecordModel>.from(records)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      for (final r in sortedRecords) {
        final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(r.timestamp);
        final loc = r.locationVerified ? 'YES' : 'NO';
        buffer.writeln('$timeStr,${_escapeCsvValue(r.subjectName ?? '')},${r.status.name.toUpperCase()},${r.verificationMethod.displayName},$loc');
      }

      final csvContent = buffer.toString();
      final dateSlug = DateFormat('yyyyMMdd').format(DateTime.now());
      final cleanId = student.studentId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = 'Attendance_Statement_${cleanId}_$dateSlug.csv';

      final bytes = Uint8List.fromList(utf8.encode(csvContent));
      final xFile = XFile.fromData(
        bytes,
        name: fileName,
        mimeType: 'text/csv',
      );

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Presenza Attendance Statement for ${student.user.name} ($cleanId)',
          subject: 'Attendance Statement - ${student.user.name}',
        ),
      );

      return result.status == ShareResultStatus.success || result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('CsvExportService.exportStudentPersonalAttendance error: $e');
      return false;
    }
  }

  /// Exports campus attendance records for admin review.
  static Future<bool> exportCampusAttendance({
    required List<AttendanceRecordModel> records,
    List<StudentModel> students = const [],
  }) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Presenza Institutional Attendance Audit Report');
      buffer.writeln('Export Date,${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
      buffer.writeln('Total Check-in Records,${records.length}');
      buffer.writeln('');

      buffer.writeln('Sl No,Date & Time,Student ID,Student Name,Subject Code,Subject Name,Faculty,Status,Method,GPS Verified');

      final studentMap = {for (final s in students) s.user.id: s};

      for (var i = 0; i < records.length; i++) {
        final r = records[i];
        final student = studentMap[r.studentId];
        final rollNo = student?.studentId ?? r.studentId;
        final name = student?.user.name ?? 'Student';
        final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(r.timestamp);
        final loc = r.locationVerified ? 'VERIFIED' : 'STANDARD';

        buffer.writeln('${i + 1},$timeStr,${_escapeCsvValue(rollNo)},${_escapeCsvValue(name)},${_escapeCsvValue(r.subjectId)},${_escapeCsvValue(r.subjectName ?? '')},${_escapeCsvValue(r.teacherName ?? "Faculty")},${r.status.name.toUpperCase()},${r.verificationMethod.displayName},$loc');
      }

      final csvContent = buffer.toString();
      final dateSlug = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'Campus_Attendance_Audit_$dateSlug.csv';

      final bytes = Uint8List.fromList(utf8.encode(csvContent));
      final xFile = XFile.fromData(
        bytes,
        name: fileName,
        mimeType: 'text/csv',
      );

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Presenza Campus Attendance Audit ($dateSlug)',
          subject: 'Campus Attendance Audit Report',
        ),
      );

      return result.status == ShareResultStatus.success || result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('CsvExportService.exportCampusAttendance error: $e');
      return false;
    }
  }
}
