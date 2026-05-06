import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hera/core/services/test_service.dart';
import 'package:hera/core/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

const _kPrimary = Color(0xFF2E7D32);
const _kBackground = Color(0xFFF1F8F2);
const _kSurface = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFF6B7280);

class TestingHistoryScreen extends StatefulWidget {
  const TestingHistoryScreen({super.key});

  @override
  State<TestingHistoryScreen> createState() => _TestingHistoryScreenState();
}

class _TestingHistoryScreenState extends State<TestingHistoryScreen> {
  final TestService _testService = TestService();
  final ScrollController _scrollController = ScrollController();

  final List<dynamic> _items = [];
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
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final result = await _testService.fetchTestingHistory(limit: 20, cursor: _nextCursor);
      if (mounted) {
        setState(() {
          _items.addAll(result.items);
          _nextCursor = result.nextCursor;
          _hasMore = result.nextCursor != null;
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    } on UnauthorizedException {
      if (mounted) {
        setState(() { _error = 'Sesi berakhir, silakan login kembali.'; _isLoading = false; _isFirstLoad = false; });
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _isLoading = false; _isFirstLoad = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Gagal memuat histori pengujian.'; _isLoading = false; _isFirstLoad = false; });
    }
  }

  String _formatTimestamp(String? ts) {
    if (ts == null) return '-';
    try {
      final dt = DateTime.parse(ts);
      return DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(dt.toLocal());
    } catch (_) { return ts; }
  }

  String _formatVal(dynamic v) {
    if (v == null) return '-';
    if (v is num) return v.toStringAsFixed(2);
    return v.toString();
  }

  String _formatCoordinate(dynamic value) {
    if (value == null) return '-';
    final number = double.tryParse(value.toString());
    if (number == null) return value.toString();
    return number.toStringAsFixed(6);
  }

  String _formatAltitude(dynamic value) {
    if (value == null) return '-';
    final number = double.tryParse(value.toString());
    if (number == null) return value.toString();
    return '${number.toStringAsFixed(2)} m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        title: Text('Histori Pengujian GPS', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isFirstLoad && _isLoading) return Center(child: CircularProgressIndicator(color: _kPrimary));
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
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index < _items.length) return _buildTestCard(_items[index]);
          if (_hasMore) {
            if (_error != null) return _buildRetryButton();
            return Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator(color: _kPrimary)));
          }
          return _buildEndOfList();
        },
      ),
    );
  }

  Widget _buildTestCard(dynamic item) {
    final petugas = item['petugas'] ?? 'Petugas Lapangan';
    final lat = item['latitude'];
    final lng = item['longitude'];
    final altitude = item['altitude'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Colors.green.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: _kPrimary,
                      child: const Icon(Icons.person_rounded, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(petugas, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                  ],
                ),
                Text(_formatTimestamp(item['created_at']), style: GoogleFonts.poppins(fontSize: 11, color: _kTextSecondary)),
              ],
            ),
          ),

          // Card Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Row
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade100)),
                  child: Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 16, color: Colors.red.shade500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${_formatCoordinate(lat)}, Lng: ${_formatCoordinate(lng)}  |  Alt: ${_formatAltitude(altitude)}',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text('DETAIL PENGUKURAN SENSOR', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: _kTextSecondary, letterSpacing: 1.0)),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _buildGridItem('pH', _formatVal(item['ph']), Colors.indigo),
                    _buildGridItem('TDS', _formatVal(item['tds']), Colors.teal),
                    _buildGridItem('EC', _formatVal(item['ec']), Colors.blueGrey),
                    _buildGridItem('SuAt', _formatVal(item['suhu_air']), Colors.blue),
                    _buildGridItem('Hum', _formatVal(item['kelembapan']), Colors.cyan),
                    _buildGridItem('CR Est', _formatVal(item['cr_estimated']), Colors.deepOrange),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildGridItem(String label, String value, MaterialColor color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: _kTextSecondary, fontWeight: FontWeight.w500)),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, color: color.shade700, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.flaskConical, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Belum ada data pengujian.', style: GoogleFonts.poppins(fontSize: 16, color: _kTextSecondary)),
        ],
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
            Icon(LucideIcons.alertCircle, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error ?? 'Terjadi kesalahan.', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: _kTextSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () { setState(() => _isFirstLoad = true); _loadMore(); },
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: TextButton.icon(
        onPressed: _loadMore,
        icon: const Icon(LucideIcons.refreshCw, size: 16, color: _kPrimary),
        label: Text('Gagal memuat lebih banyak. Klik untuk ulangi.', style: GoogleFonts.poppins(color: _kPrimary)),
      ),
    );
  }

  Widget _buildEndOfList() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(child: Text('Seluruh riwayat pengujian telah ditampilkan', style: GoogleFonts.poppins(fontSize: 12, color: _kTextSecondary, fontWeight: FontWeight.w500))),
    );
  }
}
