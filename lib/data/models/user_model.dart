import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.email,
    required super.username,
    required super.isOnboardingCompleted,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      isOnboardingCompleted: json['isOnboardingCompleted'] ?? false,
    );
  }
}
