import 'package:flutter_test/flutter_test.dart';
import 'package:omnisource/core/network/api_client.dart';

void main() {
  test('ApiClient initializes dio with normalized base url and timeouts', () {
    final apiClient = ApiClient();

    expect(apiClient.dio.options.baseUrl.endsWith('/'), isFalse);
    expect(apiClient.dio.options.connectTimeout, const Duration(seconds: 60));
    expect(apiClient.dio.options.receiveTimeout, const Duration(seconds: 60));
    expect(apiClient.dio.interceptors.isNotEmpty, isTrue);
  });
}
