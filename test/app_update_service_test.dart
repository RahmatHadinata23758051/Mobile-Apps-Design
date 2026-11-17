import 'package:flutter_test/flutter_test.dart';
import 'package:hera/core/services/app_update_service.dart';

void main() {
  group('AppUpdateInfo Model Tests', () {
    test('AppUpdateInfo deserializes correctly from API response', () {
      final json = {
        'status': true,
        'update_available': true,
        'current_client_version': '2.0.0',
        'current_client_build': 1,
        'latest_version': '2.1.0',
        'build_number': 3,
        'download_url': 'https://example.com/hera-v2.1.0.apk',
        'changelog': 'Pembaruan algoritma sensor Ni dan Cr(VI).',
        'file_size': '24.5 MB',
        'is_force_update': true,
        'released_at': '2026-11-17T18:00:00Z',
      };

      final info = AppUpdateInfo.fromJson(json, '2.0.0', 1);

      expect(info.updateAvailable, isTrue);
      expect(info.currentVersion, '2.0.0');
      expect(info.currentBuild, 1);
      expect(info.latestVersion, '2.1.0');
      expect(info.latestBuild, 3);
      expect(info.downloadUrl, 'https://example.com/hera-v2.1.0.apk');
      expect(info.changelog, contains('Ni dan Cr(VI)'));
      expect(info.fileSize, '24.5 MB');
      expect(info.isForceUpdate, isTrue);
    });

    test('AppUpdateInfo handles null fields gracefully', () {
      final json = {
        'status': true,
        'update_available': false,
        'build_number': '1',
      };

      final info = AppUpdateInfo.fromJson(json, '2.0.0', 1);

      expect(info.updateAvailable, isFalse);
      expect(info.currentVersion, '2.0.0');
      expect(info.currentBuild, 1);
      expect(info.latestVersion, '2.0.0');
      expect(info.latestBuild, 1);
      expect(info.downloadUrl, isEmpty);
      expect(info.changelog, isEmpty);
      expect(info.fileSize, isNull);
      expect(info.isForceUpdate, isFalse);
    });
  });
}
