import 'package:flutter/material.dart';

/// Activity categories for campus announcements and student posts.
enum ActivityCategory {
  academic('Academic', Icons.school_outlined, Color(0xFF4F46E5)),
  workshop('Workshop', Icons.build_circle_outlined, Color(0xFF0D9488)),
  hackathon('Hackathon', Icons.code_outlined, Color(0xFF7C3AED)),
  cultural('Cultural', Icons.theater_comedy_outlined, Color(0xFFEC4899)),
  sports('Sports', Icons.sports_basketball_outlined, Color(0xFFEA580C)),
  notice('Official Notice', Icons.campaign_outlined, Color(0xFF2563EB)),
  club('Club / Society', Icons.groups_outlined, Color(0xFF059669));

  final String label;
  final IconData icon;
  final Color color;

  const ActivityCategory(this.label, this.icon, this.color);

  static ActivityCategory fromString(String? val) {
    if (val == null) return ActivityCategory.academic;
    return ActivityCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => ActivityCategory.academic,
    );
  }
}

/// Approval status for posts (student-submitted posts require approval).
enum ActivityStatus {
  approved('Approved'),
  pending('Pending Approval'),
  rejected('Rejected');

  final String label;
  const ActivityStatus(this.label);

  static ActivityStatus fromString(String? val) {
    if (val == null) return ActivityStatus.approved;
    return ActivityStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ActivityStatus.approved,
    );
  }
}

/// A comment on a campus activity post.
class ActivityCommentModel {
  final String id;
  final String activityId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String authorRole;
  final String content;
  final DateTime createdAt;

  const ActivityCommentModel({
    required this.id,
    required this.activityId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.authorRole,
    required this.content,
    required this.createdAt,
  });

