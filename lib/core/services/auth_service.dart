import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hera/core/network/backend_endpoints.dart';
import 'package:hera/core/network/api_response.dart';
import 'package:hera/core/network/auth_interceptor.dart';
import 'package:hera/core/network/auth_storage.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    super.message = 'Sesi login berakhir. Silakan login kembali.',
  ]);
}

class ValidationApiException extends ApiException {
  final Map<String, String> fieldErrors;
  const ValidationApiException(super.message, this.fieldErrors);
}

class FeatureUnavailableException extends ApiException {
  final String feature;
  const FeatureUnavailableException({
    required this.feature,
    required String message,
  }) : super(message);
}

class LoginResult {
  final String token;
  final String username;
  final String email;

  const LoginResult({
    required this.token,
    required this.username,
    required this.email,
  });
}

class ChangePasswordResult {
  final bool forceLogout;
  final String message;

  const ChangePasswordResult({
    required this.forceLogout,
    required this.message,
  });
}

class StoredSession {
  final String token;
  final String? username;
  final String? email;

  const StoredSession({required this.token, this.username, this.email});
}

class AuthService {
  static const String _authBaseUrl = BackendEndpoints.authBaseUrl;
  static const String _loginPath = BackendEndpoints.login;
  static const String _registerPath = BackendEndpoints.register;
  static const String _profilePath = BackendEndpoints.profile;
  static const String _updateProfilePath = BackendEndpoints.me;
  static const String _logoutPath = BackendEndpoints.logout;
  static const String _changePasswordPath = BackendEndpoints.changePassword;

  final Dio _dio;
  final AuthStorage _authStorage;

  AuthService({Dio? dio, AuthStorage? authStorage})
    : _dio = dio ?? _createAuthDio(),
      _authStorage = authStorage ?? const AuthStorage();

  static Dio _createAuthDio() {
    final options = BaseOptions(
      baseUrl: _authBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    return Dio(options)..interceptors.add(AuthInterceptor(const AuthStorage()));
  }

  Future<LoginResult> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        _loginPath,
        data: {'email': usernameOrEmail, 'password': password},
        options: Options(extra: {'skipAuth': true}),
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const ApiException('Format respon login tidak valid.');
      }

      final data = _extractLoginPayload(body);
      final token = _extractToken(data);
      if (token.isEmpty) {
        throw const ApiException('Token login tidak ditemukan di response.');
      }

      final user = _extractUser(data);
      final username =
          (user['name'] ?? user['username'] ?? usernameOrEmail).toString();
      final email = (user['email'] ?? '').toString();

      await _authStorage.saveSession(
        token: token,
        username: username,
        email: email,
      );

