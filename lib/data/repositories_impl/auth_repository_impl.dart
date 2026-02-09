import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  AuthRepositoryImpl(this._dio);

  @override
  Future<void> login(String email, String password) async {
    // fastapi expects formData for work
    final response = await _dio.post(
      '/auth/token',
      data: {
        'username': email, // field gotta be named username for oauth2 standarts
        'password': password,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final token = response.data['access_token'];
    await _storage.write(key: 'jwt_token', value: token);
  }

  @override
  Future<void> register(String email, String password, String username) async {
    await _dio.post(
      '/auth/register',
      data: {'email': email, 'password': password, 'username': username},
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
