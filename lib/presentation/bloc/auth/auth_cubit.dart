import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit(this.authRepository) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      await authRepository.login(email, password);
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError("Login failed. Check your credentials."));
    }
  }

  Future<void> register(String email, String password, String username) async {
    emit(AuthLoading());
    try {
      await authRepository.register(email, password, username);
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError("Registration failed."));
    }
  }

  void logout() async {
    await authRepository.logout();
    emit(AuthInitial());
  }
}
