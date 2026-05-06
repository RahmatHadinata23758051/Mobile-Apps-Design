import 'package:dio/dio.dart';
import 'package:hera/core/models/testing_history_result.dart';

import 'package:hera/core/network/auth_interceptor.dart';
import 'package:hera/core/network/auth_storage.dart';
import 'package:hera/core/network/backend_endpoints.dart';
import 'package:hera/core/services/auth_service.dart';

class TestService {
  final Dio _dio;

  TestService({Dio? dio}) : _dio = dio ?? _createTestingDio();

  static Dio _createTestingDio() {
    final options = BaseOptions(
      baseUrl: BackendEndpoints.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    return Dio(options)..interceptors.add(AuthInterceptor(const AuthStorage()));
  }

  Future<Map<String, dynamic>> sendTestingData({
    required double latitude,
    required double longitude,
    double? altitude,
    double? suhuAir,
    double? suhuLingkungan,
    double? kelembapan,
    double? ec,
    double? tds,
    double? ph,
    double? tegangan,
  }) async {
    if (!latitude.isFinite || !longitude.isFinite) {
      throw const ApiException('Koordinat lokasi tidak valid untuk dikirim.');
    }

    final requestData = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      // Keep key present to stay aligned with backend contract.
      'altitude': _sanitizeOptionalNumber(altitude),
      'suhu_air': _sanitizeOptionalNumber(suhuAir),
      'suhu_lingkungan': _sanitizeOptionalNumber(suhuLingkungan),
      'kelembapan': _sanitizeOptionalNumber(kelembapan),
      'ec': _sanitizeOptionalNumber(ec),
      'tds': _sanitizeOptionalNumber(tds),
      'ph': _sanitizeOptionalNumber(ph),
      'tegangan': _sanitizeOptionalNumber(tegangan),
    };

    try {
      final response = await _dio.post(
        BackendEndpoints.testingLocation,
        data: requestData,
      );

      final body = response.data;
      if (body is Map<String, dynamic>) {
        return body;
      }
      throw const ApiException('Format respon pengujian lokasi tidak valid.');
    } on DioException catch (e) {
      final body = e.response?.data;
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException();
      }
      if (body is Map<String, dynamic> && body['message'] != null) {
        throw ApiException(body['message'].toString());
      }
      throw const ApiException('Gagal terhubung ke server pengujian lokasi.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<TestingHistoryResult> fetchTestingHistory({
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final response = await _dio.get(
        BackendEndpoints.testingHistory,
        queryParameters: {
          'limit': limit,
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        },
      );
      final body = response.data;

      if (body is Map<String, dynamic>) {
        final payload = _extractHistoryPayload(body);
        if (payload != null) {
          final dataList = payload['data'];
          return TestingHistoryResult(
            items: dataList is List ? dataList : const <dynamic>[],
            nextCursor: _normalizeCursor(payload['next_cursor']),
          );
        }

        // Fallback for older API format if needed.
        final legacyPayload = body['data'];
        if (legacyPayload is List) {
          return TestingHistoryResult(items: legacyPayload, nextCursor: null);
        }
      }
      throw const ApiException('Format history pengujian tidak valid.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException();
      }
      throw ApiException(
        _extractErrorMessage(e, fallback: 'Gagal mengambil history pengujian.'),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    final body = e.response?.data;
    if (body is Map<String, dynamic>) {
      final message = body['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }
    return fallback;
  }

  Map<String, dynamic>? _extractHistoryPayload(Map<String, dynamic> body) {
    if (body['status'] == true && body['data'] is Map<String, dynamic>) {
      final wrapped = body['data'] as Map<String, dynamic>;
      if (wrapped['data'] is List) return wrapped;
    }

    if (body['data'] is Map<String, dynamic>) {
      final direct = body['data'] as Map<String, dynamic>;
      if (direct['data'] is List) return direct;
    }

    if (body['data'] is List) {
      return <String, dynamic>{
        'data': body['data'],
        'next_cursor': body['next_cursor'],
      };
    }

    return null;
  }

  String? _normalizeCursor(dynamic rawCursor) {
    final value = rawCursor?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  double? _sanitizeOptionalNumber(double? value) {
    if (value == null) return null;
    if (!value.isFinite) return null;
    return value;
  }
}
