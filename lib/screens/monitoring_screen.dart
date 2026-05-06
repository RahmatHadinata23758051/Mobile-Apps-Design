import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hera/core/models/sensor_reading.dart';
import 'package:hera/core/services/auth_service.dart';
import 'package:hera/core/services/realtime_service.dart';
import 'package:hera/core/services/sensor_service.dart';

const _kPrimary = Color(0xFF2E7D32);
const _kBackground = Color(0xFFF1F8F2);
const _kSurface = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFF6B7280);

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

    try {
      await _realtimeService.connect();
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

    if (showLoader) setState(() { _isLoading = true; _errorMessage = null; });

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
        setState(() { _errorMessage = e.message; _isLoading = false; });
      }
    } catch (_) {
      if (!mounted) return;
      if (showLoader || _latestReading == null) {
        setState(() { _errorMessage = 'Terjadi kesalahan saat memuat data monitoring.'; _isLoading = false; });
      }
    } finally {
      _isFetchingLatest = false;
    }
  }

  String _formatNumber(double? value, {int fractionDigits = 2}) {
    if (value == null) return '-';
    return value.toStringAsFixed(fractionDigits);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        title: Text('Monitoring', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _loadLatestSensor(showLoader: false),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Manual',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _kPrimary));
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
              Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: _kTextSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadLatestSensor,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
      );
    }

    if (_latestReading == null) {
      return Center(child: Text('Belum ada data sensor.', style: GoogleFonts.poppins(fontSize: 14, color: _kTextSecondary)));
    }

    final r = _latestReading!;
    final items = <_SensorItem>[
      _SensorItem(label: 'EC', value: _formatNumber(r.ec), unit: 'mS/cm', icon: Icons.electric_bolt_rounded, color: Colors.amber.shade700),
      _SensorItem(label: 'TDS', value: _formatNumber(r.tds), unit: 'ppm', icon: Icons.water_drop_rounded, color: Colors.blue.shade600),
      _SensorItem(label: 'pH', value: _formatNumber(r.ph), unit: '', icon: Icons.science_rounded, color: Colors.indigo.shade600),
      _SensorItem(label: 'Suhu Air', value: _formatNumber(r.suhuAir), unit: '°C', icon: Icons.thermostat_rounded, color: Colors.cyan.shade600),
      _SensorItem(label: 'Suhu Ling.', value: _formatNumber(r.suhuLingkungan), unit: '°C', icon: Icons.wb_sunny_rounded, color: Colors.orange.shade600),
      _SensorItem(label: 'Kelembapan', value: _formatNumber(r.kelembapan), unit: '%', icon: Icons.water_outlined, color: Colors.teal.shade600),
      _SensorItem(label: 'Tegangan', value: _formatNumber(r.tegangan), unit: 'V', icon: Icons.power_rounded, color: Colors.purple.shade600),
      _SensorItem(label: 'CR Est.', value: _formatNumber(r.crEstimated), unit: 'ml/l', icon: Icons.analytics_rounded, color: _kPrimary),
    ];

    return Column(
      children: [
        // Status Bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _isConnected ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isConnected ? Colors.green.shade200 : Colors.red.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: _isConnected ? Colors.green.shade600 : Colors.red.shade600, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                _isConnected ? 'Realtime Connected' : 'Disconnected',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _isConnected ? Colors.green.shade700 : Colors.red.shade700),
              ),
              const Spacer(),
              if (_isConnected) Text('Live', style: GoogleFonts.poppins(fontSize: 11, color: Colors.green.shade600)),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border(left: BorderSide(color: item.color, width: 4)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(item.icon, color: item.color, size: 18),
                        const SizedBox(width: 6),
                        Text(item.label, style: GoogleFonts.poppins(fontSize: 12, color: _kTextSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(item.value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                        if (item.unit.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(item.unit, style: GoogleFonts.poppins(fontSize: 11, color: _kTextSecondary)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SensorItem {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  const _SensorItem({required this.label, required this.value, required this.unit, required this.icon, required this.color});
}
