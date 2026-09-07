class ProfileUpdateRequestModel {
  final String id;
  final String studentUid;
  final String studentName;
  final String studentRollNo;
  final Map<String, dynamic> currentData;
  final Map<String, dynamic> requestedData;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedByTeacherId;
  final String? reviewedByTeacherName;
  final String? rejectionReason;

  const ProfileUpdateRequestModel({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.studentRollNo,
    required this.currentData,
    required this.requestedData,
    this.status = 'pending',
    required this.createdAt,
    this.reviewedAt,
    this.reviewedByTeacherId,
    this.reviewedByTeacherName,
    this.rejectionReason,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get requestedName => (requestedData['name'] as String?)?.trim() ?? studentName;
  String get requestedCourseId => requestedData['courseId'] as String? ?? (currentData['courseId'] as String? ?? '');
  String get requestedBatchId => requestedData['batchId'] as String? ?? (currentData['batchId'] as String? ?? '');
  String get requestedSection => requestedData['section'] as String? ?? (currentData['section'] as String? ?? 'A');
  int get requestedSemester => (requestedData['semester'] as num?)?.toInt() ?? ((currentData['semester'] as num?)?.toInt() ?? 1);
  String? get requestedPhone => requestedData['phone'] as String? ?? currentData['phone'] as String?;
  String? get requestedBio => requestedData['bio'] as String? ?? currentData['bio'] as String?;

  factory ProfileUpdateRequestModel.fromJson(Map<String, dynamic> json) =>
      ProfileUpdateRequestModel(
        id: json['id'] as String,
        studentUid: json['studentUid'] as String,
        studentName: json['studentName'] as String? ?? '',
        studentRollNo: json['studentRollNo'] as String? ?? '',
        currentData: Map<String, dynamic>.from(json['currentData'] as Map? ?? {}),
        requestedData: Map<String, dynamic>.from(json['requestedData'] as Map? ?? {}),
        status: json['status'] as String? ?? 'pending',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        reviewedAt: json['reviewedAt'] != null
            ? DateTime.tryParse(json['reviewedAt'] as String)
            : null,
        reviewedByTeacherId: json['reviewedByTeacherId'] as String?,
        reviewedByTeacherName: json['reviewedByTeacherName'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentUid': studentUid,
        'studentName': studentName,
        'studentRollNo': studentRollNo,
        'currentData': currentData,
        'requestedData': requestedData,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'reviewedAt': reviewedAt?.toIso8601String(),
        'reviewedByTeacherId': reviewedByTeacherId,
        'reviewedByTeacherName': reviewedByTeacherName,
        'rejectionReason': rejectionReason,
      };

  ProfileUpdateRequestModel copyWith({
    String? id,
    String? studentUid,
    String? studentName,
    String? studentRollNo,
    Map<String, dynamic>? currentData,
    Map<String, dynamic>? requestedData,
    String? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedByTeacherId,
    String? reviewedByTeacherName,
    String? rejectionReason,
  }) =>
      ProfileUpdateRequestModel(
        id: id ?? this.id,
        studentUid: studentUid ?? this.studentUid,
        studentName: studentName ?? this.studentName,
        studentRollNo: studentRollNo ?? this.studentRollNo,
        currentData: currentData ?? this.currentData,
        requestedData: requestedData ?? this.requestedData,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        reviewedByTeacherId: reviewedByTeacherId ?? this.reviewedByTeacherId,
        reviewedByTeacherName: reviewedByTeacherName ?? this.reviewedByTeacherName,
        rejectionReason: rejectionReason ?? this.rejectionReason,
      );
}
