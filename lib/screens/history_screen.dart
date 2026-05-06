import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hera/core/models/sensor_reading.dart';
import 'package:hera/core/services/sensor_service.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _kPrimary = Color(0xFF2E7D32);
const _kBackground = Color(0xFFF1F8F2);
const _kSurface = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFF6B7280);

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
    switch (reading.status.toLowerCase()) {
      case 'danger':
        statusColor = Colors.red.shade600;
        statusLabel = 'BAHAYA';
        break;
      case 'warning':
        statusColor = Colors.orange.shade600;
        statusLabel = 'PERINGATAN';
        break;
      default:
        statusColor = Colors.green.shade600;
        statusLabel = 'NORMAL';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
                              Icon(LucideIcons.calendar, size: 13, color: _kTextSecondary),
                              const SizedBox(width: 4),
                              Text(_formatTimestamp(reading.createdAt), style: GoogleFonts.poppins(fontSize: 12, color: _kTextSecondary, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                            child: Text(statusLabel, style: GoogleFonts.poppins(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildMiniInfo('pH', _formatVal(reading.ph), Colors.indigo),
                          _buildMiniInfo('TDS', _formatVal(reading.tds), Colors.teal),
                          _buildMiniInfo('EC', _formatVal(reading.ec), Colors.blueGrey),
                          _buildMiniInfo('SuAt', '${_formatVal(reading.suhuAir)}°C', Colors.blue),
                          _buildMiniInfo('SuLi', '${_formatVal(reading.suhuLingkungan)}°C', Colors.orange),
                          _buildMiniInfo('Hum', '${_formatVal(reading.kelembapan)}%', Colors.cyan),
                          _buildMiniInfo('Volt', '${_formatVal(reading.tegangan)}V', Colors.purple),
                          _buildMiniInfo('CR', '${_formatVal(reading.crEstimated)}ml', Colors.deepOrange),
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

  Widget _buildMiniInfo(String label, String value, MaterialColor color) {
    return SizedBox(
      width: 65,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: _kTextSecondary, fontWeight: FontWeight.w600)),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, color: color.shade700, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
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
            Icon(LucideIcons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Belum ada histori data.', style: GoogleFonts.poppins(fontSize: 16, color: _kTextSecondary)),
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
            Icon(LucideIcons.alertTriangle, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error ?? 'Terjadi kesalahan.', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: _kTextSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () { setState(() => _isFirstLoad = true); _loadMore(); },
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
          TextButton.icon(onPressed: _loadMore, icon: const Icon(LucideIcons.refreshCw, size: 16, color: _kPrimary), label: Text('Coba Lagi', style: GoogleFonts.poppins(color: _kPrimary))),
        ],
      ),
    );
  }

  Widget _buildEndOfList() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.green.shade200, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 10),
            Text('Sudah mencapai akhir data', style: GoogleFonts.poppins(fontSize: 12, color: _kTextSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
