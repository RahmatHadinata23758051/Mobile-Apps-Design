import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hera/core/services/auth_service.dart';
import 'package:hera/core/models/validation_api_exception.dart';
import 'package:flutter_animate/flutter_animate.dart';

const _kPrimary = Color(0xFF2E7D32);
const _kPrimaryLight = Color(0xFF43A047);
const _kBackground = Color(0xFFF1F8F2);
const _kSurface = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFF6B7280);

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const int _minPasswordLength = 6;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Map<String, String> _backendErrors = {};

  void _clearError(String field) {
    if (_backendErrors.containsKey(field)) {
      setState(() => _backendErrors.remove(field));
      _formKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final name = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() { _isLoading = true; _backendErrors.clear(); });

    try {
      await AuthService().register(name: name, email: email, password: password, passwordConfirmation: confirmPassword);
      if (mounted) {
        _passwordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registrasi berhasil! Silakan login.')));
        Navigator.pushReplacementNamed(context, '/login', arguments: {'username': name, 'email': email});
      }
    } on ValidationApiException catch (e) {
      if (mounted) { setState(() => _backendErrors = e.fieldErrors); _formKey.currentState!.validate(); }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan saat registrasi.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToLogin() {
    try {
      Navigator.pushNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal navigasi ke login: $e")));
    }
  }

  InputDecoration _fieldDecoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: _kTextSecondary, fontSize: 14),
      prefixIcon: Icon(icon, color: _kPrimary),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF9FBF9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Green Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_kPrimary, _kPrimaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Text(
                    'Buat Akun Baru',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.25),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Daftar untuk mulai menggunakan\nHERA Monitoring',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),

            // ── Form ──
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Image.asset('assets/images/unhas-logo.png', height: 60),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Registrasi Akun',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
                            ),
                            const SizedBox(height: 20),

                            // Username
                            TextFormField(
                              controller: _usernameController,
                              enabled: !_isLoading,
                              onChanged: (_) => _clearError('name'),
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              decoration: _fieldDecoration('Username', Icons.person_outlined),
                              validator: (v) {
                                if (_backendErrors.containsKey('name')) return _backendErrors['name'];
                                if (v == null || v.isEmpty) return 'Username tidak boleh kosong';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) => _clearError('email'),
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: _fieldDecoration('Email', Icons.email_outlined),
                              validator: (v) {
                                if (_backendErrors.containsKey('email')) return _backendErrors['email'];
                                if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Masukkan email yang valid';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              enabled: !_isLoading,
                              obscureText: _obscurePassword,
                              onChanged: (_) => _clearError('password'),
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              enableSuggestions: false,
                              autocorrect: false,
                              decoration: _fieldDecoration('Password', Icons.lock_outlined,
                                  suffix: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _kTextSecondary),
                                    onPressed: _isLoading ? null : () => setState(() => _obscurePassword = !_obscurePassword),
                                  )),
                              validator: (v) {
                                if (_backendErrors.containsKey('password')) return _backendErrors['password'];
                                if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                                if (v.length < _minPasswordLength) return 'Password minimal $_minPasswordLength karakter';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Confirm Password
                            TextFormField(
                              controller: _confirmPasswordController,
                              enabled: !_isLoading,
                              obscureText: _obscureConfirmPassword,
                              onChanged: (_) => _clearError('password_confirmation'),
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              enableSuggestions: false,
                              autocorrect: false,
                              onFieldSubmitted: (_) => _signUp(),
                              decoration: _fieldDecoration('Konfirmasi Password', Icons.lock_outlined,
                                  suffix: IconButton(
                                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _kTextSecondary),
                                    onPressed: _isLoading ? null : () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  )),
                              validator: (v) {
                                if (_backendErrors.containsKey('password_confirmation')) return _backendErrors['password_confirmation'];
                                if (v == null || v.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                                if (v != _passwordController.text) return 'Password tidak cocok';
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // Sign Up Button
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _kPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                  shadowColor: _kPrimary.withValues(alpha: 0.4),
                                ),
                                child: _isLoading
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : Text('Daftar Sekarang', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Sudah punya akun? ', style: GoogleFonts.poppins(fontSize: 14, color: _kTextSecondary)),
                        GestureDetector(
                          onTap: _isLoading ? null : _navigateToLogin,
                          child: Text('Login di sini', style: GoogleFonts.poppins(fontSize: 14, color: _kPrimary, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ).animate().fade(duration: 500.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),
            ),

            // ── Footer ──
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                children: [
                  Text('HERA V.2', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 2),
                  Text('© PT. Makerindo Prima Solusi Inc.', style: GoogleFonts.poppins(fontSize: 11, color: _kTextSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
