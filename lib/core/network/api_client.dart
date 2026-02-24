import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    // interpretator for auto token injection
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          AppLogger.info(
            'HTTP ${options.method} ${options.path}',
            name: 'ApiClient',
          );
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            AppLogger.warning(
              'Authorization error: token is invalid',
              name: 'ApiClient',
            );
          }
          AppLogger.error(
            'HTTP error ${e.requestOptions.method} ${e.requestOptions.path}',
            error: e,
            stackTrace: e.stackTrace,
            name: 'ApiClient',
          );
          return handler.next(e);
        },
      ),
    );
  }
}
