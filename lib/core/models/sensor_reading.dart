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
  final double? niEstimated;
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
    this.niEstimated,
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
      niEstimated: _toDouble(json['ni_estimated']),
      status: (json['status'] ?? 'unknown').toString(),
      createdAt: _toDateTime(json['created_at'] ?? json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ec': ec,
      'tds': tds,
      'ph': ph,
      'suhu_air': suhuAir,
      'suhu_lingkungan': suhuLingkungan,
      'kelembapan': kelembapan,
      'tegangan': tegangan,
      'cr_estimated': crEstimated,
      'ni_estimated': niEstimated,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
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
