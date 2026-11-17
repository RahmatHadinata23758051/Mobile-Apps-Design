import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hera/core/services/test_service.dart';
import 'package:hera/core/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

const _kPrimary = Color(0xFF006948);
const _kBackground = Color(0xFFF4F7F5);
const _kSurface = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFF5F6E65);

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
    final petugas = item['user']?['name']?.toString() ?? item['petugas']?.toString() ?? 'Petugas Lapangan';
    final lat = item['latitude'];
    final lng = item['longitude'];
    final altitude = item['altitude'];
    final crVal = item['cr_estimated'];
    final niVal = item['ni_estimated'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
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
                    Text(
                      petugas,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                    ),
                  ],
                ),
                Text(
                  _formatTimestamp(item['created_at']),
                  style: GoogleFonts.poppins(fontSize: 11, color: _kTextSecondary, fontWeight: FontWeight.w500),
                ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_formatCoordinate(lat)}, ${_formatCoordinate(lng)}  •  ${_formatAltitude(altitude)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Heavy Metals Predictions (Cr & Ni)
                Text(
                  'PREDIKSI LOGAM BERAT (AI)',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kTextSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Cr(VI) Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kPrimary.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cr(VI)',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: _kPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              crVal != null ? '${_formatVal(crVal)} µg/L' : '-',
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: _kPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Ni Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ni',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              niVal != null ? '${_formatVal(niVal)} µg/L' : '-',
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF4338CA)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Physical Sensors Grid
                Text(
                  'DETAIL PENGUKURAN SENSOR',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kTextSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.1,
                  children: [
                    _buildGridItem('pH', _formatVal(item['ph']), const Color(0xFF0284C7)),
                    _buildGridItem('TDS', '${_formatVal(item['tds'])} ppm', const Color(0xFF0EA5E9)),
                    _buildGridItem('EC', '${_formatVal(item['ec'])} mS', const Color(0xFFD97706)),
                    _buildGridItem('Suhu Air', '${_formatVal(item['suhu_air'])}°C', const Color(0xFF059669)),
                    _buildGridItem('Suhu Udara', '${_formatVal(item['suhu_lingkungan'])}°C', const Color(0xFFEA580C)),
                    _buildGridItem('Kelembapan', '${_formatVal(item['kelembapan'])}%', const Color(0xFF0D9488)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 350.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _buildGridItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: _kTextSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 12, color: color, fontWeight: FontWeight.bold),
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
              child: Icon(Icons.science_outlined, size: 54, color: _kPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Data Pengujian',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              'Data uji lapangan dari smartphone akan tersimpan di sini.',
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
            Icon(Icons.error_outline_rounded, size: 54, color: Colors.red.shade400),
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
      padding: const EdgeInsets.all(24),
      child: Center(
        child: TextButton.icon(
          onPressed: _loadMore,
          icon: const Icon(Icons.refresh_rounded, size: 16, color: _kPrimary),
          label: Text('Gagal memuat lebih banyak. Klik untuk ulangi.', style: GoogleFonts.poppins(color: _kPrimary, fontWeight: FontWeight.bold)),
        ),
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
              'Seluruh riwayat pengujian telah ditampilkan',
              style: GoogleFonts.poppins(fontSize: 12, color: _kTextSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
