import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register(String email, String password, String username);

  Future<List<String>> getAvailableTags();
  Future<void> completeOnboarding(List<String> tags);

  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String token, String newPassword);
  Future<void> logout();
  Future<bool> checkAuth();
}
