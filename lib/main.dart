import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hera/screens/login_screen.dart';
import 'package:hera/screens/signup_screen.dart';
import 'package:hera/screens/home_screen.dart';
import 'package:hera/screens/history_screen.dart';
import 'package:hera/screens/testing_history_screen.dart';
import 'package:hera/screens/test_location_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hera/core/services/auth_service.dart';
import 'package:hera/core/widgets/protected_route.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(
    'id_ID',
    null,
  ); // Inisialisasi locale untuk format tanggal
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF006948),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006948),
          primary: const Color(0xFF006948),
          secondary: const Color(0xFF009664),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shadowColor: Color(0x0D000000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          color: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF006948),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006948),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 2,
            shadowColor: const Color(0xFF006948).withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF006948), width: 1.8),
          ),
          prefixIconColor: const Color(0xFF006948),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
        ),
      ),
      initialRoute: '/auth-bootstrap',
      routes: {
        '/auth-bootstrap': (context) => const AuthBootstrapScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const ProtectedRoute(child: HomeScreen()),
        '/history': (context) => const ProtectedRoute(child: HistoryScreen()),
        '/testing-history':
            (context) => const ProtectedRoute(child: TestingHistoryScreen()),
        '/test_location':
            (context) => const ProtectedRoute(child: TestLocationScreen()),
      },
    );
  }
}

class AuthBootstrapScreen extends StatefulWidget {
  const AuthBootstrapScreen({super.key});

  @override
  State<AuthBootstrapScreen> createState() => _AuthBootstrapScreenState();
}

class _AuthBootstrapScreenState extends State<AuthBootstrapScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveInitialRoute();
    });
  }

  Future<void> _resolveInitialRoute() async {
    final session = await _authService.getStoredSession();
    if (!mounted) return;

    if (session == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {'username': session.username, 'email': session.email},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006948).withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset('assets/images/unhas-logo.png', height: 72),
            ),
            const SizedBox(height: 24),
            Text(
              'HERA V.2',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: const Color(0xFF006948),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Heavy Metal Monitoring & Early Warning System',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF5F6E65),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF006948),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
