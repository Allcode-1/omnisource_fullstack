import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late Dio dio;
  final _storage = const FlutterSecureStorage();
  Future<String?>? _refreshInFlight;

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
        onError: (DioException e, handler) async {
          final startMs = e.requestOptions.extra['start_ms'] as int?;
          final duration = startMs == null
              ? -1
              : DateTime.now().millisecondsSinceEpoch - startMs;
          if (e.response?.statusCode == 401) {
            AppLogger.warning(
              'Authorization error: token is invalid',
              name: 'ApiClient',
            );
            final refreshedToken = await _refreshAccessTokenIfNeeded(e);
            if (refreshedToken != null) {
              try {
                final retryOptions = e.requestOptions;
                retryOptions.headers['Authorization'] =
                    'Bearer $refreshedToken';
                retryOptions.extra['auth_retry'] = true;
                retryOptions.extra['start_ms'] =
                    DateTime.now().millisecondsSinceEpoch;
                final response = await dio.fetch<dynamic>(retryOptions);
                return handler.resolve(response);
              } catch (retryError, retryStack) {
                AppLogger.error(
                  'HTTP retry after token refresh failed',
                  error: retryError,
                  stackTrace: retryStack,
                  name: 'ApiClient',
                );
              }
            }
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

  bool _canRefresh(DioException error) {
    if (error.response?.statusCode != 401) return false;
    if (error.requestOptions.extra['auth_retry'] == true) return false;
    final path = error.requestOptions.path;
    return path != ApiConstants.login &&
        path != ApiConstants.register &&
        path != ApiConstants.refresh &&
        path != ApiConstants.logout;
  }

  Future<String?> _refreshAccessTokenIfNeeded(DioException error) {
    if (!_canRefresh(error)) return Future.value(null);
    final pending = _refreshInFlight;
    if (pending != null) return pending;

    final future = _performTokenRefresh();
    _refreshInFlight = future;
    return future.whenComplete(() => _refreshInFlight = null);
  }

  Future<String?> _performTokenRefresh() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: dio.options.connectTimeout,
          receiveTimeout: dio.options.receiveTimeout,
        ),
      );
      final response = await refreshDio.post<Map<String, dynamic>>(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );

      final accessToken = response.data?['access_token']?.toString();
      final newRefreshToken = response.data?['refresh_token']?.toString();
      if (accessToken == null || accessToken.isEmpty) return null;

      await _storage.write(key: 'jwt_token', value: accessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.write(key: 'refresh_token', value: newRefreshToken);
      }
      AppLogger.info('Access token refreshed', name: 'ApiClient');
      return accessToken;
    } catch (e, st) {
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'refresh_token');
      AppLogger.error(
        'Token refresh failed; local session cleared',
        error: e,
        stackTrace: st,
        name: 'ApiClient',
      );
      return null;
    }
  }
}
