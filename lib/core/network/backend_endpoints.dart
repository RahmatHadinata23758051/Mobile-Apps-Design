class BackendEndpoints {
  // Set API_BASE_URL via --dart-define or --dart-define-from-file=.env.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: apiBaseUrl,
  );

  static const String wsAppKey = String.fromEnvironment(
    'WS_APP_KEY',
    defaultValue: 'app-key',
  );

  static const String wsAppCluster = String.fromEnvironment(
    'WS_APP_CLUSTER',
    defaultValue: 'mt1',
  );

  static const bool wsUseTls = bool.fromEnvironment(
    'WS_USE_TLS',
    defaultValue: false,
  );

  // If AUTH_BASE_URL is not supplied, use API_BASE_URL so mobile stays
  // aligned to the same backend host.
  static const String authBaseUrl = String.fromEnvironment(
    'AUTH_BASE_URL',
    defaultValue: apiBaseUrl,
  );

  static const String login = String.fromEnvironment(
    'AUTH_LOGIN_PATH',
    defaultValue: '/api/mobile/login',
  );
  static const String register = String.fromEnvironment(
    'AUTH_REGISTER_PATH',
    defaultValue: '/api/mobile/register',
  );
  static const String me = String.fromEnvironment(
    'AUTH_ME_PATH',
    defaultValue: '/api/mobile/me',
  );
  static const String profile = String.fromEnvironment(
    'AUTH_PROFILE_PATH',
    defaultValue: '/api/mobile/profile',
  );
  static const String logout = String.fromEnvironment(
    'AUTH_LOGOUT_PATH',
    defaultValue: '/api/mobile/logout',
  );
  static const String changePassword = String.fromEnvironment(
    'AUTH_CHANGE_PASSWORD_PATH',
    defaultValue: '/api/mobile/password',
  );

  static const String sensorLatest = '/api/mobile/sensor/latest';
  static const String sensorAlerts = '/api/mobile/sensor/alerts';
  static const String sensorHistory = '/api/mobile/sensor/history';

  static const String testingLocation = '/api/mobile/testing/location';
  static const String testingHistory = '/api/mobile/testing/history';
}
