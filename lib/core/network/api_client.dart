import 'package:dio/dio.dart';
import 'package:hera/core/network/auth_interceptor.dart';
import 'package:hera/core/network/auth_storage.dart';
import 'package:hera/core/network/backend_endpoints.dart';

class ApiClient {
  static const String _baseUrl = BackendEndpoints.apiBaseUrl;

  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(AuthInterceptor(const AuthStorage()));
}
