/// Academic course.
class CourseModel {
  final String id;
  final String name;
  final String code;
  final String departmentId;
  final int totalSemesters;
  final String? description;

  const CourseModel({
    required this.id,
    required this.name,
    required this.code,
    required this.departmentId,
    required this.totalSemesters,
    this.description,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        departmentId: json['departmentId'] as String,
        totalSemesters: json['totalSemesters'] as int,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'departmentId': departmentId,
        'totalSemesters': totalSemesters,
        'description': description,
      };
}

/// Subject within a course.
class SubjectModel {
  final String id;
  final String name;
  final String code;
  final String courseId;
  final int semester;
  final int credits;
  final String teacherId;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.code,
    required this.courseId,
    required this.semester,
    required this.credits,
    required this.teacherId,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) => SubjectModel(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        courseId: json['courseId'] as String,
        semester: json['semester'] as int,
        credits: json['credits'] as int,
        teacherId: json['teacherId'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'courseId': courseId,
        'semester': semester,
        'credits': credits,
        'teacherId': teacherId,
      };
}

/// Batch (section/year group).
class BatchModel {
  final String id;
  final String name;
  final String courseId;
  final int year;
  final String section;

  const BatchModel({
    required this.id,
    required this.name,
    required this.courseId,
    required this.year,
    required this.section,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) => BatchModel(
        id: json['id'] as String,
        name: json['name'] as String,
        courseId: json['courseId'] as String,
        year: json['year'] as int,
        section: json['section'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'courseId': courseId,
        'year': year,
        'section': section,
      };
}
