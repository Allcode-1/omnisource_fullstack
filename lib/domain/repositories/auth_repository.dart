abstract class AuthRepository {
  // login by email and password
  Future<void> login(String email, String password);

  // new user regist
  Future<void> register(String email, String password, String username);

  // Вlogout (token deleting)
  Future<void> logout();

  // check if user authenticated (token exists)
  Future<bool> checkAuth();
}
