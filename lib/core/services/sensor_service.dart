import 'package:dio/dio.dart';
import 'package:hera/core/models/sensor_history_result.dart';
import 'package:hera/core/models/sensor_reading.dart';
import 'package:hera/core/network/api_client.dart';
import 'package:hera/core/network/backend_endpoints.dart';
import 'package:hera/core/network/api_response.dart';
import 'package:hera/core/services/auth_service.dart';

class SensorService {
  final Dio _dio;

  SensorService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  Future<List<SensorReading>> fetchLatest() async {
    try {
      final response = await _dio.get(BackendEndpoints.sensorLatest);
      return _parseSensorListResponse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException();
      }
      throw ApiException(
        _extractErrorMessage(e, fallback: 'Gagal memuat data latest sensor.'),
      );
    }
  }

  Future<List<SensorReading>> fetchAlerts() async {
    try {
      final response = await _dio.get(BackendEndpoints.sensorAlerts);
      return _parseSensorListResponse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException();
      }
      throw ApiException(
        _extractErrorMessage(e, fallback: 'Gagal memuat data alert sensor.'),
      );
    }
  }

  Future<SensorHistoryResult> fetchHistory({
    DateTime? from,
    DateTime? to,
    int limit = 50,
    String? cursor,
    String? source,
  }) async {
    try {
      final nextPage = int.tryParse(cursor ?? '');
      final status = _mapSourceToStatus(source);
      final query = <String, dynamic>{
        'limit': limit,
        if (from != null) 'from_date': _formatBackendDate(from),
        if (to != null) 'to_date': _formatBackendDate(to),
        if (nextPage != null && nextPage > 0) 'page': nextPage,
        if (status != null) 'status': status,
      };

      final response = await _dio.get(
        BackendEndpoints.sensorHistory,
        queryParameters: query,
      );
      final body = response.data;

      if (body is List) {
        return SensorHistoryResult(
          items: _parseSensorList(body),
          nextCursor: null,
        );
      }

      if (body is! Map<String, dynamic>) {
        throw const ApiException('Format respon history tidak valid.');
      }

      final wrapped = ApiResponse<dynamic>.fromJson(body, (raw) => raw);
      final payload = wrapped.data;
      final nextCursor = _extractNextCursorFromMeta(body['meta']);

      if (payload is List) {
        return SensorHistoryResult(
          items: _parseSensorList(payload),
          nextCursor: nextCursor,
        );
      }

      if (payload is Map<String, dynamic>) {
        final dataList = payload['data'];
        return SensorHistoryResult(
          items:
              dataList is List ? _parseSensorList(dataList) : <SensorReading>[],
          nextCursor: payload['next_cursor']?.toString() ?? nextCursor,
        );
      }

      return const SensorHistoryResult(
        items: <SensorReading>[],
        nextCursor: null,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException();
      }
      throw ApiException(
        _extractErrorMessage(e, fallback: 'Gagal memuat data history sensor.'),
      );
    }
  }

  List<SensorReading> _parseSensorListResponse(dynamic body) {
    if (body is List) {
      return _parseSensorList(body);
    }

    if (body is! Map<String, dynamic>) {
      throw const ApiException('Format respon data sensor tidak valid.');
    }

    final wrapped = ApiResponse<dynamic>.fromJson(body, (raw) => raw);
    final payload = wrapped.data;

    if (payload is List) {
      return _parseSensorList(payload);
    }

    if (payload is Map<String, dynamic> && payload['data'] is List) {
      return _parseSensorList(payload['data'] as List);
    }

    return <SensorReading>[];
  }

  List<SensorReading> _parseSensorList(List rawList) {
    return rawList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(SensorReading.fromJson)
        .toList(growable: false);
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    final body = e.response?.data;
    if (body is Map<String, dynamic>) {
      final wrappedMessage = (body['message'] ?? '').toString();
      if (wrappedMessage.isNotEmpty) return wrappedMessage;

      final errors = body['errors'];
      if (errors is Map<String, dynamic>) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
        }
      }
    }
    return fallback;
  }

  String _formatBackendDate(DateTime value) {
    // Backend expects date-only query params (YYYY-MM-DD).
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String? _mapSourceToStatus(String? source) {
    if (source == null || source.trim().isEmpty) return null;
    final normalized = source.trim().toLowerCase();

    // Legacy value from older mobile build.
    if (normalized == 'postgres' || normalized == 'all') return 'all';

    if (normalized == 'normal' ||
        normalized == 'warning' ||
        normalized == 'danger') {
      return normalized;
    }

    return null;
  }

  String? _extractNextCursorFromMeta(dynamic meta) {
    if (meta is! Map<String, dynamic>) return null;
    final currentPage = _asInt(meta['current_page']);
    final lastPage = _asInt(meta['last_page']);
    if (currentPage == null || lastPage == null) return null;
    if (currentPage >= lastPage) return null;
    return (currentPage + 1).toString();
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
