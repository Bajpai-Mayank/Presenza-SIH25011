import 'package:flutter/material.dart';
import 'package:presenza/core/enums/user_role.dart';

/// Milestone / Achievement badge for students & faculty.
class AchievementModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
    this.unlockedAt,
  });
}

/// Core user model shared across all roles.
class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? avatarUrl;
  final String? phone;
  final String? bio;
  final String? institution;
  final String? department;
  final DateTime? lastLoginAt;
  final DateTime? lastActiveAt;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.phone,
    this.bio,
    this.institution,
    this.department,
    this.lastLoginAt,
    this.lastActiveAt,
    this.isOnline = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? 'User',
        role: UserRole.fromString(json['role'] as String?),
        avatarUrl: json['avatarUrl'] as String?,
        phone: json['phone'] as String?,
        bio: json['bio'] as String?,
        institution: json['institution'] as String? ?? 'National Institute of Technology',
        department: json['department'] as String?,
        lastLoginAt: json['lastLoginAt'] != null
            ? DateTime.tryParse(json['lastLoginAt'] as String)
            : null,
        lastActiveAt: json['lastActiveAt'] != null
            ? DateTime.tryParse(json['lastActiveAt'] as String)
            : null,
        isOnline: json['isOnline'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role.name,
        'avatarUrl': avatarUrl,
        'phone': phone,
        'bio': bio,
        'institution': institution,
        'department': department,
        'lastLoginAt': lastLoginAt?.toIso8601String(),
        'lastActiveAt': lastActiveAt?.toIso8601String(),
        'isOnline': isOnline,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? avatarUrl,
    String? phone,
    String? bio,
    String? institution,
    String? department,
    DateTime? lastLoginAt,
    DateTime? lastActiveAt,
    bool? isOnline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name ?? this.name,
        role: role ?? this.role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        phone: phone ?? this.phone,
        bio: bio ?? this.bio,
        institution: institution ?? this.institution,
        department: department ?? this.department,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
        isOnline: isOnline ?? this.isOnline,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  bool get isCurrentlyActive {
    if (isOnline) return true;
    if (lastActiveAt != null &&
        DateTime.now().difference(lastActiveAt!).inMinutes < 5) {
      return true;
    }
    return false;
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

/// Student-specific profile data.
class StudentModel {
  final UserModel user;
  final String studentId;
  final String courseId;
  final String batchId;
  final String section;
  final int semester;
  final DateTime enrollmentDate;

  const StudentModel({
    required this.user,
    required this.studentId,
    required this.courseId,
    required this.batchId,
    this.section = 'A',
    required this.semester,
    required this.enrollmentDate,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    String sectionVal = (json['section'] as String?)?.trim().toUpperCase() ?? '';
    if (sectionVal.isEmpty) {
      final batch = json['batchId'] as String? ?? '';
      final parts = batch.split('_');
      if (parts.length >= 4) {
        sectionVal = parts.last.toUpperCase();
      } else if (batch.contains('-')) {
        final dashParts = batch.split('-');
        if (dashParts.isNotEmpty && dashParts.last.length <= 2) {
          sectionVal = dashParts.last.toUpperCase();
        }
      }
      if (sectionVal.isEmpty) sectionVal = 'A';
    }

    return StudentModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      studentId: json['studentId'] as String? ?? 'STU-001',
      courseId: json['courseId'] as String? ?? 'course-btech-cse',
      batchId: json['batchId'] as String? ?? 'batch-2024-a',
      section: sectionVal,
      semester: (json['semester'] as num?)?.toInt() ?? 4,
      enrollmentDate: json['enrollmentDate'] != null
          ? DateTime.tryParse(json['enrollmentDate'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'studentId': studentId,
        'courseId': courseId,
        'batchId': batchId,
        'section': section,
        'semester': semester,
        'enrollmentDate': enrollmentDate.toIso8601String(),
      };

  StudentModel copyWith({
    UserModel? user,
    String? studentId,
    String? courseId,
    String? batchId,
    String? section,
    int? semester,
    DateTime? enrollmentDate,
  }) =>
      StudentModel(
        user: user ?? this.user,
        studentId: studentId ?? this.studentId,
        courseId: courseId ?? this.courseId,
        batchId: batchId ?? this.batchId,
        section: section ?? this.section,
        semester: semester ?? this.semester,
        enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      );
}

/// Teacher-specific profile data.
class TeacherModel {
  final UserModel user;
  final String employeeId;
  final String departmentId;
  final List<String> subjectIds;

  const TeacherModel({
    required this.user,
    required this.employeeId,
    required this.departmentId,
    required this.subjectIds,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) => TeacherModel(
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
        employeeId: json['employeeId'] as String? ?? 'EMP-001',
        departmentId: json['departmentId'] as String? ?? 'dept-cse',
        subjectIds: (json['subjectIds'] as List<dynamic>?)?.cast<String>().toList() ?? const [],
      );

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'employeeId': employeeId,
        'departmentId': departmentId,
        'subjectIds': subjectIds,
      };

  TeacherModel copyWith({
    UserModel? user,
    String? employeeId,
    String? departmentId,
    List<String>? subjectIds,
  }) =>
      TeacherModel(
        user: user ?? this.user,
        employeeId: employeeId ?? this.employeeId,
        departmentId: departmentId ?? this.departmentId,
        subjectIds: subjectIds ?? this.subjectIds,
      );
}
