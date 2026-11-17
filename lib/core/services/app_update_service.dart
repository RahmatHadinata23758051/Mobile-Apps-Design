import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hera/core/network/api_client.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class AppUpdateInfo {
  final bool updateAvailable;
  final String currentVersion;
  final int currentBuild;
  final String latestVersion;
  final int latestBuild;
  final String downloadUrl;
  final String changelog;
  final String? fileSize;
  final bool isForceUpdate;

  const AppUpdateInfo({
    required this.updateAvailable,
    required this.currentVersion,
    required this.currentBuild,
    required this.latestVersion,
    required this.latestBuild,
    required this.downloadUrl,
    required this.changelog,
    this.fileSize,
    required this.isForceUpdate,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json, String currentVer, int currentBld) {
    return AppUpdateInfo(
      updateAvailable: json['update_available'] == true,
      currentVersion: currentVer,
      currentBuild: currentBld,
      latestVersion: json['latest_version']?.toString() ?? currentVer,
      latestBuild: json['build_number'] is int
          ? json['build_number'] as int
          : int.tryParse(json['build_number']?.toString() ?? '0') ?? 0,
      downloadUrl: json['download_url']?.toString() ?? '',
      changelog: json['changelog']?.toString() ?? '',
      fileSize: json['file_size']?.toString(),
      isForceUpdate: json['is_force_update'] == true,
    );
  }
}

class AppUpdateService {
  final Dio _dio;

  AppUpdateService([Dio? dio]) : _dio = dio ?? ApiClient.dio;

  /// Check server for the latest APK version compared to installed version.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

      final response = await _dio.get(
        '/api/mobile/app-version/latest',
        queryParameters: {
          'version': currentVersion,
          'build_number': currentBuild,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true) {
          return AppUpdateInfo.fromJson(data, currentVersion, currentBuild);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[AppUpdateService] Error checking for updates: $e');
      return null;
    }
  }

  /// Download APK with progress callback and trigger Android Package Installer.
  Future<bool> downloadAndInstall({
    required String downloadUrl,
    required void Function(double progress, String downloadedSize, String totalSize) onProgress,
    required void Function(String message) onError,
  }) async {
    try {
      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final savePath = '${dir.path}/hera_update.apk';

      // Remove existing temp apk if any
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            final recMB = (received / (1024 * 1024)).toStringAsFixed(1);
            final totMB = (total / (1024 * 1024)).toStringAsFixed(1);
            onProgress(progress, '$recMB MB', '$totMB MB');
          } else {
            final recMB = (received / (1024 * 1024)).toStringAsFixed(1);
            onProgress(-1, '$recMB MB', 'Unknown');
          }
        },
      );

      // Open and trigger installation
      final result = await OpenFilex.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        debugPrint('[AppUpdateService] OpenFilex result: ${result.message}');
        if (result.type == ResultType.permissionDenied) {
          onError('Izin menginstal dari sumber tidak dikenal ditolak. Silakan berikan izin di Pengaturan Android.');
        } else {
          onError('Gagal membuka paket installer APK: ${result.message}');
        }
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[AppUpdateService] Download/install error: $e');
      onError('Terjadi kesalahan saat mengunduh pembaruan: $e');
      return false;
    }
  }
}
