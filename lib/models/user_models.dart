// models/user_model.dart
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String fireStation;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime? approvedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.fireStation,
    required this.isApproved,
    required this.createdAt,
    this.approvedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'fireStation': fireStation,
      'isApproved': isApproved,
      'createdAt': createdAt,
      'approvedAt': approvedAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      fireStation: map['fireStation'] ?? '',
      isApproved: map['isApproved'] ?? false,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      approvedAt: map['approvedAt']?.toDate(),
    );
  }
}