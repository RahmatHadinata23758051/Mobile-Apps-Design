import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:hera/core/network/auth_interceptor.dart';
import 'package:hera/core/network/auth_storage.dart';
import 'package:hera/core/network/backend_endpoints.dart';

class ApiClient {
  static const String _baseUrl = BackendEndpoints.apiBaseUrl;

  ApiClient._();

  static Dio createDio([String? baseUrl]) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? _baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Bypass SSL handshake errors for self-signed or staging IP certificates
    if (dio.httpClientAdapter is IOHttpClientAdapter) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    dio.interceptors.add(AuthInterceptor(const AuthStorage()));
    return dio;
  }

  static final Dio dio = createDio();
}
