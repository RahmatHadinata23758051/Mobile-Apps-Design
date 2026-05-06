import 'package:dio/dio.dart';
import 'package:hera/core/network/auth_storage.dart';

class AuthInterceptor extends Interceptor {
  final AuthStorage _authStorage;

  AuthInterceptor(this._authStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final shouldSkipAuth = options.extra['skipAuth'] == true;

    if (!shouldSkipAuth) {
      final token = await _authStorage.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _authStorage.clearSession();
    }

    handler.next(err);
  }
}
