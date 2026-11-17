import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hera/core/models/sensor_reading.dart';
import 'package:hera/core/services/sensor_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

const _kPrimary = Color(0xFF006948);
const _kBackground = Color(0xFFF4F7F5);
const _kSurface = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFF5F6E65);

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SensorService _sensorService = SensorService();
  final ScrollController _scrollController = ScrollController();

  final List<SensorReading> _items = [];
  bool _isLoading = false;
  bool _isFirstLoad = true;
  String? _nextCursor;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final result = await _sensorService.fetchHistory(limit: 20, cursor: _nextCursor, source: 'postgres');
      if (mounted) {
        setState(() {
          _items.addAll(result.items);
          _nextCursor = result.nextCursor;
          _hasMore = result.nextCursor != null;
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().contains('Unauthorized') ? 'Sesi berakhir, silakan login kembali.' : 'Gagal memuat data histori.';
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    }
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(dt.toLocal());
  }

  String _formatVal(double? v) => v?.toStringAsFixed(2) ?? '-';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        title: Text('Histori Data Sensor', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isFirstLoad && _isLoading) {
      return Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (_error != null && _items.isEmpty) return _buildErrorState();
    if (_items.isEmpty && !_isLoading) return _buildEmptyState();

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async {
        setState(() { _items.clear(); _nextCursor = null; _hasMore = true; _isFirstLoad = true; });
        await _loadMore();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + (_hasMore ? 1 : 1),
        itemBuilder: (context, index) {
          if (index < _items.length) return _buildHistoryCard(_items[index]);
          if (_hasMore) {
            if (_error != null) return _buildRetryButton();
            return Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator(color: _kPrimary)));
          }
          return _buildEndOfList();
        },
      ),
    );
  }

  Widget _buildHistoryCard(SensorReading reading) {
    Color statusColor;
    String statusLabel;
    Color statusBg;
    switch (reading.status.toLowerCase()) {
      case 'danger':
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEE2E2);
        statusLabel = 'BAHAYA';
        break;
      case 'warning':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF9C3);
        statusLabel = 'PERINGATAN';
        break;
      default:
        statusColor = _kPrimary;
        statusBg = _kPrimary.withValues(alpha: 0.1);
        statusLabel = 'NORMAL';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: _kTextSecondary),
                              const SizedBox(width: 5),
                              Text(
                                _formatTimestamp(reading.createdAt),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _kTextSecondary,
                                  fontWeight: FontWeight.w500,
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
                              statusLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMiniInfo('pH', _formatVal(reading.ph), const Color(0xFF0284C7)),
                          _buildMiniInfo('TDS', '${_formatVal(reading.tds)} ppm', const Color(0xFF0EA5E9)),
                          _buildMiniInfo('EC', '${_formatVal(reading.ec)} mS', const Color(0xFFD97706)),
                          _buildMiniInfo('Suhu Air', '${_formatVal(reading.suhuAir)}°C', const Color(0xFF059669)),
                          _buildMiniInfo('Suhu Ling.', '${_formatVal(reading.suhuLingkungan)}°C', const Color(0xFFEA580C)),
                          _buildMiniInfo('Kelembapan', '${_formatVal(reading.kelembapan)}%', const Color(0xFF0D9488)),
                          _buildMiniInfo('Tegangan', '${_formatVal(reading.tegangan)}V', const Color(0xFF7C3AED)),
                          _buildMiniInfo(
                            'Cr(VI)',
                            reading.crEstimated != null ? '${_formatVal(reading.crEstimated)} µg/L' : '-',
                            _kPrimary,
                            isHighlighted: true,
                          ),
                          _buildMiniInfo(
                            'Ni',
                            reading.niEstimated != null ? '${_formatVal(reading.niEstimated)} µg/L' : '-',
                            const Color(0xFF4338CA),
                            isHighlighted: true,
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
    ).animate().fade(duration: 350.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _buildMiniInfo(String label, String value, Color color, {bool isHighlighted = false}) {
    return Container(
      width: 98,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted ? color.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isHighlighted ? color : _kTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isHighlighted ? color : const Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_rounded, size: 54, color: _kPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Histori Data',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              'Data telemetri dari sensor IoT akan tersimpan di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: _kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 54, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: _kTextSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () { setState(() => _isFirstLoad = true); _loadMore(); },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryButton() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text('Gagal memuat lebih banyak data.', style: GoogleFonts.poppins(fontSize: 12, color: _kTextSecondary)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadMore,
            icon: const Icon(Icons.refresh_rounded, size: 16, color: _kPrimary),
            label: Text('Coba Lagi', style: GoogleFonts.poppins(color: _kPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEndOfList() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Container(width: 32, height: 4, decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            Text(
              'Seluruh data histori telah ditampilkan',
              style: GoogleFonts.poppins(fontSize: 12, color: _kTextSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
