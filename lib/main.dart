import 'package:flutter/material.dart';
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
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF43A047),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF1F8F2),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
        cardTheme: const CardThemeData(
          elevation: 8,
          shadowColor: Color(0x14000000), // Colors.black.withValues(alpha: 0.08)
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          color: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 4,
            shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          prefixIconColor: const Color(0xFF2E7D32),
          filled: true,
          fillColor: const Color(0xFFF9FBF9),
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
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
