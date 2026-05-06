import 'package:flutter/material.dart';
import 'package:hera/core/services/auth_service.dart';

class ProtectedRoute extends StatefulWidget {
  final Widget child;

  const ProtectedRoute({super.key, required this.child});

  @override
  State<ProtectedRoute> createState() => _ProtectedRouteState();
}

class _ProtectedRouteState extends State<ProtectedRoute> {
  final AuthService _authService = AuthService();
  bool _checking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = await _authService.getStoredSession();
    if (!mounted) return;

    if (session == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      return;
    }

    setState(() {
      _isAuthenticated = true;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticated) {
      return const SizedBox.shrink();
    }

    return widget.child;
  }
}
