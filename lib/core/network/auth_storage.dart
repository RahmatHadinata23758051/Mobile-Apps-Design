import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _tokenKey = 'auth_bearer_token';
  static const _usernameKey = 'auth_username';
  static const _emailKey = 'auth_email';

  const AuthStorage();

  FlutterSecureStorage get _storage => const FlutterSecureStorage();

  Future<void> saveSession({
    required String token,
    String? username,
    String? email,
  }) async {
    await _storage.write(key: _tokenKey, value: token);

    if (username != null && username.isNotEmpty) {
      await _storage.write(key: _usernameKey, value: username);
    }
    if (email != null && email.isNotEmpty) {
      await _storage.write(key: _emailKey, value: email);
    }
  }

  Future<String?> readToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<String?> readUsername() {
    return _storage.read(key: _usernameKey);
  }

  Future<String?> readEmail() {
    return _storage.read(key: _emailKey);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _emailKey);
  }
}