  factory ActivityCommentModel.fromJson(Map<String, dynamic> json) =>
      ActivityCommentModel(
        id: json['id'] as String? ?? '',
        activityId: json['activityId'] as String? ?? '',
        authorId: json['authorId'] as String? ?? '',
        authorName: json['authorName'] as String? ?? 'Anonymous',
        authorAvatarUrl: json['authorAvatarUrl'] as String?,
        authorRole: json['authorRole'] as String? ?? 'student',
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'activityId': activityId,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatarUrl': authorAvatarUrl,
        'authorRole': authorRole,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Interactive Campus Activity Post.
class ActivityPostModel {
  final String id;
  final String title;
  final String description;
  final ActivityCategory category;
  final String authorId;
  final String authorName;
  final String authorRole;
  final bool isOfficial;
  final ActivityStatus status;
  final DateTime? eventDate;
  final String? location;
  final String? organizer;
  final List<String> targetCourseIds;
  final List<String> targetBatchIds;
  final List<int> targetSemesters;
  final List<String> attachmentUrls;
  final Map<String, int> reactionCounts; // {'like': 10, 'clap': 5, 'fire': 8}
  final Map<String, String> userReactions; // userId -> 'like' / 'clap' / 'fire'
  final List<String> interestedUids;
  final List<String> bookmarkedUids;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ActivityPostModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    this.isOfficial = false,
    this.status = ActivityStatus.approved,
    this.eventDate,
    this.location,
    this.organizer,
    this.targetCourseIds = const [],
    this.targetBatchIds = const [],
    this.targetSemesters = const [],
    this.attachmentUrls = const [],
    this.reactionCounts = const {},
    this.userReactions = const {},
    this.interestedUids = const [],
    this.bookmarkedUids = const [],
    this.commentCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivityPostModel.fromJson(Map<String, dynamic> json) =>
      ActivityPostModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? (json['content'] as String? ?? ''),
        category: ActivityCategory.fromString(json['category'] as String?),
        authorId: json['authorId'] as String? ?? '',
        authorName: json['authorName'] as String? ?? '',
        authorRole: json['authorRole'] as String? ?? 'student',
        isOfficial: json['isOfficial'] as bool? ?? false,
        status: ActivityStatus.fromString(json['status'] as String?),
        eventDate: json['eventDate'] != null
            ? DateTime.tryParse(json['eventDate'] as String)
            : null,
        location: json['location'] as String?,
        organizer: json['organizer'] as String?,
        targetCourseIds: (json['targetCourseIds'] as List<dynamic>?)
                ?.cast<String>()
                .toList() ??
            const [],
        targetBatchIds: (json['targetBatchIds'] as List<dynamic>?)
                ?.cast<String>()
                .toList() ??
            const [],
        targetSemesters: (json['targetSemesters'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [],
        attachmentUrls: (json['attachmentUrls'] as List<dynamic>?)
                ?.cast<String>()
                .toList() ??
            const [],
        reactionCounts: (json['reactionCounts'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toInt()),
            ) ??
            const {},
        userReactions: (json['userReactions'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v.toString()),
            ) ??
            const {},
        interestedUids: (json['interestedUids'] as List<dynamic>?)
                ?.cast<String>()
                .toList() ??
            const [],
        bookmarkedUids: (json['bookmarkedUids'] as List<dynamic>?)
                ?.cast<String>()
                .toList() ??
            const [],
        commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'content': description, // compatibility with legacy circulars
        'category': category.name,
        'authorId': authorId,
        'authorName': authorName,
        'authorRole': authorRole,
        'isOfficial': isOfficial,
        'status': status.name,
        'eventDate': eventDate?.toIso8601String(),
        'location': location,
        'organizer': organizer,
        'targetCourseIds': targetCourseIds,
        'targetBatchIds': targetBatchIds,
        'targetSemesters': targetSemesters,
        'attachmentUrls': attachmentUrls,
        'reactionCounts': reactionCounts,
        'userReactions': userReactions,
        'interestedUids': interestedUids,
        'bookmarkedUids': bookmarkedUids,
        'commentCount': commentCount,
        'publishDate': createdAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  ActivityPostModel copyWith({
    String? id,
    String? title,
    String? description,
    ActivityCategory? category,
    String? authorId,
    String? authorName,
    String? authorRole,
    bool? isOfficial,
    ActivityStatus? status,
    DateTime? eventDate,
    String? location,
    String? organizer,
    List<String>? targetCourseIds,
    List<String>? targetBatchIds,
    List<int>? targetSemesters,
    List<String>? attachmentUrls,
    Map<String, int>? reactionCounts,
    Map<String, String>? userReactions,
    List<String>? interestedUids,
    List<String>? bookmarkedUids,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ActivityPostModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        authorRole: authorRole ?? this.authorRole,
        isOfficial: isOfficial ?? this.isOfficial,
        status: status ?? this.status,
        eventDate: eventDate ?? this.eventDate,
        location: location ?? this.location,
        organizer: organizer ?? this.organizer,
        targetCourseIds: targetCourseIds ?? this.targetCourseIds,
        targetBatchIds: targetBatchIds ?? this.targetBatchIds,
        targetSemesters: targetSemesters ?? this.targetSemesters,
        attachmentUrls: attachmentUrls ?? this.attachmentUrls,
        reactionCounts: reactionCounts ?? this.reactionCounts,
        userReactions: userReactions ?? this.userReactions,
        interestedUids: interestedUids ?? this.interestedUids,
        bookmarkedUids: bookmarkedUids ?? this.bookmarkedUids,
        commentCount: commentCount ?? this.commentCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  int get totalReactions => reactionCounts.values.fold(0, (sum, count) => sum + count);
  bool isInterested(String userId) => interestedUids.contains(userId);
  bool isBookmarked(String userId) => bookmarkedUids.contains(userId);
  String? getUserReaction(String userId) => userReactions[userId];
  bool get isUpcoming => eventDate != null && eventDate!.isAfter(DateTime.now());
  bool get isPendingApproval => status == ActivityStatus.pending;
  bool get isApproved => status == ActivityStatus.approved;
}
