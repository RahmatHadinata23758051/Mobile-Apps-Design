import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hera/core/services/app_update_service.dart';

class AppUpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;
  final AppUpdateService? updateService;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
    this.updateService,
  });

  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo updateInfo,
    AppUpdateService? updateService,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !updateInfo.isForceUpdate,
      builder: (context) => PopScope(
        canPop: !updateInfo.isForceUpdate,
        child: AppUpdateDialog(
          updateInfo: updateInfo,
          updateService: updateService,
        ),
      ),
    );
  }

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  late final AppUpdateService _service;
  bool _isDownloading = false;
  double _progress = 0.0;
  String _downloadedText = '0 MB';
  String _totalText = '0 MB';
  String? _errorMessage;

  static const Color _kPrimary = Color(0xFF2E7D32);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1E293B);
  static const Color _kTextSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _service = widget.updateService ?? AppUpdateService();
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _progress = 0.0;
    });

    final success = await _service.downloadAndInstall(
      downloadUrl: widget.updateInfo.downloadUrl,
      onProgress: (progress, downloaded, total) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _downloadedText = downloaded;
            _totalText = total;
          });
        }
      },
      onError: (message) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _errorMessage = message;
          });
        }
      },
    );

    if (success && mounted) {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.updateInfo;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: _kSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon and Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: info.isForceUpdate ? Colors.amber.shade50 : _kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      info.isForceUpdate ? Icons.warning_amber_rounded : Icons.system_update_rounded,
                      color: info.isForceUpdate ? Colors.amber.shade800 : _kPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.isForceUpdate ? 'Pembaruan Wajib!' : 'Pembaruan Tersedia',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _kTextPrimary,
                          ),
                        ),
                        Text(
                          'Versi terbaru siap dipasang',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Version Badges Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Versi Anda',
                          style: GoogleFonts.poppins(fontSize: 11, color: _kTextSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v${info.currentVersion}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: _kPrimary, size: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Versi Baru',
                          style: GoogleFonts.poppins(fontSize: 11, color: _kPrimary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              info.latestVersion.startsWith('v') ? info.latestVersion : 'v${info.latestVersion}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _kPrimary,
                              ),
                            ),
                            if (info.fileSize != null && info.fileSize!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _kPrimary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  info.fileSize!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _kPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Changelog Section
              if (info.changelog.isNotEmpty) ...[
                Text(
                  'Catatan Pembaruan:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      info.changelog,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _kTextSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Downloading Progress or Actions
              if (_isDownloading) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mengunduh pembaruan...',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: _kPrimary),
                        ),
                        Text(
                          _progress >= 0 ? '${(_progress * 100).toInt()}%' : '',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: _kPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _progress >= 0
                          ? LinearProgressIndicator(
                              value: _progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                            )
                          : const LinearProgressIndicator(
                              minHeight: 8,
                              backgroundColor: Colors.grey,
                              valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_downloadedText / $_totalText',
                      style: GoogleFonts.poppins(fontSize: 11, color: _kTextSecondary),
                    ),
                  ],
                ),
              ] else ...[
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                Row(
                  children: [
                    if (!info.isForceUpdate) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            'Nanti',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: _kTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: info.isForceUpdate ? 1 : 2,
                      child: ElevatedButton.icon(
                        onPressed: _startDownload,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(
                          _errorMessage != null ? 'Coba Lagi' : 'Perbarui Sekarang',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
