import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/presensi_viewmodel.dart';
import 'presensi_screen.dart';
import 'tiket_screen.dart';
import 'report_progress_screen.dart';
import 'kasbon_screen.dart';
import 'pengajuan_screen.dart';
import 'shifting_screen.dart';
import 'profile_screen.dart';
import 'company_info_screen.dart';
import 'attendance_confirmation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final presensiViewModel = context.read<PresensiViewModel>();
    await presensiViewModel.fetchTodayPresensi();
  }

  // ==================== ATTENDANCE FLOW HANDLER ====================

  Future<void> _handleAttendance() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Step 1: Check and request permissions
      print('📱 Step 1: Requesting permissions...');
      final permissionsGranted = await _requestPermissions();

      if (!permissionsGranted) {
        print('❌ Permissions denied');
        setState(() => _isProcessing = false);
        return;
      }
      print('✅ Permissions granted');

      // Step 2: Capture image
      print('📷 Step 2: Opening camera...');
      final imagePath = await _captureImage();

      if (imagePath == null) {
        print('❌ Image capture cancelled');
        setState(() => _isProcessing = false);
        return; // User cancelled
      }
      print('✅ Image captured: $imagePath');

      // Step 3: Show loading while getting location
      if (mounted) {
        print('📍 Step 3: Getting GPS location...');
        _showLoadingDialog('Mengambil lokasi...');
      }

      // Step 4: Get current location
      final position = await _getCurrentLocation();
      print('✅ Location obtained: ${position.latitude}, ${position.longitude}');

      // Step 5: Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Step 6: Navigate to confirmation screen
      if (mounted) {
        print('🚀 Step 4: Navigating to confirmation screen...');
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttendanceConfirmationScreen(
              imagePath: imagePath,
              latitude: position.latitude,
              longitude: position.longitude,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error in attendance flow: $e');
      if (mounted) {
        // Close loading dialog if open
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showError('Terjadi kesalahan: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // Check and request camera & location permissions
  Future<bool> _requestPermissions() async {
    try {
      // Check location service enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Mohon aktifkan GPS/Lokasi di pengaturan HP Anda');
        return false;
      }

      // Request location permission using Geolocator
      LocationPermission locationPermission =
          await Geolocator.checkPermission();
      if (locationPermission == LocationPermission.denied) {
        locationPermission = await Geolocator.requestPermission();
        if (locationPermission == LocationPermission.denied) {
          _showError('Izin lokasi ditolak');
          return false;
        }
      }

      if (locationPermission == LocationPermission.deniedForever) {
        _showPermissionDialog();
        return false;
      }

      // Request camera permission using permission_handler
      var cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          _showError('Izin kamera ditolak');
          return false;
        }
      }

      if (cameraStatus.isPermanentlyDenied) {
        _showPermissionDialog();
        return false;
      }

      return true;
    } catch (e) {
      print('Permission error: $e');
      _showError('Gagal meminta izin: ${e.toString()}');
      return false;
    }
  }

  // Capture image using camera
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

  // Get current GPS location
  Future<Position> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return position;
    } catch (e) {
      throw Exception('Gagal mendapatkan lokasi: ${e.toString()}');
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

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
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
                        padding: const EdgeInsets.all(16),
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
                                Icon(
                                  Icons.access_time,
                                  color: Colors.blue.shade700,
                                  size: 32,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Consumer<PresensiViewModel>(
                              builder: (context, presensiViewModel, _) {
                                final todayPresensi =
                                    presensiViewModel.todayPresensi;

                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimeCard(
                                        'Check In',
                                        todayPresensi?.checkInTime != null
                                            ? DateFormat('HH:mm').format(
                                                todayPresensi!.checkInTime!,
                                              )
                                            : '--:--',
                                        Icons.login,
                                        Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTimeCard(
                                        'Check Out',
                                        todayPresensi?.checkOutTime != null
                                            ? DateFormat('HH:mm').format(
                                                todayPresensi!.checkOutTime!,
                                              )
                                            : '--:--',
                                        Icons.logout,
                                        Colors.orange,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _isProcessing
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
                                  : const Icon(Icons.fingerprint),
                              label: Text(
                                _isProcessing
                                    ? 'Processing...'
                                    : 'Presensi Sekarang',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
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
                      const SizedBox(height: 16),
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
                                builder: (_) => const TiketScreen(),
                              ),
                            ),
                          ),
                          _buildMenuCard(
                            'Presensi',
                            Icons.access_time,
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
                            Icons.schedule_outlined,
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
