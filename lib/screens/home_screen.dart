import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/location_service.dart';
import '../services/image_watermark_service.dart';
import '../services/attendance_service.dart';
import 'presensi_screen.dart';
import 'ticket_screen.dart';
import 'report_progress_screen.dart';
import 'kasbon_screen.dart';
import 'pengajuan_screen.dart';
import 'shifting_screen.dart';
import 'profile_screen.dart';
import 'company_info_screen.dart';
import 'attendance_confirmation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ImagePicker _imagePicker = ImagePicker();
  final LocationService _locationService = LocationService();
  final ImageWatermarkService _watermarkService = ImageWatermarkService();
  final AttendanceService _attendanceService = AttendanceService();

  bool _isProcessing = false;

  // ==================== ATTENDANCE STATE ====================
  bool _isLoadingAttendance = true;
  String? _clockInTime;
  String? _clockOutTime;
  bool _hasClockIn = false;
  bool _hasClockOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTodayAttendance();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ==================== LIFECYCLE OBSERVER ====================

  /// Handle app lifecycle changes
  /// This is critical for detecting when user returns from Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('📱 App Lifecycle State: $state');

    if (state == AppLifecycleState.resumed) {
      // User returned to app (possibly from Settings)
      debugPrint('🔄 App resumed - User returned to app');

      // Re-check location service status if we were waiting for it
      if (_waitingForLocationService) {
        debugPrint('🔍 Re-checking location service status...');
        _recheckLocationServiceAfterResume();
      }
    }
  }

  // Flag to track if we're waiting for user to enable location
  bool _waitingForLocationService = false;

  /// Re-check location service after user returns from Settings
  Future<void> _recheckLocationServiceAfterResume() async {
    setState(() => _waitingForLocationService = false);

    // Give a small delay for system to update
    await Future.delayed(const Duration(milliseconds: 300));

    // Check if location is now enabled
    final isEnabled = await Geolocator.isLocationServiceEnabled();

    if (isEnabled) {
      debugPrint('✅ Location service is now ENABLED');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('GPS berhasil diaktifkan!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      debugPrint('⚠️ Location service is still DISABLED');
    }
  }

  // ==================== LOAD TODAY'S ATTENDANCE ====================

  /// Fetch today's attendance data on init
  Future<void> _loadTodayAttendance() async {
    setState(() => _isLoadingAttendance = true);

    try {
      debugPrint('📊 Loading today\'s attendance...');

      final response = await _attendanceService.getTodayAttendance();

      if (response['success'] == true) {
        if (response['hasAttendance'] == true && response['data'] != null) {
          final data = response['data'];

          // Parse clock_in and clock_out
          final clockIn = data['clock_in'];
          final clockOut = data['clock_out'];

          setState(() {
            _hasClockIn = clockIn != null;
            _hasClockOut = clockOut != null;

            // Parse time strings for display
            if (clockIn != null) {
              try {
                final dateTime = DateTime.parse(clockIn);
                _clockInTime = DateFormat('HH:mm').format(dateTime);
              } catch (e) {
                _clockInTime = '--:--';
                debugPrint('Error parsing clock_in: $e');
              }
            }

            if (clockOut != null) {
              try {
                final dateTime = DateTime.parse(clockOut);
                _clockOutTime = DateFormat('HH:mm').format(dateTime);
              } catch (e) {
                _clockOutTime = '--:--';
                debugPrint('Error parsing clock_out: $e');
              }
            }
          });

          debugPrint('✅ Attendance loaded:');
          debugPrint('   Clock In: ${_hasClockIn ? _clockInTime : "Not yet"}');
          debugPrint(
            '   Clock Out: ${_hasClockOut ? _clockOutTime : "Not yet"}',
          );
        } else {
          // No attendance today
          setState(() {
            _hasClockIn = false;
            _hasClockOut = false;
            _clockInTime = null;
            _clockOutTime = null;
          });
          debugPrint('ℹ️ No attendance today');
        }
      } else {
        // API error
        debugPrint('❌ Failed to load attendance: ${response['error']}');
      }
    } catch (e) {
      debugPrint('❌ Error loading attendance: $e');
    } finally {
      setState(() => _isLoadingAttendance = false);
    }
  }

  // ==================== REVISED ATTENDANCE FLOW HANDLER ====================

  Future<void> _handleAttendance() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // STEP 1: STRICT Location Service Check (GPS + Permissions)
      print('📱 STEP 1: Strict location service check...');
      final locationOK = await _checkLocationServiceStrict();

      if (!locationOK) {
        print('❌ Location service check failed');
        setState(() => _isProcessing = false);
        return;
      }
      print('✅ Location service OK');

      // STEP 2: Validate location (Mock GPS check)
      print('📍 STEP 2: Validating location (Mock GPS check)...');

      Position position;
      try {
        position = await _locationService.getCurrentPositionWithValidation();
        print(
          '✅ Location validated: ${position.latitude}, ${position.longitude}',
        );
      } on MockLocationException {
        // Mock location detected!
        print('❌ Mock Location Detected!');
        if (mounted) {
          _showMockLocationDialog();
        }
        setState(() => _isProcessing = false);
        return;
      } catch (e) {
        print('❌ Location error: $e');
        if (mounted) {
          _showError('Gagal mendapatkan lokasi: ${e.toString()}');
        }
        setState(() => _isProcessing = false);
        return;
      }

      // STEP 3: Capture image
      print('📷 STEP 3: Opening camera...');
      final imagePath = await _captureImage();

      if (imagePath == null) {
        print('❌ Image capture cancelled');
        setState(() => _isProcessing = false);
        return;
      }
      print('✅ Image captured: $imagePath');

      // STEP 4: Process image (Watermark)
      print('🎨 STEP 4: Adding watermark...');
      if (mounted) {
        _showLoadingDialog('Memproses foto...');
      }

      final watermarkedPath = await _watermarkService.addWatermark(
        imagePath: imagePath,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      print('✅ Watermark applied: $watermarkedPath');

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // STEP 5: Determine action based on CURRENT STATE
      print('🔍 STEP 5: Determining action...');
      final bool isClockOut = _hasClockIn && !_hasClockOut;

      print('📊 Current State:');
      print('   Has Clock In: $_hasClockIn');
      print('   Has Clock Out: $_hasClockOut');
      print('   Action: ${isClockOut ? "CLOCK OUT" : "CLOCK IN"}');

      // STEP 6: Navigate to confirmation screen
      if (mounted) {
        print('🚀 STEP 6: Navigating to confirmation screen...');
        final success = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => AttendanceConfirmationScreen(
              imagePath: watermarkedPath,
              latitude: position.latitude,
              longitude: position.longitude,
              isClockOut: isClockOut,
            ),
          ),
        );

        // Refresh data if successful
        if (success == true) {
          print('✅ Attendance successful - Reloading data...');
          await _loadTodayAttendance();
        }
      }
    } catch (e) {
      print('❌ Error in attendance flow: $e');
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showError('Terjadi kesalahan: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ==================== STRICT LOCATION CHECK WITH RESUME SUPPORT ====================

  /// STRICT CHECK: GPS Service + Permissions
  ///
  /// Step 1: Check if GPS/Location Service is enabled
  /// Step 2: Check location permissions
  ///
  /// Returns true if all checks pass, false otherwise
  ///
  /// IMPROVED: Now waits for user to return from Settings
  Future<bool> _checkLocationServiceStrict() async {
    try {
      // ==================== CHECK 1: GPS HARDWARE ====================
      debugPrint('🔍 Check 1: GPS Service Status...');

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint('❌ GPS is DISABLED');

        // Set flag that we're waiting for location service
        setState(() => _waitingForLocationService = true);

        // Show dialog to ask user to enable GPS
        if (!mounted) return false;

        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async {
              // Allow user to dismiss
              setState(() => _waitingForLocationService = false);
              return true;
            },
            child: AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.location_off, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Text('GPS Tidak Aktif'),
                ],
              ),
              content: const Text(
                'Aplikasi memerlukan GPS untuk verifikasi lokasi presensi.\n\n'
                'Mohon aktifkan GPS/Lokasi di pengaturan perangkat Anda.',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => _waitingForLocationService = false);
                    Navigator.pop(context, false);
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.settings),
                  label: const Text('Buka Pengaturan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );

        if (shouldOpenSettings == true) {
          debugPrint('📱 Opening location settings...');

          // Open location settings
          await Geolocator.openLocationSettings();

          // Wait for user to return (handled by didChangeAppLifecycleState)
          // Small delay to let the settings app open
          await Future.delayed(const Duration(milliseconds: 500));

          // CRITICAL: Re-check after user might have enabled GPS
          debugPrint('🔄 Re-checking GPS status after settings...');
          serviceEnabled = await Geolocator.isLocationServiceEnabled();

          if (!serviceEnabled) {
            // Still disabled after returning from settings
            setState(() => _waitingForLocationService = false);

            if (mounted) {
              _showError(
                'GPS masih belum aktif. Mohon aktifkan GPS terlebih dahulu.',
              );
            }
            return false;
          } else {
            // Successfully enabled!
            debugPrint('✅ GPS is now ENABLED');
            setState(() => _waitingForLocationService = false);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('GPS berhasil diaktifkan!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } else {
          // User cancelled
          setState(() => _waitingForLocationService = false);
          return false;
        }
      } else {
        debugPrint('✅ GPS is ENABLED');
      }

      // ==================== CHECK 2: PERMISSIONS ====================
      debugPrint('🔍 Check 2: Location Permission...');

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ Permission DENIED - Requesting...');
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          debugPrint('❌ Permission DENIED by user');
          if (mounted) {
            _showError(
              'Izin lokasi ditolak. Aplikasi memerlukan izin lokasi untuk presensi.',
            );
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Permission DENIED FOREVER');
        if (mounted) {
          _showPermissionDialog();
        }
        return false;
      }

      debugPrint('✅ Location permission granted');

      // ==================== CHECK 3: CAMERA PERMISSION ====================
      debugPrint('🔍 Check 3: Camera Permission...');

      var cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          if (mounted) {
            _showError('Izin kamera ditolak');
          }
          return false;
        }
      }

      if (cameraStatus.isPermanentlyDenied) {
        if (mounted) {
          _showPermissionDialog();
        }
        return false;
      }

      debugPrint('✅ All permissions granted');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking location service: $e');
      setState(() => _waitingForLocationService = false);

      if (mounted) {
        _showError('Gagal memeriksa layanan lokasi: ${e.toString()}');
      }
      return false;
    }
  }

  // Capture image using front camera
  Future<String?> _captureImage() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      return photo?.path;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  // Show loading dialog
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  // Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show permission dialog
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izin Diperlukan'),
        content: const Text(
          'Aplikasi memerlukan izin kamera dan lokasi untuk fitur presensi. '
          'Silakan aktifkan di pengaturan aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  // Show CRITICAL blocking dialog for Mock Location
  void _showMockLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Lokasi Palsu Terdeteksi'),
          ],
        ),
        content: const Text(
          'Aplikasi mendeteksi Anda menggunakan Fake GPS atau lokasi palsu. '
          'Mohon matikan aplikasi Fake GPS dan aktifkan lokasi asli untuk melanjutkan presensi.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // 🔥 FIXED: Transparent status bar
        statusBarIconBrightness:
            Brightness.light, // White icons on blue background
        statusBarBrightness: Brightness.dark, // For iOS
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: RefreshIndicator(
          onRefresh: _loadTodayAttendance,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      // AppBar custom
                      Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 16,
                          left: 16,
                          right: 16,
                          bottom: 16,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white,
                              child: Text(
                                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E88E5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Halo, ${user?.name ?? "User"}!',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    user?.jabatan ?? 'Karyawan',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Tidak ada notifikasi baru'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Quick Presensi Card
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Presensi Hari Ini',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat(
                                        'EEEE, dd MMMM yyyy',
                                        'id_ID',
                                      ).format(DateTime.now()),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PresensiScreen(),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.access_time,
                                    color: Colors.blue.shade700,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTimeCard(
                                    'Check In',
                                    _clockInTime ?? '--:--',
                                    Icons.login,
                                    Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTimeCard(
                                    'Check Out',
                                    _clockOutTime ?? '--:--',
                                    Icons.logout,
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // DYNAMIC BUTTON - Clock In or Clock Out
                            _isLoadingAttendance
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: _hasClockOut || _isProcessing
                                        ? null
                                        : _handleAttendance,
                                    icon: _isProcessing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            _hasClockIn && !_hasClockOut
                                                ? Icons.logout
                                                : Icons.fingerprint,
                                          ),
                                    label: Text(
                                      _isProcessing
                                          ? 'Processing...'
                                          : _hasClockOut
                                          ? 'Presensi Selesai'
                                          : _hasClockIn
                                          ? 'Clock Out Sekarang'
                                          : 'Clock In Sekarang',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _hasClockOut
                                          ? Colors.grey
                                          : _hasClockIn
                                          ? Colors.orange
                                          : const Color(0xFF1E88E5),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(44),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Menu Grid
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Menu Utama',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          _buildMenuCard(
                            'Report Progress',
                            Icons.analytics_outlined,
                            Colors.purple,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReportProgressScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            'Informasi Tiket',
                            Icons.confirmation_number_outlined,
                            Colors.orange,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TicketScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            'Riwayat Presensi',
                            Icons.history,
                            Colors.green,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PresensiScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            'Kasbon',
                            Icons.account_balance_wallet_outlined,
                            Colors.green,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const KasbonScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            'Lembur/Izin/Cuti',
                            Icons.event_note_outlined,
                            Colors.blue,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PengajuanScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            'Shifting Kerja',
                            Icons.calendar_month,
                            Colors.teal,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ShiftingScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            'Data Pribadi',
                            Icons.person_outlined,
                            Colors.indigo,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            'Info Perusahaan',
                            Icons.business_outlined,
                            Colors.red,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CompanyInfoScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            'Logout',
                            Icons.logout,
                            Colors.grey,
                            () => _handleLogout(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard(String label, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authViewModel = context.read<AuthViewModel>();
      await authViewModel.logout();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}
