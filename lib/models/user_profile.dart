import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, teacher, admin }

class UserProfile {
  final String uid;
  final String name;
  final UserRole role;
  final String? photoUrl;
  final String? themeColorHex;

  UserProfile({
    required this.uid,
    required this.name,
    required this.role,
    this.photoUrl,
    this.themeColorHex,
  });

  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      role: _roleFromString(data['role'] as String? ?? 'student'),
      photoUrl: data['photoUrl'] as String?,
      themeColorHex: data['themeColorHex'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role.toString().split('.').last,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (themeColorHex != null) 'themeColorHex': themeColorHex,
      };

  static UserRole _roleFromString(String role) {
    switch (role) {
      case 'teacher':
        return UserRole.teacher;
      case 'admin':
        return UserRole.admin;
      case 'student':
      default:
        return UserRole.student;
    }
  }
}
