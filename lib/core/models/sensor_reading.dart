class SensorReading {
  final int? id;
  final double? ec;
  final double? tds;
  final double? ph;
  final double? suhuAir;
  final double? suhuLingkungan;
  final double? kelembapan;
  final double? tegangan;
  final double? crEstimated;
  final String status;
  final DateTime? createdAt;

  const SensorReading({
    this.id,
    this.ec,
    this.tds,
    this.ph,
    this.suhuAir,
    this.suhuLingkungan,
    this.kelembapan,
    this.tegangan,
    this.crEstimated,
    required this.status,
    this.createdAt,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      id: _toInt(json['id']),
      ec: _toDouble(json['ec']),
      tds: _toDouble(json['tds']),
      ph: _toDouble(json['ph']),
      suhuAir: _toDouble(json['suhu_air']),
      suhuLingkungan: _toDouble(json['suhu_lingkungan']),
      kelembapan: _toDouble(json['kelembapan']),
      tegangan: _toDouble(json['tegangan']),
      crEstimated: _toDouble(json['cr_estimated']),
      status: (json['status'] ?? 'unknown').toString(),
      createdAt: _toDateTime(json['created_at'] ?? json['timestamp']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
