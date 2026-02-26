import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiClient() {
    final normalizedBaseUrl = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
        : ApiConstants.baseUrl;

    dio = Dio(
      BaseOptions(
        baseUrl: normalizedBaseUrl,
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
          options.extra['start_ms'] = DateTime.now().millisecondsSinceEpoch;
          AppLogger.info(
            'HTTP ${options.method} ${options.path} q=${options.queryParameters.isEmpty ? '-' : options.queryParameters.keys.join(',')}',
            name: 'ApiClient',
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final startMs = response.requestOptions.extra['start_ms'] as int?;
          final duration = startMs == null
              ? -1
              : DateTime.now().millisecondsSinceEpoch - startMs;
          AppLogger.info(
            'HTTP ${response.requestOptions.method} ${response.requestOptions.path} -> ${response.statusCode} (${duration}ms)',
            name: 'ApiClient',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final startMs = e.requestOptions.extra['start_ms'] as int?;
          final duration = startMs == null
              ? -1
              : DateTime.now().millisecondsSinceEpoch - startMs;
          if (e.response?.statusCode == 401) {
            AppLogger.warning(
              'Authorization error: token is invalid',
              name: 'ApiClient',
            );
          }
          final status = e.response?.statusCode?.toString() ?? 'no_status';
          final rawBody = e.response?.data?.toString() ?? '';
          final bodySnippet = rawBody.isEmpty
              ? ''
              : ' body=${rawBody.length > 120 ? rawBody.substring(0, 120) : rawBody}';
          AppLogger.error(
            'HTTP error ${e.requestOptions.method} ${e.requestOptions.path} -> $status (${duration}ms)$bodySnippet',
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
