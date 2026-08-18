import 'package:presenza/core/enums/user_role.dart';

/// Core user model shared across all roles.
class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? avatarUrl;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        role: UserRole.fromString(json['role'] as String),
        avatarUrl: json['avatarUrl'] as String?,
        phone: json['phone'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role.name,
        'avatarUrl': avatarUrl,
        'phone': phone,
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
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  String get initials {
    final parts = name.trim().split(' ');
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
  final int semester;
  final DateTime enrollmentDate;

  const StudentModel({
    required this.user,
    required this.studentId,
    required this.courseId,
    required this.batchId,
    required this.semester,
    required this.enrollmentDate,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
        studentId: json['studentId'] as String,
        courseId: json['courseId'] as String,
        batchId: json['batchId'] as String,
        semester: json['semester'] as int,
        enrollmentDate: DateTime.parse(json['enrollmentDate'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'studentId': studentId,
        'courseId': courseId,
        'batchId': batchId,
        'semester': semester,
        'enrollmentDate': enrollmentDate.toIso8601String(),
      };

  StudentModel copyWith({
    UserModel? user,
    String? studentId,
    String? courseId,
    String? batchId,
    int? semester,
    DateTime? enrollmentDate,
  }) =>
      StudentModel(
        user: user ?? this.user,
        studentId: studentId ?? this.studentId,
        courseId: courseId ?? this.courseId,
        batchId: batchId ?? this.batchId,
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
        employeeId: json['employeeId'] as String,
        departmentId: json['departmentId'] as String,
        subjectIds:
            (json['subjectIds'] as List<dynamic>).cast<String>().toList(),
      );

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'employeeId': employeeId,
        'departmentId': departmentId,
        'subjectIds': subjectIds,
      };
}
