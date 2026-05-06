import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hera/core/services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _kPrimary = Color(0xFF2E7D32);
const _kBackground = Color(0xFFF1F8F2);
const _kSurface = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFF6B7280);

class ProfileView extends StatefulWidget {
  final String? username;
  final String? email;

  const ProfileView({super.key, this.username, this.email});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _userData;
  bool _isUpdateProfileAvailable = true;
  bool _isChangePasswordAvailable = true;
  String? _profileFeatureNotice;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) setState(() { _userData = user; _isLoading = false; });
    } on UnauthorizedException {
      if (mounted) {
        await _authService.clearLocalSession();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _errorMessage = e.message; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  String get _displayName => _userData?['name']?.toString() ?? widget.username ?? 'Pengguna';
  String get _displayEmail => _userData?['email']?.toString() ?? widget.email ?? '-';
  String get _displayRole {
    final role = _userData?['role']?.toString() ?? 'pekerja';
    return role[0].toUpperCase() + role.substring(1);
  }

  void _markFeatureUnavailable(FeatureUnavailableException exception) {
    if (!mounted) return;
    setState(() {
      if (exception.feature == 'update_profile') _isUpdateProfileAvailable = false;
      if (exception.feature == 'change_password') _isChangePasswordAvailable = false;
      _profileFeatureNotice = exception.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text("Profil Pengguna", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return Center(child: CircularProgressIndicator(color: _kPrimary));

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 15, color: _kTextSecondary)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchProfile,
                icon: const Icon(Icons.refresh_rounded),
                label: Text("Coba Lagi", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
      );
    }

    // Get initials for avatar
    final initials = _displayName.isNotEmpty ? _displayName.split(' ').take(2).map((e) => e[0].toUpperCase()).join() : 'U';

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Header Banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_kPrimary, Color(0xFF43A047)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/images/user.png', fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(child: Text(initials, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(_displayName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(_displayEmail, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(_displayRole, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ],
            ),
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Info Card
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 12),
                      child: Text('INFORMASI AKUN', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _kTextSecondary, letterSpacing: 1.0)),
                    ),
                    _buildProfileItem(LucideIcons.user, "Nama Lengkap", _displayName),
                    _buildProfileItem(LucideIcons.mail, "Email", _displayEmail),
                    _buildProfileItem(LucideIcons.briefcase, "Pekerjaan", _displayRole),
                  ],
                ).animate(delay: 100.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 20),

                // Edit Profile Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isUpdateProfileAvailable ? _showEditProfileDialog : null,
                    icon: const Icon(Icons.edit_rounded),
                    label: Text(
                      _isUpdateProfileAvailable ? 'Edit Profil' : 'Edit Profil (Belum Tersedia)',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      shadowColor: _kPrimary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Change Password Button
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isChangePasswordAvailable ? _showChangePasswordDialog : null,
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: Text(
                      _isChangePasswordAvailable ? 'Ubah Katasandi' : 'Ubah Katasandi (Belum Tersedia)',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      side: const BorderSide(color: _kPrimary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                if (_profileFeatureNotice != null) ...[
                  const SizedBox(height: 16),
                  _buildFeatureNotice(_profileFeatureNotice!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey.shade100);

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _displayName);
    final emailController = TextEditingController(text: _displayEmail);
    bool isSaving = false;
    String? formError;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final fieldDeco = (String label, IconData icon) => InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.poppins(color: _kTextSecondary, fontSize: 14),
              prefixIcon: Icon(icon, color: _kPrimary),
              filled: true, fillColor: const Color(0xFFF9FBF9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
            );
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text('Edit Profil', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary)),
                  const SizedBox(height: 20),
                  TextField(controller: nameController, decoration: fieldDeco('Nama Lengkap', Icons.person_outlined)),
                  const SizedBox(height: 14),
                  TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: fieldDeco('Email', Icons.email_outlined)),
                  if (formError != null) ...[
                    const SizedBox(height: 10),
                    Text(formError!, style: GoogleFonts.poppins(fontSize: 13, color: Colors.red.shade600, fontWeight: FontWeight.w500)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        final name = nameController.text.trim();
                        final email = emailController.text.trim();
                        if (name.isEmpty) { setModalState(() => formError = 'Nama lengkap tidak boleh kosong.'); return; }
                        if (email.isEmpty) { setModalState(() => formError = 'Email tidak boleh kosong.'); return; }
                        if (!emailRegex.hasMatch(email)) { setModalState(() => formError = 'Format email tidak valid.'); return; }
                        setModalState(() { isSaving = true; formError = null; });
                        try {
                          final updatedUser = await _authService.updateProfile(name: name, email: email);
                          if (!mounted || !modalContext.mounted) return;
                          setState(() => _userData = <String, dynamic>{...?_userData, ...updatedUser});
                          Navigator.pop(modalContext);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui.'), backgroundColor: Colors.green));
                          _fetchProfile();
                        } on ValidationApiException catch (e) {
                          final nameErr = e.fieldErrors['name'];
                          final emailErr = e.fieldErrors['email'];
                          setModalState(() => formError = nameErr ?? emailErr ?? e.message);
                        } on FeatureUnavailableException catch (e) {
                          _markFeatureUnavailable(e);
                          if (!mounted || !modalContext.mounted) return;
                          Navigator.pop(modalContext);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.orange.shade700));
                        } on ApiException catch (e) {
                          setModalState(() => formError = e.message);
                        } finally {
                          if (mounted && modalContext.mounted) setModalState(() => isSaving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : Text('Simpan Perubahan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
    nameController.dispose();
    emailController.dispose();
  }

  Future<void> _showChangePasswordDialog() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSaving = false;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? formError;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final fieldDeco = (String label, bool obscure, VoidCallback toggle) => InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.poppins(color: _kTextSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.lock_outlined, color: _kPrimary),
              suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _kTextSecondary), onPressed: toggle),
              filled: true, fillColor: const Color(0xFFF9FBF9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
            );
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text('Ubah Katasandi', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary)),
                  const SizedBox(height: 20),
                  TextField(controller: oldPasswordController, obscureText: obscureOld, decoration: fieldDeco('Sandi Lama', obscureOld, () => setModalState(() => obscureOld = !obscureOld))),
                  const SizedBox(height: 14),
                  TextField(controller: newPasswordController, obscureText: obscureNew, decoration: fieldDeco('Sandi Baru', obscureNew, () => setModalState(() => obscureNew = !obscureNew))),
                  const SizedBox(height: 14),
                  TextField(controller: confirmPasswordController, obscureText: obscureConfirm, decoration: fieldDeco('Konfirmasi Sandi Baru', obscureConfirm, () => setModalState(() => obscureConfirm = !obscureConfirm))),
                  if (formError != null) ...[
                    const SizedBox(height: 10),
                    Text(formError!, style: GoogleFonts.poppins(fontSize: 13, color: Colors.red.shade600, fontWeight: FontWeight.w500)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        final oldPass = oldPasswordController.text.trim();
                        final newPass = newPasswordController.text.trim();
                        final confirmPass = confirmPasswordController.text.trim();
                        if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) { setModalState(() => formError = 'Semua field sandi wajib diisi.'); return; }
                        if (newPass.length < 6) { setModalState(() => formError = 'Sandi baru minimal 6 karakter.'); return; }
                        if (newPass != confirmPass) { setModalState(() => formError = 'Konfirmasi sandi baru tidak cocok.'); return; }
                        if (oldPass == newPass) { setModalState(() => formError = 'Sandi baru tidak boleh sama dengan sandi lama.'); return; }
                        setModalState(() { isSaving = true; formError = null; });
                        try {
                          final result = await _authService.changePassword(oldPassword: oldPass, newPassword: newPass, confirmPassword: confirmPass);
                          if (!mounted || !modalContext.mounted) return;
                          Navigator.pop(modalContext);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message), backgroundColor: Colors.green));
                          if (result.forceLogout) { await _authService.clearLocalSession(); } else { await _authService.logout(); }
                          if (!mounted) return;
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        } on ValidationApiException catch (e) {
                          setModalState(() => formError = e.fieldErrors['old_password'] ?? e.fieldErrors['new_password'] ?? e.fieldErrors['new_password_confirmation'] ?? e.message);
                        } on FeatureUnavailableException catch (e) {
                          _markFeatureUnavailable(e);
                          if (!mounted || !modalContext.mounted) return;
                          Navigator.pop(modalContext);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.orange.shade700));
                        } on UnauthorizedException {
                          if (!mounted || !modalContext.mounted) return;
                          Navigator.pop(modalContext);
                          await _authService.clearLocalSession();
                          if (!mounted) return;
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                        } on ApiException catch (e) {
                          setModalState(() => formError = e.message);
                        } finally {
                          if (mounted && modalContext.mounted) setModalState(() => isSaving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : Text('Ganti Katasandi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.green.shade50, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _kPrimary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: _kTextSecondary)),
                const SizedBox(height: 2),
                Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureNotice(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: GoogleFonts.poppins(fontSize: 13, color: Colors.orange.shade900, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