      return LoginResult(token: token, username: username, email: email);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AuthService.login] baseUrl=${_dio.options.baseUrl} path=$_loginPath type=${e.type} '
          'status=${e.response?.statusCode} message=${e.message} data=${e.response?.data}',
        );
      }

      if (kIsWeb && e.response == null) {
        throw const ApiException(
          'Login gagal karena CORS/preflight backend. Cek konfigurasi CORS untuk endpoint auth mobile.',
        );
      }

      final message = _extractErrorMessage(e.response?.data);
      if (message.isNotEmpty) throw ApiException(message);
      throw const ApiException('Tidak dapat terhubung ke server login.');
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post(
        _registerPath,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
        options: Options(extra: {'skipAuth': true}),
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const ApiException('Format respon register tidak valid.');
      }

      _extractLoginPayload(body);
    } on DioException catch (e) {
      if (kIsWeb && e.response == null) {
        throw const ApiException(
          'Register gagal karena CORS/preflight backend. Pastikan backend menyala.',
        );
      }

      final body = e.response?.data;
      if (body is Map<String, dynamic> && body['errors'] is Map) {
        final rawErrors = body['errors'] as Map;
        final fieldErrors = <String, String>{};
        for (final entry in rawErrors.entries) {
          if (entry.value is List && (entry.value as List).isNotEmpty) {
            fieldErrors[entry.key.toString()] =
                (entry.value as List).first.toString();
          } else {
            fieldErrors[entry.key.toString()] = entry.value.toString();
          }
        }
        final msg = (body['message'] ?? 'Validasi gagal').toString();
        throw ValidationApiException(msg, fieldErrors);
      }

      final message = _extractErrorMessage(body);
      if (message.isNotEmpty) throw ApiException(message);
      throw const ApiException('Tidak dapat terhubung ke server registrasi.');
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get(_profilePath);
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const ApiException('Format respon profil tidak valid.');
      }

      final data = body['data'];
      if (data is Map<String, dynamic>) {
        if (data['user'] is Map<String, dynamic>) {
          return data['user'] as Map<String, dynamic>;
        }
        if (data.containsKey('id') &&
            data.containsKey('name') &&
            data.containsKey('email')) {
          return data;
        }
      }

      throw const ApiException('Data user tidak ditemukan di response.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _authStorage.clearSession();
        throw const UnauthorizedException();
      }
      final message = _extractErrorMessage(e.response?.data);
      if (message.isNotEmpty) throw ApiException(message);
      throw const ApiException('Tidak dapat terhubung ke server profil.');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      final response = await _dio.put(
        _updateProfilePath,
        data: {'name': name, 'email': email},
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const ApiException('Format respon update profil tidak valid.');
      }

      if (body['status'] == false) {
        final message = _extractErrorMessage(body);
        throw ApiException(
          message.isNotEmpty
              ? message
              : 'Gagal memperbarui profil. Silakan coba lagi.',
        );
      }

      final data = body['data'];
      Map<String, dynamic>? updatedUser;
      if (data is Map<String, dynamic>) {
        if (data['user'] is Map<String, dynamic>) {
          updatedUser = Map<String, dynamic>.from(data['user'] as Map);
        } else if (data.containsKey('name') && data.containsKey('email')) {
          updatedUser = Map<String, dynamic>.from(data);
        }
      }

      updatedUser ??= <String, dynamic>{'name': name, 'email': email};

      // Update secure storage local data
      final storedSession = await getStoredSession();
      if (storedSession != null) {
        await _authStorage.saveSession(
          token: storedSession.token,
          username: updatedUser['name']?.toString() ?? name,
          email: updatedUser['email']?.toString() ?? email,
        );
      }

      return updatedUser;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _authStorage.clearSession();
        throw const UnauthorizedException();
      }
      if (_isFeatureUnavailableStatus(e.response?.statusCode)) {
        throw const FeatureUnavailableException(
          feature: 'update_profile',
          message: 'Fitur edit profil belum tersedia di backend saat ini.',
        );
      }

      final body = e.response?.data;
      if (body is Map<String, dynamic> && body['errors'] is Map) {
        final rawErrors = body['errors'] as Map;
        final fieldErrors = <String, String>{};
        for (final entry in rawErrors.entries) {
          if (entry.value is List && (entry.value as List).isNotEmpty) {
            fieldErrors[entry.key.toString()] =
                (entry.value as List).first.toString();
          } else {
            fieldErrors[entry.key.toString()] = entry.value.toString();
          }
        }
        final msg = (body['message'] ?? 'Validasi update gagal').toString();
        throw ValidationApiException(msg, fieldErrors);
      }

      final message = _extractErrorMessage(e.response?.data);
      if (message.isNotEmpty) throw ApiException(message);
      throw const ApiException(
        'Tidak dapat terhubung ke server update profil.',
      );
    }
  }

  Future<ChangePasswordResult> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.put(
        _changePasswordPath,
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        },
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const ApiException('Format respon ganti password tidak valid.');
      }

      if (body['status'] != true) {
        final message = _extractErrorMessage(body);
        throw ApiException(
          message.isNotEmpty
              ? message
              : 'Gagal mengganti sandi. Silakan coba lagi.',
        );
      }

      final message = (body['message'] ?? 'Sandi berhasil diubah.').toString();
      final data = body['data'];
      final forceLogout =
          data is Map<String, dynamic> && data['force_logout'] == true;

      return ChangePasswordResult(forceLogout: forceLogout, message: message);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _authStorage.clearSession();
        throw const UnauthorizedException();
      }
      if (_isFeatureUnavailableStatus(e.response?.statusCode)) {
        throw const FeatureUnavailableException(
          feature: 'change_password',
          message: 'Fitur ubah katasandi belum tersedia di backend saat ini.',
        );
      }

      final body = e.response?.data;
      if (body is Map<String, dynamic> && body['errors'] is Map) {
        final rawErrors = body['errors'] as Map;
        final fieldErrors = <String, String>{};
        for (final entry in rawErrors.entries) {
          if (entry.value is List && (entry.value as List).isNotEmpty) {
            fieldErrors[entry.key.toString()] =
                (entry.value as List).first.toString();
          } else {
            fieldErrors[entry.key.toString()] = entry.value.toString();
          }
        }
        final msg =
            (body['message'] ?? 'Validasi ganti sandi gagal.').toString();
        throw ValidationApiException(msg, fieldErrors);
      }

      final message = _extractErrorMessage(e.response?.data);
      if (message.isNotEmpty) throw ApiException(message);
      throw const ApiException('Tidak dapat terhubung ke server update sandi.');
    }
  }

  Future<void> logout() async {
    DioException? networkError;

    try {
      await _dio.post(_logoutPath);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _authStorage.clearSession();
        throw const UnauthorizedException();
      }
      networkError = e;
    } finally {
      await _authStorage.clearSession();
    }

    if (networkError != null) {
      final message = _extractErrorMessage(networkError.response?.data);
      if (message.isNotEmpty) {
        throw ApiException(message);
      }
      throw const ApiException('Gagal terhubung ke server saat logout.');
    }
  }

  Future<void> clearLocalSession() {
    return _authStorage.clearSession();
  }

  Future<StoredSession?> getStoredSession() async {
    final token = await _authStorage.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    return StoredSession(
      token: token,
      username: await _authStorage.readUsername(),
      email: await _authStorage.readEmail(),
    );
  }

  String _extractToken(Map<String, dynamic> data) {
    final directKeys = ['token', 'access_token', 'bearer_token'];
    for (final key in directKeys) {
      final value = data[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    final nestedToken = data['auth'];
    if (nestedToken is Map<String, dynamic>) {
      for (final key in directKeys) {
        final value = nestedToken[key];
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      }
    }

    return '';
  }

  Map<String, dynamic> _extractLoginPayload(Map<String, dynamic> body) {
    final hasWrappedStatus = body.containsKey('status');
    if (hasWrappedStatus) {
      final apiResponse = ApiResponse<Map<String, dynamic>?>.fromJson(
        body,
        (raw) => raw is Map<String, dynamic> ? raw : <String, dynamic>{},
      );

      if (!apiResponse.status) {
        throw ApiException(
          apiResponse.message.isNotEmpty
              ? apiResponse.message
              : 'Login gagal. Silakan coba lagi.',
        );
      }

      return apiResponse.data ?? <String, dynamic>{};
    }

    return body;
  }

  String _extractErrorMessage(dynamic body) {
    if (body is! Map<String, dynamic>) return '';

    final message = (body['message'] ?? '').toString();
    if (message.isNotEmpty) return message;

    final errors = body['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
      }
    }

    return '';
  }

  Map<String, dynamic> _extractUser(Map<String, dynamic> data) {
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      return user;
    }
    return <String, dynamic>{};
  }

  bool _isFeatureUnavailableStatus(int? statusCode) {
    return statusCode == 404 || statusCode == 405;
  }
}
