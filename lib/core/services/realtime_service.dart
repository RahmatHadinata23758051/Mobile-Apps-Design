import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hera/core/network/backend_endpoints.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class RealtimeService {
  RealtimeService();

  static const String _sensorMonitoringChannel = 'sensor-monitoring';
  static const String _sensorDataUpdatedEvent = 'SensorDataUpdated';
  static const String _newTestingDataEvent = 'new_testing_data';

  static final PusherChannelsFlutter _client =
      PusherChannelsFlutter.getInstance();

  static final StreamController<Map<String, dynamic>> _sensorController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<Map<String, dynamic>> _testingController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  static bool _initialized = false;
  static bool _subscribed = false;
  static bool _connected = false;
  static bool _connecting = false;
  static int _referenceCount = 0;

  Stream<Map<String, dynamic>> get sensorStream => _sensorController.stream;
  Stream<Map<String, dynamic>> get testingStream => _testingController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _connected;

  Future<void> connect() async {
    _referenceCount++;
    await _ensureConnected();
  }

  Future<void> disconnect() async {
    if (_referenceCount > 0) {
      _referenceCount--;
    }
    if (_referenceCount > 0) return;

    if (!_initialized) {
      _connected = false;
      _connectionController.add(false);
      return;
    }

    try {
      if (_subscribed) {
        await _client.unsubscribe(channelName: _sensorMonitoringChannel);
        _subscribed = false;
      }
      await _client.disconnect();
    } catch (error, stackTrace) {
      debugPrint('[Realtime] Disconnect error: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _connected = false;
      _connectionController.add(false);
    }
  }

  Future<void> _ensureConnected() async {
    if (_connected || _connecting) return;
    _connecting = true;

    try {
      if (!_initialized) {
        final wsUri = _resolveUri(BackendEndpoints.wsBaseUrl);
        final useTls =
            BackendEndpoints.wsUseTls ||
            wsUri.scheme == 'https' ||
            wsUri.scheme == 'wss';

        await _client.init(
          apiKey: BackendEndpoints.wsAppKey,
          cluster: BackendEndpoints.wsAppCluster,
          useTLS: useTls,
          onConnectionStateChange: (currentState, previousState) {
            final nowConnected = currentState == 'CONNECTED';
            _connected = nowConnected;
            _connectionController.add(nowConnected);
            debugPrint('[Realtime] State $previousState -> $currentState');
          },
          onEvent: (event) {
            final normalizedEvent = _normalizeEventName(event.eventName);
            final payload = _decodeMap(event.data);
            if (payload == null) return;

            if (normalizedEvent == _sensorDataUpdatedEvent) {
              _sensorController.add(payload);
            } else if (normalizedEvent == _newTestingDataEvent) {
              _testingController.add(payload);
            }
          },
          onError: (message, code, error) {
            _connected = false;
            _connectionController.add(false);
            debugPrint(
              '[Realtime] Error code=$code message=$message error=$error',
            );
          },
          onSubscriptionSucceeded: (channelName, data) {
            debugPrint('[Realtime] Subscribed to $channelName');
          },
          onSubscriptionError: (message, error) {
            debugPrint('[Realtime] Subscription error: $message | $error');
          },
        );

        _initialized = true;
      }

      if (!_subscribed) {
        await _client.subscribe(channelName: _sensorMonitoringChannel);
        _subscribed = true;
      }

      await _client.connect();
    } catch (error, stackTrace) {
      _connected = false;
      _connectionController.add(false);
      debugPrint('[Realtime] Connect error: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      _connecting = false;
    }
  }

  String _normalizeEventName(String raw) {
    if (raw.startsWith('.')) return raw.substring(1);
    return raw;
  }

  Uri _resolveUri(String raw) {
    final normalized = raw.contains('://') ? raw : 'http://$raw';
    final uri = Uri.parse(normalized);
    if (uri.host.isEmpty) {
      throw ArgumentError('WS_BASE_URL tidak valid: $raw');
    }
    return uri;
  }

  Map<String, dynamic>? _decodeMap(dynamic payload) {
    if (payload == null) return null;

    if (payload is Map<String, dynamic>) {
      return payload;
    }

    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }

    if (payload is String && payload.isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        return null;
      }
    }

    return null;
  }
}
