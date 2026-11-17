import 'package:flutter_test/flutter_test.dart';
import 'package:hera/core/models/sensor_reading.dart';

void main() {
  group('SensorReading Model QC Unit Tests', () {
    test('Correctly deserializes JSON with Ni and Cr(VI) parameters', () {
      final json = {
        'id': 101,
        'suhu_air': 25.5,
        'suhu_lingkungan': 28.2,
        'kelembapan': 65.0,
        'ec': 350.0,
        'tds': 175.0,
        'ph': 7.3,
        'tegangan': 12.0,
        'cr_estimated': 24.5,
        'ni_estimated': 14.8,
        'status': 'normal',
        'created_at': '2026-11-17T17:00:00Z',
      };

      final reading = SensorReading.fromJson(json);

      expect(reading.id, 101);
      expect(reading.suhuAir, 25.5);
      expect(reading.suhuLingkungan, 28.2);
      expect(reading.kelembapan, 65.0);
      expect(reading.ec, 350.0);
      expect(reading.tds, 175.0);
      expect(reading.ph, 7.3);
      expect(reading.tegangan, 12.0);
      expect(reading.crEstimated, 24.5);
      expect(reading.niEstimated, 14.8);
      expect(reading.status, 'normal');
    });

    test('Correctly serializes back to JSON', () {
      final reading = SensorReading(
        id: 202,
        suhuAir: 26.0,
        suhuLingkungan: 30.0,
        kelembapan: 70.0,
        ec: 400.0,
        tds: 200.0,
        ph: 7.0,
        tegangan: 12.2,
        crEstimated: 45.2,
        niEstimated: 18.5,
        status: 'warning',
        createdAt: DateTime.parse('2026-11-17T17:00:00Z'),
      );

      final json = reading.toJson();

      expect(json['id'], 202);
      expect(json['cr_estimated'], 45.2);
      expect(json['ni_estimated'], 18.5);
      expect(json['status'], 'warning');
    });

    test('Handles null Ni and Cr without crashing', () {
      final json = {
        'suhu_air': 24.0,
        'ph': 6.8,
      };

      final reading = SensorReading.fromJson(json);

      expect(reading.crEstimated, null);
      expect(reading.niEstimated, null);
      expect(reading.status, 'unknown');
    });
  });
}
