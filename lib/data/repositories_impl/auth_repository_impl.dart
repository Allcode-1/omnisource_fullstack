import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  AuthRepositoryImpl(this._dio);

  @override
  Future<User> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': email, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final token = response.data['access_token'];
    await _storage.write(key: 'jwt_token', value: token);

    return UserModel.fromJson(response.data['user']);
  }

  @override
  Future<User> register(String email, String password, String username) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'email': email, 'password': password, 'username': username},
    );
    final token = response.data['access_token'];
    if (token != null) {
      await _storage.write(key: 'jwt_token', value: token);
    }

    return UserModel.fromJson(response.data['user']);
  }

  @override
  Future<void> completeOnboarding(List<String> tags) async {
    final token = await _storage.read(key: 'jwt_token');

    await _dio.post(
      '/user/complete-onboarding',
      data: {'interests': tags},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return null;
      final response = await _dio.get(
        '/user/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error with getting user: $e");
      return null;
    }
  }

  @override
  Future<List<String>> getAvailableTags() async {
    try {
      final response = await _dio.get('/user/tags');

      if (response.statusCode == 200) {
        return List<String>.from(response.data);
      }
      return [];
    } catch (e) {
      print("Error while loading tags: $e");
      return [];
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    await _dio.post(
      '/auth/reset-password',
      data: {'token': token, 'new_password': newPassword},
    );
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  @override
  Future<bool> checkAuth() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }
}
