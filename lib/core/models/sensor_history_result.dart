import 'package:hera/core/models/sensor_reading.dart';

class SensorHistoryResult {
  final List<SensorReading> items;
  final String? nextCursor;

  const SensorHistoryResult({required this.items, this.nextCursor});
}
