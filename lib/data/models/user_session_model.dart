import 'package:cloud_firestore/cloud_firestore.dart';

class UserSessionModel {
  final String sessionId;
  final String userId;
  final String deviceId;
  final DateTime loginAt;
  final bool isActive;

  UserSessionModel({
    required this.sessionId,
    required this.userId,
    required this.deviceId,
    required this.loginAt,
    required this.isActive,
  });

  factory UserSessionModel.fromMap(Map<String, dynamic> map) {
    return UserSessionModel(
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      deviceId: map['deviceId'] ?? '',
      loginAt: (map['loginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'deviceId': deviceId,
      'loginAt': Timestamp.fromDate(loginAt),
      'isActive': isActive,
    };
  }
}
