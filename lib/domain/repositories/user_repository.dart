import '../entities/user.dart';

abstract class UserRepository {
  Future<User> getMe();
  Future<User> updateProfile({String? username, List<String>? interests});
  Future<void> deleteAccount();
}
