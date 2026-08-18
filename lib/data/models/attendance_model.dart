import 'package:presenza/core/enums/attendance_status.dart';
import 'package:presenza/core/enums/enums.dart';

/// A teacher-initiated attendance session for one class period.
class AttendanceSessionModel {
  final String id;
  final String subjectId;
  final String teacherId;
  final String courseId;
  final String batchId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String? qrToken;
  final bool isActive;
  final bool locationRequired;
  final FaceVerificationMode faceVerificationMode;
  final double? campusLat;
  final double? campusLng;
  final double? allowedRadiusMeters;
  final DateTime createdAt;

  const AttendanceSessionModel({
    required this.id,
    required this.subjectId,
    required this.teacherId,
    required this.courseId,
    required this.batchId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.qrToken,
    required this.isActive,
    this.locationRequired = false,
    this.faceVerificationMode = FaceVerificationMode.disabled,
    this.campusLat,
    this.campusLng,
    this.allowedRadiusMeters,
    required this.createdAt,
  });

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) =>
      AttendanceSessionModel(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        teacherId: json['teacherId'] as String,
        courseId: json['courseId'] as String,
        batchId: json['batchId'] as String,
        date: DateTime.parse(json['date'] as String),
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        qrToken: json['qrToken'] as String?,
        isActive: json['isActive'] as bool,
        locationRequired: json['locationRequired'] as bool? ?? false,
        faceVerificationMode: FaceVerificationMode.fromString(
            json['faceVerificationMode'] as String? ?? 'disabled'),
        campusLat: (json['campusLat'] as num?)?.toDouble(),
        campusLng: (json['campusLng'] as num?)?.toDouble(),
        allowedRadiusMeters: (json['allowedRadiusMeters'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'teacherId': teacherId,
        'courseId': courseId,
        'batchId': batchId,
        'date': date.toIso8601String(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'qrToken': qrToken,
        'isActive': isActive,
        'locationRequired': locationRequired,
        'faceVerificationMode': faceVerificationMode.name,
        'campusLat': campusLat,
        'campusLng': campusLng,
        'allowedRadiusMeters': allowedRadiusMeters,
        'createdAt': createdAt.toIso8601String(),
      };

  AttendanceSessionModel copyWith({
    String? id,
    String? qrToken,
    bool? isActive,
  }) =>
      AttendanceSessionModel(
        id: id ?? this.id,
        subjectId: subjectId,
        teacherId: teacherId,
        courseId: courseId,
        batchId: batchId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        qrToken: qrToken ?? this.qrToken,
        isActive: isActive ?? this.isActive,
        locationRequired: locationRequired,
        faceVerificationMode: faceVerificationMode,
        campusLat: campusLat,
        campusLng: campusLng,
        allowedRadiusMeters: allowedRadiusMeters,
        createdAt: createdAt,
      );

  bool get isExpired => DateTime.now().isAfter(endTime);
}

/// A single student's attendance record for a session.
class AttendanceRecordModel {
  final String id;
  final String studentId;
  final String attendanceSessionId;
  final String subjectId;
  final String courseId;
  final String teacherId;
  final AttendanceStatus status;
  final VerificationMethod verificationMethod;
  final DateTime timestamp;
  final bool locationVerified;
  final bool faceVerified;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AttendanceRecordModel({
    required this.id,
    required this.studentId,
    required this.attendanceSessionId,
    required this.subjectId,
    required this.courseId,
    required this.teacherId,
    required this.status,
    required this.verificationMethod,
    required this.timestamp,
    this.locationVerified = false,
    this.faceVerified = false,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) =>
      AttendanceRecordModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        attendanceSessionId: json['attendanceSessionId'] as String,
        subjectId: json['subjectId'] as String,
        courseId: json['courseId'] as String,
        teacherId: json['teacherId'] as String,
        status: AttendanceStatus.fromString(json['status'] as String),
        verificationMethod: VerificationMethod.fromString(
            json['verificationMethod'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
        locationVerified: json['locationVerified'] as bool? ?? false,
        faceVerified: json['faceVerified'] as bool? ?? false,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'attendanceSessionId': attendanceSessionId,
        'subjectId': subjectId,
        'courseId': courseId,
        'teacherId': teacherId,
        'status': status.name,
        'verificationMethod': verificationMethod.name,
        'timestamp': timestamp.toIso8601String(),
        'locationVerified': locationVerified,
        'faceVerified': faceVerified,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// Aggregate subject attendance for a student.
class SubjectAttendance {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final int totalClasses;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final int currentStreak;

  const SubjectAttendance({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.totalClasses,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    this.currentStreak = 0,
  });

  double get percentage =>
      totalClasses > 0 ? ((present + late) / totalClasses) * 100 : 0;

  bool isBelowThreshold(double threshold) => percentage < threshold;

  /// Classes needed to reach threshold.
  int classesNeededForThreshold(double threshold) {
    if (percentage >= threshold) return 0;
    final target = threshold / 100;
    // (present + late + x) / (totalClasses + x) >= target
    // Solving: x >= (target * totalClasses - present - late) / (1 - target)
    final needed = ((target * totalClasses - present - late) / (1 - target))
        .ceil();
    return needed > 0 ? needed : 0;
  }

  /// Classes that can be missed before falling below threshold.
  int classesCanMiss(double threshold) {
    if (percentage < threshold) return 0;
    final target = threshold / 100;
    // (present + late) / (totalClasses + x) >= target
    // x <= (present + late) / target - totalClasses
    final canMiss = ((present + late) / target - totalClasses).floor();
    return canMiss > 0 ? canMiss : 0;
  }
}
