import 'package:flutter/material.dart';
import 'package:glosindo_connect/screens/presensi_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/presensi_viewmodel.dart';
import 'tiket_screen.dart';
import 'report_progress_screen.dart';
import 'kasbon_screen.dart';
import 'pengajuan_screen.dart';
import 'shifting_screen.dart';
import 'profile_screen.dart';
import 'company_info_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final presensiViewModel = context.read<PresensiViewModel>();
    await presensiViewModel.fetchTodayPresensi();
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
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PresensiScreen(),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.access_time,
                                      color: Colors.blue.shade700,
                                      size: 32,
                                    ),
                                  ),
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
                            Consumer<PresensiViewModel>(
                              builder: (context, presensiViewModel, _) {
                                return ElevatedButton.icon(
                                  onPressed: presensiViewModel.isLoading
                                      ? null
                                      : () async {
                                          // Langsung call checkIn
                                          final success =
                                              await presensiViewModel.checkIn();

                                          if (context.mounted) {
                                            if (success) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Check-in berhasil!',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  duration: Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            } else if (presensiViewModel
                                                    .errorMessage !=
                                                null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    presensiViewModel
                                                        .errorMessage!,
                                                  ),
                                                  backgroundColor: Colors.red,
                                                  duration: const Duration(
                                                    seconds: 3,
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  icon: presensiViewModel.isLoading
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
                                    presensiViewModel.isLoading
                                        ? 'Loading...'
                                        : 'Presensi Sekarang',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E88E5),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(44),
                                  ),
                                );
                              },
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
