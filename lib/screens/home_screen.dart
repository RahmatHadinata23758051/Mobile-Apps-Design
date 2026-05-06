import 'package:flutter/material.dart';
import 'package:hera/screens/profile_view.dart';
import 'package:hera/screens/monitoring_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hera/core/network/auth_storage.dart';
import 'package:hera/core/models/sensor_history_result.dart';
import 'package:hera/core/models/testing_history_result.dart';
import 'package:hera/core/models/sensor_reading.dart';
import 'package:hera/core/services/auth_service.dart';
import 'package:hera/core/services/location_security_service.dart';
import 'package:hera/core/services/sensor_service.dart';
import 'package:hera/core/services/test_service.dart';
import 'package:hera/core/services/realtime_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late String _formattedDate;
  late String _formattedTime;
  late Timer _timer;
  String _locationMessage = "Mendapatkan lokasi...";
  double _speed = 0.0;
  Position? _previousPosition;
  StreamSubscription<Position>? _positionStream;

  String? _username;
  String? _email;

  final AuthStorage _authStorage = const AuthStorage();
  final AuthService _authService = AuthService();
  final SensorService _sensorService = SensorService();
  final TestService _testService = TestService();
  final LocationSecurityService _locationSecurityService =
      LocationSecurityService();
  bool _isLoadingApiSummary = false;
  bool _isLoggingOut = false;
  Timer? _summaryRefreshTimer;
  int _latestCount = 0;
  int _alertsCount = 0;
  int _historyCount = 0;
  final List<int> _historyRowOptions = const [10, 15, 20];
  int _selectedHistoryRows = 10;
  int _selectedTestingRows = 10;
  List<SensorReading> _historyRows = const <SensorReading>[];
  List<dynamic> _testingHistoryRows = [];
  String? _historyErrorMessage;

  final ScrollController _historyScrollController = ScrollController();
  final ScrollController _testingHistoryScrollController = ScrollController();

  final RealtimeService _realtimeService = RealtimeService();
  StreamSubscription<Map<String, dynamic>>? _sensorSubscription;
  StreamSubscription<Map<String, dynamic>>? _testingSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
    _startLocationUpdates();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null) {
        setState(() {
          _username = args['username']?.toString();
          _email = args['email']?.toString();
        });
      }

      // Load user data from storage and backend
      await _loadUserProfile();
      await _loadSensorSummary();
    });

    _initRealtime();
    _startSummaryAutoRefresh();
  }

  void _startSummaryAutoRefresh() {
    _summaryRefreshTimer?.cancel();
    _summaryRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted || _isDisposed) return;
      _loadSensorSummary(showLoader: false);
    });
  }

  Future<void> _initRealtime() async {
    _sensorSubscription?.cancel();
    _testingSubscription?.cancel();
    _connectionSubscription?.cancel();

    _sensorSubscription = _realtimeService.sensorStream.listen((json) {
      if (!mounted || _isDisposed) return;
      try {
        final reading = SensorReading.fromJson(json);
        if (_isDuplicateSensorReading(reading)) {
          return;
        }

        setState(() {
          _latestCount++;
          _historyCount++;
          if (reading.status == 'warning' || reading.status == 'danger') {
            _alertsCount++;
          }

          // Tambahkan ke paling atas tabel histori langsung.
          _historyRows = List<SensorReading>.from([reading, ..._historyRows]);
          if (_historyRows.length > 50) {
            _historyRows.removeLast();
          }
        });
      } catch (e) {
        debugPrint('[Realtime] Error parsing data home: $e');
      }
    });

    _testingSubscription = _realtimeService.testingStream.listen((newTest) {
      if (!mounted || _isDisposed) return;
      if (_isDuplicateTestingRow(newTest)) {
        return;
      }

      setState(() {
        // Tambahkan ke atas list pengujian.
        _testingHistoryRows = [newTest, ..._testingHistoryRows];
        if (_testingHistoryRows.length > 50) {
          _testingHistoryRows.removeLast();
        }
      });
    });

    _connectionSubscription = _realtimeService.connectionStream.listen((
      connected,
    ) {
      if (!connected || !mounted || _isDisposed) return;
      _loadSensorSummary(showLoader: false);
    });

    try {
      await _realtimeService.connect();
    } catch (e) {
      debugPrint('[Realtime] Gagal konek di home: $e');
    }
  }

  bool _isDuplicateSensorReading(SensorReading incoming) {
    if (incoming.id != null) {
      return _historyRows.any((row) => row.id == incoming.id);
    }

    final incomingCreatedAt = incoming.createdAt?.toUtc().toIso8601String();
    if (incomingCreatedAt == null) return false;

    return _historyRows.any((row) {
      final rowCreatedAt = row.createdAt?.toUtc().toIso8601String();
      return rowCreatedAt == incomingCreatedAt &&
          row.ec == incoming.ec &&
          row.tds == incoming.tds &&
          row.ph == incoming.ph;
    });
  }

  bool _isDuplicateTestingRow(Map<String, dynamic> incoming) {
    final incomingId = incoming['id']?.toString();
    if (incomingId != null && incomingId.isNotEmpty) {
      return _testingHistoryRows.any((row) {
        if (row is! Map) return false;
        return row['id']?.toString() == incomingId;
      });
    }

    final createdAt = incoming['created_at']?.toString();
    final latitude = incoming['latitude']?.toString();
    final longitude = incoming['longitude']?.toString();
    final altitude = incoming['altitude']?.toString();

    return _testingHistoryRows.any((row) {
      if (row is! Map) return false;
      return row['created_at']?.toString() == createdAt &&
          row['latitude']?.toString() == latitude &&
          row['longitude']?.toString() == longitude &&
          row['altitude']?.toString() == altitude;
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _sensorSubscription?.cancel();
    _testingSubscription?.cancel();
    _connectionSubscription?.cancel();
    unawaited(_realtimeService.disconnect());
    _timer.cancel();
    _summaryRefreshTimer?.cancel();
    _positionStream?.cancel();
    _historyScrollController.dispose();
    _testingHistoryScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && !_isDisposed) {
      _loadSensorSummary(showLoader: false);
    }
  }

  Future<void> _loadSensorSummary({bool showLoader = true}) async {
    if (_isLoadingApiSummary) return;
    if (showLoader) {
      setState(() {
        _isLoadingApiSummary = true;
        _historyErrorMessage = null;
      });
    }

    try {
      final results = await Future.wait<Object>([
        _sensorService.fetchLatest(),
        _sensorService.fetchAlerts(),
        _sensorService.fetchHistory(
          limit: _selectedHistoryRows,
          source: 'postgres',
        ),
        _testService.fetchTestingHistory(limit: _selectedTestingRows),
      ]);

      if (!mounted) return;

      final latest = results[0] as List<SensorReading>;
      final alerts = results[1] as List<SensorReading>;
      final historyResult = results[2] as SensorHistoryResult;
      final testingHistoryResult = results[3] as TestingHistoryResult;

      setState(() {
        _latestCount = latest.length;
        _alertsCount = alerts.length;
        _historyCount = historyResult.items.length;
        _historyRows = historyResult.items;
        _testingHistoryRows = testingHistoryResult.items;
      });
    } on UnauthorizedException catch (e) {
      if (!mounted) return;
      _showApiError(e.message);
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showApiError(e.message);
      setState(() {
        _historyErrorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      _showApiError('Terjadi kesalahan saat memuat data sensor.');
      setState(() {
        _historyErrorMessage = 'Terjadi kesalahan saat memuat histori data.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingApiSummary = false;
        });
      }
    }
  }

  Future<void> _onHistoryRowsChanged(int? value) async {
    if (value == null || value == _selectedHistoryRows) return;
    setState(() {
      _selectedHistoryRows = value;
    });
    await _loadSensorSummary(showLoader: false);
  }

  Future<void> _onTestingRowsChanged(int? value) async {
    if (value == null || value == _selectedTestingRows) return;
    setState(() {
      _selectedTestingRows = value;
    });
    await _loadSensorSummary(showLoader: false);
  }

  String _formatHistoryTimestamp(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('dd MMM yyyy HH:mm:ss', 'id_ID').format(value.toLocal());
  }

  Future<void> _loadUserProfile() async {
    // 1. Fallback dari secure storage (Prioritas jika args tidak ada)
    final storedUsername = await _authStorage.readUsername();
    final storedEmail = await _authStorage.readEmail();

    if (mounted) {
      bool needUpdate = false;
      String? nextUsername = _username;
      String? nextEmail = _email;

      if (_username == null || _username!.isEmpty || _username == 'Pengguna') {
        nextUsername =
            (storedUsername != null && storedUsername.isNotEmpty)
                ? storedUsername
                : nextUsername;
        needUpdate = true;
      }

      if (_email == null || _email!.isEmpty) {
        nextEmail =
            (storedEmail != null && storedEmail.isNotEmpty)
                ? storedEmail
                : nextEmail;
        needUpdate = true;
      }

      if (needUpdate) {
        setState(() {
          _username = nextUsername;
          _email = nextEmail;
        });
      }
    }

    // 2. Fetch fresh data dari backend /api/mobile/profile
    try {
      final user = await AuthService().getCurrentUser();
      if (mounted) {
        final newName = user['name']?.toString();
        final newEmail = user['email']?.toString();

        if ((newName != null && newName != _username) ||
            (newEmail != null && newEmail != _email)) {
          setState(() {
            _username = newName ?? _username;
            _email = newEmail ?? _email;
          });
        }
      }
    } on UnauthorizedException {
      if (mounted) {
        await _authStorage.clearSession();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } catch (_) {
      // Tetap gunakan data yang sudah ada
    }
  }

  void _showApiError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
      _formattedTime = DateFormat('HH:mm:ss').format(now);
    });
  }

  void _startLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationMessage = "Layanan lokasi tidak diaktifkan.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationMessage = "Izin lokasi ditolak.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _locationMessage = "Izin lokasi ditolak secara permanen.");
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) async {
      final securityMessage = await _locationSecurityService.validatePosition(
        position,
      );
      if (securityMessage != null) {
        setState(() {
          _locationMessage = securityMessage;
          _speed = 0.0;
        });
        return;
      }

      if (_previousPosition != null) {
        double distance = Geolocator.distanceBetween(
          _previousPosition!.latitude,
          _previousPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        _speed = distance / 1;
      }
      _previousPosition = position;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        Placemark place = placemarks[0];
        setState(() {
          _locationMessage =
              "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
        });
      } catch (e) {
        setState(() {
          _locationMessage = "Gagal mendapatkan alamat: $e";
        });
      }
    });
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    _timer.cancel();
    await _positionStream?.cancel();

    try {
      await _authService.logout();
    } on UnauthorizedException {
      // Session memang sudah tidak valid. Tetap lanjutkan proses logout lokal.
    } on ApiException {
      // Token tetap dihapus dari secure storage pada AuthService.logout().
    }

    if (!mounted) return;
    setState(() {
      _locationMessage = "Mendapatkan lokasi...";
      _speed = 0.0;
      _previousPosition = null;
      _username = null;
      _email = null;
      _latestCount = 0;
      _alertsCount = 0;
      _historyCount = 0;
      _historyRows = const <SensorReading>[];
      _historyErrorMessage = null;
      _isLoggingOut = false;
    });

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F2),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF1B5E20),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1B5E20),
                      Color(0xFF2E7D32),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ProfileView(username: _username, email: _email),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: const AssetImage(
                          'assets/images/user.png',
                        ),
                        backgroundColor: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _username ?? "Pengguna",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _email ?? "-",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(LucideIcons.flaskConical, color: Colors.white),
                title: Text("Pengujian", style: GoogleFonts.poppins(color: Colors.white, fontSize: 15)),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.pushNamed(context, '/test_location');
                  if (!mounted || _isDisposed) return;
                  _loadSensorSummary(showLoader: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.monitor_heart, color: Colors.white),
                title: Text("Monitoring", style: GoogleFonts.poppins(color: Colors.white, fontSize: 15)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MonitoringScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_rounded, color: Colors.white),
                title: Text("Profil", style: GoogleFonts.poppins(color: Colors.white, fontSize: 15)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileView(username: _username, email: _email)));
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.logOut, color: Colors.white),
                title: Text("Logout", style: GoogleFonts.poppins(color: Colors.white, fontSize: 15)),
                onTap: () => _logout(),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text("Dashboard", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ProfileView(
                                  username: _username,
                                  email: _email,
                                ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: const AssetImage(
                              'assets/images/user.png',
                            ),
                            backgroundColor: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _username ?? "Pengguna",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent.shade700,
                                ),
                              ),
                              Text(
                                "Lihat Profil",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _formattedDate,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E7D32),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formattedTime,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Lokasi: $_locationMessage",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Kecepatan: ${_speed.toStringAsFixed(2)} m/s",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.activity,
                          color: Color(0xFF2E7D32),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Ringkasan Sensor API",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E7D32),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingApiSummary)
                      Text(
                        "Memuat ringkasan API...",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black45,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildApiSummaryCard(
                                "Latest",
                                _latestCount.toString(),
                                Icons.sensors,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildApiSummaryCard(
                                "Alerts",
                                _alertsCount.toString(),
                                Icons.warning_amber_rounded,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildApiSummaryCard(
                                "Histori",
                                _historyCount.toString(),
                                Icons.history,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.table,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Historis Data Sensor",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/history'),
                                child: Text(
                                  "Lihat Semua >",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF43A047),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _selectedHistoryRows,
                          borderRadius: BorderRadius.circular(12),
                          underline: const SizedBox(),
                          onChanged:
                              _isLoadingApiSummary
                                  ? null
                                  : _onHistoryRowsChanged,
                          items:
                              _historyRowOptions
                                  .map(
                                    (value) => DropdownMenuItem<int>(
                                      value: value,
                                      child: Text(
                                        '$value',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingApiSummary)
                      Text(
                        "Memuat histori data...",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black45,
                        ),
                      )
                    else if (_historyErrorMessage != null)
                      Text(
                        _historyErrorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red.shade400,
                        ),
                      )
                    else if (_historyRows.isEmpty)
                      Text(
                        "Belum ada data histori.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black45,
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 400),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Scrollbar(
                          controller: _historyScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _historyScrollController,
                            scrollDirection: Axis.vertical,
                            primary: false,
                            physics: const BouncingScrollPhysics(),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth:
                                      MediaQuery.of(context).size.width * 1.8,
                                ),
                                child: DataTable(
                                  columnSpacing: 24,
                                  headingTextStyle: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                  dataTextStyle: GoogleFonts.poppins(
                                    fontSize: 12,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('Waktu')),
                                    DataColumn(label: Text('EC')),
                                    DataColumn(label: Text('TDS')),
                                    DataColumn(label: Text('pH')),
                                    DataColumn(label: Text('CR Est')),
                                    DataColumn(label: Text('Status')),
                                  ],
                                  rows:
                                      _historyRows
                                          .take(_selectedHistoryRows)
                                          .map(
                                            (row) => DataRow(
                                              cells: [
                                                DataCell(
                                                  Text(
                                                    _formatHistoryTimestamp(
                                                      row.createdAt,
                                                    ),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    row.ec?.toStringAsFixed(
                                                          2,
                                                        ) ??
                                                        '-',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    row.tds?.toStringAsFixed(
                                                          2,
                                                        ) ??
                                                        '-',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    row.ph?.toStringAsFixed(
                                                          2,
                                                        ) ??
                                                        '-',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    row.crEstimated
                                                            ?.toStringAsFixed(
                                                              2,
                                                            ) ??
                                                        '-',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    row.status,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          color: Colors.green.shade600,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Histori Pengujian",
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              GestureDetector(
                                onTap:
                                    () => Navigator.pushNamed(
                                      context,
                                      '/testing-history',
                                    ),
                                child: Text(
                                  "Lihat Semua >",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _selectedTestingRows,
                          borderRadius: BorderRadius.circular(12),
                          underline: const SizedBox(),
                          onChanged:
                              _isLoadingApiSummary
                                  ? null
                                  : _onTestingRowsChanged,
                          items:
                              _historyRowOptions
                                  .map(
                                    (value) => DropdownMenuItem<int>(
                                      value: value,
                                      child: Text(
                                        '$value',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingApiSummary)
                      Text(
                        "Memuat histori pengujian...",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black45,
                        ),
                      )
                    else if (_testingHistoryRows.isEmpty)
                      Text(
                        "Belum ada data pengujian tersimpan.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black45,
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 400),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Scrollbar(
                          controller: _testingHistoryScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _testingHistoryScrollController,
                            scrollDirection: Axis.vertical,
                            primary: false,
                            physics: const BouncingScrollPhysics(),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth:
                                      MediaQuery.of(context).size.width * 1.8,
                                ),
                                child: DataTable(
                                  columnSpacing: 24,
                                  headingTextStyle: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                  dataTextStyle: GoogleFonts.poppins(
                                    fontSize: 12,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('Waktu')),
                                    DataColumn(label: Text('Petugas')),
                                    DataColumn(
                                      label: Text('Lokasi (Lat,Lng,Alt)'),
                                    ),
                                    DataColumn(label: Text('TDS')),
                                    DataColumn(label: Text('pH')),
                                    DataColumn(label: Text('CR Est')),
                                  ],
                                  rows:
                                      _testingHistoryRows
                                          .take(_selectedTestingRows)
                                          .map(
                                            (row) => DataRow(
                                              cells: [
                                                DataCell(
                                                  Text(
                                                    row['created_at'] != null
                                                        ? DateFormat(
                                                          'dd/MM HH:mm',
                                                        ).format(
                                                          DateTime.parse(
                                                            row['created_at'],
                                                          ).toLocal(),
                                                        )
                                                        : '-',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    row['petugas']
                                                            ?.toString() ??
                                                        '-',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    (row['latitude'] != null &&
                                                            row['longitude'] !=
                                                                null)
                                                        ? "${double.parse(row['latitude'].toString()).toStringAsFixed(4)}, ${double.parse(row['longitude'].toString()).toStringAsFixed(4)}, ${row['altitude'] != null ? "${double.parse(row['altitude'].toString()).toStringAsFixed(2)} m" : "-"}"
                                                        : "-",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    row['tds'] != null
                                                        ? double.parse(
                                                          row['tds'].toString(),
                                                        ).toStringAsFixed(1)
                                                        : '-',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    row['ph'] != null
                                                        ? double.parse(
                                                          row['ph'].toString(),
                                                        ).toStringAsFixed(1)
                                                        : '-',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    row['cr_estimated'] != null
                                                        ? double.parse(
                                                          row['cr_estimated']
                                                              .toString(),
                                                        ).toStringAsFixed(2)
                                                        : '-',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiSummaryCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
