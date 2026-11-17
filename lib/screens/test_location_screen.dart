import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hera/core/services/auth_service.dart';
import 'package:hera/core/services/location_security_service.dart';
import 'package:hera/core/services/test_service.dart';
import 'package:hera/core/services/sensor_service.dart';
import 'package:hera/core/services/realtime_service.dart';
import 'package:hera/core/models/sensor_reading.dart';

const _kPrimary = Color(0xFF006948);
const _kPrimaryLight = Color(0xFF009664);
const _kBackground = Color(0xFFF4F7F5);
const _kSurface = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFF5F6E65);

class TestLocationScreen extends StatefulWidget {
  const TestLocationScreen({super.key});

  @override
  State<TestLocationScreen> createState() => _TestLocationScreenState();
}

class _TestLocationScreenState extends State<TestLocationScreen> {
  final TestService _testService = TestService();
  final SensorService _sensorService = SensorService();
  final LocationSecurityService _locationSecurityService = LocationSecurityService();

  double? _latitude;
  double? _longitude;
  double? _altitude;
  bool _isLoading = false;
  String _statusMessage = "Siap mengambil titik pengujian.";
  Color _statusColor = const Color(0xFF6B7280);

  SensorReading? _latestReading;
  final RealtimeService _realtimeService = RealtimeService();
  StreamSubscription<Map<String, dynamic>>? _sensorSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialLatest();
    _fetchInitialLocation();
    _initRealtime();
  }

  Future<void> _initRealtime() async {
    _sensorSubscription?.cancel();
    _connectionSubscription?.cancel();

    _sensorSubscription = _realtimeService.sensorStream.listen((json) {
      if (!mounted || _isDisposed) return;
      try {
        setState(() => _latestReading = SensorReading.fromJson(json));
      } catch (e) {
        debugPrint('[Realtime] Error parsing data test location: $e');
      }
    });

    _connectionSubscription = _realtimeService.connectionStream.listen((_) {});

    try {
      await _realtimeService.connect();
    } catch (e) {
      debugPrint('[Realtime] Gagal konek di test location: $e');
    }
  }

  Future<void> _fetchInitialLatest() async {
    try {
      final results = await _sensorService.fetchLatest();
      if (results.isNotEmpty && mounted) setState(() => _latestReading = results.first);
    } catch (_) {}
  }

  Future<Position> _resolveCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw const ApiException("Layanan lokasi tidak aktif.");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw const ApiException("Izin lokasi ditolak.");
    }
    if (permission == LocationPermission.deniedForever) throw const ApiException("Izin lokasi ditolak secara permanen.");

    final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    final securityMessage = await _locationSecurityService.validatePosition(position);
    if (securityMessage != null) throw ApiException(securityMessage);
    return position;
  }

  Future<void> _fetchInitialLocation() async {
    try {
      final position = await _resolveCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _altitude = _resolveAltitude(position.altitude);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _statusMessage = e.message; _statusColor = Colors.orange.shade700; });
    } catch (_) {}
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sensorSubscription?.cancel();
    _connectionSubscription?.cancel();
    unawaited(_realtimeService.disconnect());
    super.dispose();
  }

  Future<void> _fetchAndSendTestData() async {
    setState(() { _isLoading = true; _statusMessage = "Memvalidasi keamanan lokasi..."; _statusColor = _kPrimary; });

    try {
      final position = await _resolveCurrentPosition();
      final altitude = _resolveAltitude(position.altitude);
      final altitudeMissing = altitude == null;

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _altitude = altitude;
        _statusMessage = "Mengirim data uji sensor secara terintegrasi...";
      });

      final response = await _testService.sendTestingData(
        latitude: position.latitude, longitude: position.longitude, altitude: altitude,
        suhuAir: _latestReading?.suhuAir, suhuLingkungan: _latestReading?.suhuLingkungan,
        kelembapan: _latestReading?.kelembapan, ec: _latestReading?.ec,
        tds: _latestReading?.tds, ph: _latestReading?.ph, tegangan: _latestReading?.tegangan,
      );

      if (mounted) {
        setState(() {
          final baseMessage = response['message']?.toString() ?? "Data pengujian berhasil terekam!";
          _statusMessage = altitudeMissing ? "$baseMessage (Altitude dipaksa lewat emulator)" : baseMessage;
          _statusColor = Colors.green.shade600;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_statusMessage), backgroundColor: Colors.green.shade700));
      }
    } on UnauthorizedException {
      await AuthService().clearLocalSession();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() { _statusMessage = e.message; _statusColor = Colors.red.shade600; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700));
      }
    } catch (e) {
      if (mounted) setState(() { _statusMessage = "Kesalahan integrasi: $e"; _statusColor = Colors.red.shade600; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double? _resolveAltitude(double? rawAltitude) {
    if (rawAltitude == null) return null;
    if (!rawAltitude.isFinite) return null;
    return rawAltitude;
  }

  Widget _buildSensorCard(String label, String value, String unit, {double? width, required double scale, Color? accentColor}) {
    final effectiveAccent = accentColor ?? _kPrimary;
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: 10 * scale, horizontal: 10 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11 * scale,
              fontWeight: FontWeight.w600,
              color: effectiveAccent,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                SizedBox(width: 3 * scale),
                Text(
                  unit,
                  style: GoogleFonts.poppins(
                    fontSize: 10 * scale,
                    fontWeight: FontWeight.w500,
                    color: _kTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGpsItem({required String label, required String value, required double scale}) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: (11 * scale).clamp(10.0, 12.0),
                color: _kTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4 * scale),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: (12 * scale).clamp(10.0, 13.0),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        title: Text(
          "Pengujian Lapangan",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double sw = MediaQuery.of(context).size.width;
          final double scale = (sw / 400).clamp(0.7, 1.2);

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.0 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sensor Section Header Banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16 * scale),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kPrimary, _kPrimaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8 * scale),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.sensors_rounded, size: 24 * scale, color: Colors.white),
                      ),
                      SizedBox(width: 12 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tinjauan Sensor Aktual",
                              style: GoogleFonts.poppins(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "Data telemetri langsung terhubung ke IoT",
                              style: GoogleFonts.poppins(
                                fontSize: 11 * scale,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16 * scale),

                // Sensor Grid
                if (_latestReading == null)
                  Container(
                    padding: EdgeInsets.all(24 * scale),
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2.2),
                        ),
                        SizedBox(width: 12 * scale),
                        Text(
                          "Memindai sensor dari air...",
                          style: GoogleFonts.poppins(
                            fontSize: 13 * scale,
                            color: _kTextSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Builder(builder: (context) {
                    double itemWidth = (sw - 40 * scale - 24 * scale) / 3;
                    return Container(
                      padding: EdgeInsets.all(16 * scale),
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Wrap(
                        spacing: 10 * scale,
                        runSpacing: 10 * scale,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildSensorCard("pH", _latestReading!.ph?.toStringAsFixed(1) ?? "-", "", width: itemWidth, scale: scale, accentColor: const Color(0xFF0284C7)),
                          _buildSensorCard("TDS", _latestReading!.tds?.toStringAsFixed(0) ?? "-", "ppm", width: itemWidth, scale: scale, accentColor: const Color(0xFF0EA5E9)),
                          _buildSensorCard("Suhu Air", _latestReading!.suhuAir?.toStringAsFixed(1) ?? "-", "°C", width: itemWidth, scale: scale, accentColor: const Color(0xFF059669)),
                          _buildSensorCard("Suhu Udara", _latestReading!.suhuLingkungan?.toStringAsFixed(1) ?? "-", "°C", width: itemWidth, scale: scale, accentColor: const Color(0xFFEA580C)),
                          _buildSensorCard("Kelembapan", _latestReading!.kelembapan?.toStringAsFixed(1) ?? "-", "%", width: itemWidth, scale: scale, accentColor: const Color(0xFF0D9488)),
                          _buildSensorCard("EC", _latestReading!.ec?.toStringAsFixed(2) ?? "-", "mS", width: itemWidth, scale: scale, accentColor: const Color(0xFFD97706)),
                          _buildSensorCard("Tegangan", _latestReading!.tegangan?.toStringAsFixed(2) ?? "-", "V", width: itemWidth, scale: scale, accentColor: const Color(0xFF7C3AED)),
                          _buildSensorCard("Cr(VI) Est.", _latestReading!.crEstimated?.toStringAsFixed(3) ?? "-", "µg/L", width: itemWidth, scale: scale, accentColor: _kPrimary),
                          _buildSensorCard("Ni Est.", _latestReading!.niEstimated?.toStringAsFixed(3) ?? "-", "µg/L", width: itemWidth, scale: scale, accentColor: const Color(0xFF4338CA)),
                        ],
                      ),
                    );
                  }),

                SizedBox(height: 20 * scale),

                // GPS Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Icon(Icons.satellite_alt_rounded, size: 16, color: _kPrimary),
                      const SizedBox(width: 6),
                      Text(
                        "KOORDINAT GPS LAPANGAN",
                        style: GoogleFonts.poppins(
                          fontSize: 11 * scale,
                          fontWeight: FontWeight.w700,
                          color: _kTextSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10 * scale),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16 * scale, horizontal: 16 * scale),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildGpsItem(
                        label: "Latitude",
                        value: _latitude != null ? _latitude!.toStringAsFixed(6) : "Belum didapat",
                        scale: scale,
                      ),
                      Container(width: 1, height: 36 * scale, color: const Color(0xFFE2E8F0)),
                      _buildGpsItem(
                        label: "Longitude",
                        value: _longitude != null ? _longitude!.toStringAsFixed(6) : "Belum didapat",
                        scale: scale,
                      ),
                      Container(width: 1, height: 36 * scale, color: const Color(0xFFE2E8F0)),
                      _buildGpsItem(
                        label: "Altitude",
                        value: _altitude != null ? "${_altitude!.toStringAsFixed(2)} m" : "Belum didapat",
                        scale: scale,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 22 * scale),

                // Status Message
                if (_statusMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _statusColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16 * scale, color: _statusColor),
                        SizedBox(width: 8 * scale),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12 * scale,
                              color: _statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 18 * scale),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52 * scale,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fetchAndSendTestData,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20 * scale,
                            height: 20 * scale,
                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : Icon(Icons.cloud_upload_rounded, size: 20 * scale),
                    label: Text(
                      _isLoading ? "Merekam Validasi..." : "Simpan Data Pengujian",
                      style: GoogleFonts.poppins(fontSize: 15 * scale, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      shadowColor: _kPrimary.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                SizedBox(height: 8 * scale),
              ],
            ),
          );
        },
      ),
    );
  }
}
