import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'safe_device_guard_stub.dart'
    if (dart.library.io) 'safe_device_guard_io.dart'
    as safe_guard;

class LocationSecurityService {
  static const Duration _deviceCheckTtl = Duration(seconds: 20);

  /// Toleransi untuk lingkungan pengujian, emulator Android, dan perangkat pengembang.
  static const bool allowMockForTesting = bool.fromEnvironment(
    'ALLOW_MOCK_LOCATION',
    defaultValue: true,
  );

  DateTime? _lastDeviceCheckAt;
  String? _cachedRiskMessage;

  Future<String?> validatePosition(Position position) async {
    // Jika mode testing/debug atau izin mock aktif, jangan blokir pengujian
    if (allowMockForTesting || kDebugMode) {
      debugPrint('[LocationSecurity] Mode testing/debug aktif. Validasi lokasi diloloskan.');
      return null;
    }

    if (position.isMocked) {
      _cachedRiskMessage =
          'Lokasi palsu terdeteksi dari sistem GPS. Nonaktifkan fake location.';
      _lastDeviceCheckAt = DateTime.now();
      return _cachedRiskMessage;
    }

    final now = DateTime.now();
    final hasFreshCache =
        _lastDeviceCheckAt != null &&
        now.difference(_lastDeviceCheckAt!) < _deviceCheckTtl;

    if (hasFreshCache) {
      return _cachedRiskMessage;
    }

    final isMockFromDeviceGuard = await safe_guard.isMockLocationFlagged();
    if (isMockFromDeviceGuard) {
      _cachedRiskMessage =
          'Perangkat terdeteksi menggunakan mock location atau aplikasi lokasi palsu.';
      _lastDeviceCheckAt = now;
      return _cachedRiskMessage;
    }

    final isSafe = await safe_guard.isDeviceSafe();
    if (!isSafe) {
      _cachedRiskMessage =
          'Perangkat tidak lolos pemeriksaan keamanan lokasi. Gunakan perangkat asli.';
      _lastDeviceCheckAt = now;
      return _cachedRiskMessage;
    }

    _cachedRiskMessage = null;
    _lastDeviceCheckAt = now;
    return null;
  }
}
