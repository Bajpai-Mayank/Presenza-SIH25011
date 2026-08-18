import 'package:presenza/core/enums/enums.dart';
import 'package:presenza/core/enums/attendance_status.dart';

/// A circular / notice published by teacher or admin.
class CircularModel {
  final String id;
  final String title;
  final String content;
  final CircularCategory category;
  final CircularPriority priority;
  final String authorId;
  final String authorName;
  final List<String>? targetCourseIds;
  final List<String>? targetBatchIds;
  final List<String> attachmentUrls;
  final DateTime publishDate;
  final DateTime? expiryDate;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CircularModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    required this.authorId,
    required this.authorName,
    this.targetCourseIds,
    this.targetBatchIds,
    this.attachmentUrls = const [],
    required this.publishDate,
    this.expiryDate,
    this.isPublished = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CircularModel.fromJson(Map<String, dynamic> json) => CircularModel(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        category: CircularCategory.fromString(json['category'] as String),
        priority: CircularPriority.fromString(json['priority'] as String),
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        targetCourseIds: (json['targetCourseIds'] as List<dynamic>?)
            ?.cast<String>()
            .toList(),
        targetBatchIds: (json['targetBatchIds'] as List<dynamic>?)
            ?.cast<String>()
            .toList(),
        attachmentUrls: (json['attachmentUrls'] as List<dynamic>?)
                ?.cast<String>()
                .toList() ??
            const [],
        publishDate: DateTime.parse(json['publishDate'] as String),
        expiryDate: json['expiryDate'] != null
            ? DateTime.parse(json['expiryDate'] as String)
            : null,
        isPublished: json['isPublished'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category.name,
        'priority': priority.name,
        'authorId': authorId,
        'authorName': authorName,
        'targetCourseIds': targetCourseIds,
        'targetBatchIds': targetBatchIds,
        'attachmentUrls': attachmentUrls,
        'publishDate': publishDate.toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
        'isPublished': isPublished,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  bool get hasAttachments => attachmentUrls.isNotEmpty;
  bool get isExpired =>
      expiryDate != null && DateTime.now().isAfter(expiryDate!);
  bool get isUrgent => priority == CircularPriority.urgent;
}

/// An academic/institutional event.
class EventModel {
  final String id;
  final String title;
  final String? description;
  final EventType type;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? location;
  final List<String>? courseIds;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.date,
    this.startTime,
    this.endTime,
    this.location,
    this.courseIds,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        type: EventType.fromString(json['type'] as String),
        date: DateTime.parse(json['date'] as String),
        startTime: json['startTime'] != null
            ? DateTime.parse(json['startTime'] as String)
            : null,
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        location: json['location'] as String?,
        courseIds:
            (json['courseIds'] as List<dynamic>?)?.cast<String>().toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'date': date.toIso8601String(),
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'location': location,
        'courseIds': courseIds,
        'createdAt': createdAt.toIso8601String(),
      };

  bool get isUpcoming => date.isAfter(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// In-app notification.
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: NotificationType.fromString(json['type'] as String),
        referenceId: json['referenceId'] as String?,
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'referenceId': referenceId,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
      };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        referenceId: referenceId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

/// Leaderboard entry for a student within a course.
class LeaderboardEntryModel {
  final String studentId;
  final String studentName;
  final String courseId;
  final int rank;
  final int streak;
  final double attendancePercentage;

  const LeaderboardEntryModel({
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.rank,
    required this.streak,
    required this.attendancePercentage,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntryModel(
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String,
        courseId: json['courseId'] as String,
        rank: json['rank'] as int,
        streak: json['streak'] as int,
        attendancePercentage:
            (json['attendancePercentage'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'courseId': courseId,
        'rank': rank,
        'streak': streak,
        'attendancePercentage': attendancePercentage,
      };
}

/// Attendance policy configuration.
class AttendancePolicyModel {
  final String id;
  final String courseId;
  final double minimumAttendancePercent;
  final int qrExpiryMinutes;
  final bool locationRequired;
  final FaceVerificationMode faceVerificationMode;
  final double? campusLat;
  final double? campusLng;
  final double? allowedRadiusMeters;

  const AttendancePolicyModel({
    required this.id,
    required this.courseId,
    this.minimumAttendancePercent = 75.0,
    this.qrExpiryMinutes = 15,
    this.locationRequired = false,
    this.faceVerificationMode = FaceVerificationMode.disabled,
    this.campusLat,
    this.campusLng,
    this.allowedRadiusMeters,
  });

  factory AttendancePolicyModel.fromJson(Map<String, dynamic> json) =>
      AttendancePolicyModel(
        id: json['id'] as String,
        courseId: json['courseId'] as String,
        minimumAttendancePercent:
            (json['minimumAttendancePercent'] as num?)?.toDouble() ?? 75.0,
        qrExpiryMinutes: json['qrExpiryMinutes'] as int? ?? 15,
        locationRequired: json['locationRequired'] as bool? ?? false,
        faceVerificationMode: FaceVerificationMode.fromString(
            json['faceVerificationMode'] as String? ?? 'disabled'),
        campusLat: (json['campusLat'] as num?)?.toDouble(),
        campusLng: (json['campusLng'] as num?)?.toDouble(),
        allowedRadiusMeters: (json['allowedRadiusMeters'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'minimumAttendancePercent': minimumAttendancePercent,
        'qrExpiryMinutes': qrExpiryMinutes,
        'locationRequired': locationRequired,
        'faceVerificationMode': faceVerificationMode.name,
        'campusLat': campusLat,
        'campusLng': campusLng,
        'allowedRadiusMeters': allowedRadiusMeters,
      };
}

/// Audit log entry for admin review.
class AuditLogModel {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final String entityType;
  final String entityId;
  final String? details;
  final DateTime timestamp;

  const AuditLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.details,
    required this.timestamp,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) => AuditLogModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        action: json['action'] as String,
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as String,
        details: json['details'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'details': details,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Today's class schedule entry.
class ClassScheduleEntry {
  final String subjectId;
  final String subjectName;
  final String teacherName;
  final String room;
  final DateTime startTime;
  final DateTime endTime;
  final AttendanceStatus? attendanceStatus;

  const ClassScheduleEntry({
    required this.subjectId,
    required this.subjectName,
    required this.teacherName,
    required this.room,
    required this.startTime,
    required this.endTime,
    this.attendanceStatus,
  });
}
