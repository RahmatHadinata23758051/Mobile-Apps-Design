import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hera/core/models/sensor_reading.dart';
import 'package:hera/core/services/auth_service.dart';
import 'package:hera/core/services/realtime_service.dart';
import 'package:hera/core/services/sensor_service.dart';

const _kPrimary = Color(0xFF006948);
const _kBackground = Color(0xFFF4F7F5);
const _kSurface = Color(0xFFFFFFFF);
const _kTextPrimary = Color(0xFF191C1E);
const _kTextSecondary = Color(0xFF5F6E65);
const _kIndigo = Color(0xFF4338CA);

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen>
    with WidgetsBindingObserver {
  final SensorService _sensorService = SensorService();
  final AuthService _authService = AuthService();
  final RealtimeService _realtimeService = RealtimeService();

  bool _isLoading = true;
  bool _isFetchingLatest = false;
  String? _errorMessage;
  SensorReading? _latestReading;

  StreamSubscription<Map<String, dynamic>>? _sensorSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  bool _isConnected = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLatestSensor();
    _initRealtime();
  }

  Future<void> _initRealtime() async {
    _sensorSubscription?.cancel();
    _connectionSubscription?.cancel();

    _sensorSubscription = _realtimeService.sensorStream.listen((json) {
      if (!mounted || _isDisposed) return;
      try {
        final reading = SensorReading.fromJson(json);
        setState(() {
          _latestReading = reading;
          _isLoading = false;
          _errorMessage = null;
        });
      } catch (e) {
        debugPrint('[Realtime] Error parsing data monitoring: $e');
      }
    });

    _connectionSubscription = _realtimeService.connectionStream.listen((connected) {
      if (!mounted || _isDisposed) return;
      setState(() => _isConnected = connected);
    });

    if (_realtimeService.isConnected && !_isConnected) {
      setState(() => _isConnected = true);
    }

    try {
      await _realtimeService.connect();
      if (!mounted || _isDisposed) return;
      if (_realtimeService.isConnected != _isConnected) {
        setState(() => _isConnected = _realtimeService.isConnected);
      }
    } catch (e) {
      debugPrint('[Realtime] Gagal konek di monitoring: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sensorSubscription?.cancel();
    _connectionSubscription?.cancel();
    unawaited(_realtimeService.disconnect());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadLatestSensor({bool showLoader = true}) async {
    if (_isFetchingLatest) return;
    _isFetchingLatest = true;

    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final latest = await _sensorService.fetchLatest();
      if (!mounted) return;
      setState(() {
        _latestReading = latest.isNotEmpty ? latest.first : null;
        _isLoading = false;
      });
    } on UnauthorizedException {
      await _authService.clearLocalSession();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (showLoader || _latestReading == null) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      if (showLoader || _latestReading == null) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan saat memuat data monitoring.';
          _isLoading = false;
        });
      }
    } finally {
      _isFetchingLatest = false;
    }
  }

  String _formatNumber(double? value, {int fractionDigits = 2}) {
    if (value == null) return '-';
    return value.toStringAsFixed(fractionDigits);
  }

  String _classifyCr(double? val) {
    if (val == null) return 'NORMAL';
    if (val >= 100.0) return 'BAHAYA';
    if (val >= 50.0) return 'WASPADA';
    return 'NORMAL';
  }

  String _classifyNi(double? val) {
    if (val == null) return 'NORMAL';
    if (val >= 70.0) return 'BAHAYA';
    if (val >= 20.0) return 'WASPADA';
    return 'NORMAL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _kPrimary,
        title: Text(
          'Monitoring Telemetri',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _loadLatestSensor(showLoader: false),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Manual',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: _kTextSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadLatestSensor,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_latestReading == null) {
      return Center(
        child: Text(
          'Belum ada data sensor.',
          style: GoogleFonts.poppins(fontSize: 14, color: _kTextSecondary),
        ),
      );
    }

    final r = _latestReading!;
    final crStatus = _classifyCr(r.crEstimated);
    final niStatus = _classifyNi(r.niEstimated);

    final physicalSensors = <_SensorItem>[
      _SensorItem(label: 'pH Air', value: _formatNumber(r.ph, fractionDigits: 2), unit: '', icon: Icons.science_outlined, color: const Color(0xFF0284C7)),
      _SensorItem(label: 'TDS (Padatan)', value: _formatNumber(r.tds, fractionDigits: 1), unit: 'ppm', icon: Icons.water_drop_outlined, color: const Color(0xFF0EA5E9)),
      _SensorItem(label: 'EC (Daya Hantar)', value: _formatNumber(r.ec, fractionDigits: 1), unit: 'µS/cm', icon: Icons.electric_bolt_outlined, color: const Color(0xFFD97706)),
      _SensorItem(label: 'Suhu Air', value: _formatNumber(r.suhuAir, fractionDigits: 1), unit: '°C', icon: Icons.thermostat_outlined, color: const Color(0xFF059669)),
      _SensorItem(label: 'Suhu Udara', value: _formatNumber(r.suhuLingkungan, fractionDigits: 1), unit: '°C', icon: Icons.wb_sunny_outlined, color: const Color(0xFFEA580C)),
      _SensorItem(label: 'Kelembapan', value: _formatNumber(r.kelembapan, fractionDigits: 1), unit: '%', icon: Icons.cloud_outlined, color: const Color(0xFF0D9488)),
      _SensorItem(label: 'Tegangan Sensor', value: _formatNumber(r.tegangan, fractionDigits: 2), unit: 'V', icon: Icons.battery_charging_full_rounded, color: const Color(0xFF7C3AED)),
    ];

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () => _loadLatestSensor(showLoader: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Bar Live
            _buildLiveStatusBar(r.status),
            const SizedBox(height: 16),

            // Section 1: Heavy Metal Insights
            Row(
              children: [
                const Icon(Icons.memory_rounded, size: 18, color: _kPrimary),
                const SizedBox(width: 8),
                Text(
                  'PREDIKSI LOGAM BERAT (AI)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: _kTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Dual Heavy Metal Cards (Cr & Ni)
            _buildHeavyMetalCard(
              title: 'Chromium Heksavalent : Cr(VI)',
              shortName: 'Cr(VI)',
              value: r.crEstimated,
              status: crStatus,
              accentColor: _kPrimary,
              bgGradient: const [Color(0xFFE8F5EE), Color(0xFFFFFFFF)],
              limitText: 'Batas Baku Normal: < 50 µg/L',
              modelFile: 'best_model_chromium_v2.pkl',
            ),
            const SizedBox(height: 12),

            _buildHeavyMetalCard(
              title: 'Nikel : Ni',
              shortName: 'Ni',
              value: r.niEstimated,
              status: niStatus,
              accentColor: _kIndigo,
              bgGradient: const [Color(0xFFEEF2FF), Color(0xFFFFFFFF)],
              limitText: 'Batas Baku Normal: < 20 µg/L',
              modelFile: 'best_model_nickel_v2.pkl',
            ),
            const SizedBox(height: 20),

            // Section 2: Sensor Hub (Physical Sensors)
            Row(
              children: [
                const Icon(Icons.speed_rounded, size: 18, color: _kPrimary),
                const SizedBox(width: 8),
                Text(
                  'PARAMETER FISIK AIR & IOT',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: _kTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Grid of physical sensors
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
              ),
              itemCount: physicalSensors.length,
              itemBuilder: (context, index) {
                final item = physicalSensors[index];
                return _buildPhysicalSensorCard(item);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatusBar(String rawStatus) {
    Color badgeColor;
    String badgeText;
    switch (rawStatus.toLowerCase()) {
      case 'danger':
        badgeColor = const Color(0xFFDC2626);
        badgeText = 'BAHAYA';
        break;
      case 'warning':
        badgeColor = const Color(0xFFD97706);
        badgeText = 'PERINGATAN';
        break;
      default:
        badgeColor = _kPrimary;
        badgeText = 'NORMAL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: _isConnected ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected ? 'Live Telemetri' : 'Terputus',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isConnected ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              'KUALITAS: $badgeText',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeavyMetalCard({
    required String title,
    required String shortName,
    required double? value,
    required String status,
    required Color accentColor,
    required List<Color> bgGradient,
    required String limitText,
    required String modelFile,
  }) {
    Color statusBg;
    Color statusTextColor;
    switch (status) {
      case 'BAHAYA':
        statusBg = const Color(0xFFFEE2E2);
        statusTextColor = const Color(0xFFDC2626);
        break;
      case 'WASPADA':
        statusBg = const Color(0xFFFEF9C3);
        statusTextColor = const Color(0xFFB45309);
        break;
      default:
        statusBg = accentColor.withValues(alpha: 0.12);
        statusTextColor = accentColor;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent bar on the left (identical to website)
              Container(width: 5, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.show_chart_rounded, size: 14, color: accentColor),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _kTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: statusTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Value & Unit Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            value != null ? value.toStringAsFixed(2) : '--',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: _kTextPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'µg/L',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Footer metadata
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            limitText,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _kTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            modelFile,
                            style: GoogleFonts.firaCode(
                              fontSize: 9,
                              color: _kTextSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhysicalSensorCard(_SensorItem item) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(item.icon, color: item.color, size: 14),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                item.value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kTextPrimary,
                ),
              ),
              if (item.unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  item.unit,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
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
}

class _SensorItem {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _SensorItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });
}
