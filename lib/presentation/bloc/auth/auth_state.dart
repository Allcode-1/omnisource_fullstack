abstract class AuthState {}

class AuthInitial extends AuthState {} // user just launched app

class AuthLoading extends AuthState {} // wait for backend response

class AuthAuthenticated extends AuthState {} // loginned correctly

class AuthError extends AuthState {
  // error (unvalid password or sum)
  final String message;
  AuthError(this.message);
}
