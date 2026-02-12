import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit(this.authRepository) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(email, password);
      emit(AuthAuthenticated(needsOnboarding: !user.isOnboardingCompleted));
    } catch (e) {
      emit(AuthError("Login failed. Check your credentials."));
    }
  }

  Future<void> register(String email, String password, String username) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.register(email, password, username);
      emit(AuthAuthenticated(needsOnboarding: !user.isOnboardingCompleted));
    } catch (e) {
      emit(AuthError("Registration failed."));
    }
  }

  Future<void> completeOnboarding(List<String> tags) async {
    emit(AuthLoading());
    try {
      await authRepository.completeOnboarding(tags);
      print("Onboarding success!");
      emit(AuthAuthenticated(needsOnboarding: false));
    } catch (e) {
      print("onboarding error: $e");
      emit(AuthError("Failed to save your preferences."));
      emit(AuthAuthenticated(needsOnboarding: true));
    }
  }

  Future<void> forgotPassword(String email) async {
    emit(AuthLoading());
    try {
      await authRepository.forgotPassword(email);
      emit(AuthInitial()); // Чтобы вернуться в обычное состояние
    } catch (e) {
      emit(AuthError("Failed to send reset email"));
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    emit(AuthLoading());
    try {
      await authRepository.resetPassword(token, newPassword);
      emit(AuthInitial()); // После смены пароля — на логин
    } catch (e) {
      emit(AuthError("Invalid token or password reset failed"));
    }
  }

  void logout() async {
    await authRepository.logout();
    emit(AuthInitial());
  }
}
