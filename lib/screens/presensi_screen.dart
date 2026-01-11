import 'package:flutter/material.dart';
import 'package:glosindo_connect/models/presensi_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../viewmodels/presensi_viewmodel.dart';

class PresensiScreen extends StatefulWidget {
  const PresensiScreen({Key? key}) : super(key: key);

  @override
  State<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    final viewModel = context.read<PresensiViewModel>();
    await viewModel.fetchTodayPresensi();
    await viewModel.fetchPresensiHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Consumer<PresensiViewModel>(
        builder: (context, viewModel, _) {
          return Column(
            children: [
              // Calendar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: const Color(0xFF1E88E5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    formatButtonTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    titleTextStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF1E88E5),
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: const TextStyle(color: Colors.red),
                    outsideDaysVisible: false,
                    markerDecoration: BoxDecoration(
                      color: Colors.green.shade700,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      // Cek apakah ada presensi di tanggal ini
                      final hasPresensi = viewModel.presensiList.any(
                        (p) =>
                            p.date.year == date.year &&
                            p.date.month == date.month &&
                            p.date.day == date.day,
                      );

                      if (hasPresensi) {
                        return Positioned(
                          bottom: 1,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Presensi List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Presensi',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_getPresensiForSelectedDate(viewModel) != null)
                      _buildStatusBadge(
                        _getPresensiForSelectedDate(viewModel)!.status,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Presensi Details
              Expanded(
                child: viewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildPresensiList(viewModel),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildPresensiList(PresensiViewModel viewModel) {
    final selectedPresensi = _getPresensiForSelectedDate(viewModel);

    if (selectedPresensi != null) {
      // Tampilkan detail presensi untuk tanggal yang dipilih
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Check In Card
            _buildTimeCard(
              'Check In',
              selectedPresensi.checkInTime,
              selectedPresensi.checkInLat,
              selectedPresensi.checkInLng,
              Icons.login,
              Colors.green,
            ),

            const SizedBox(height: 12),

            // Check Out Card
            _buildTimeCard(
              'Check Out',
              selectedPresensi.checkOutTime,
              selectedPresensi.checkOutLat,
              selectedPresensi.checkOutLng,
              Icons.logout,
              Colors.orange,
            ),

            const SizedBox(height: 16),

            // Working Hours
            if (selectedPresensi.checkInTime != null &&
                selectedPresensi.checkOutTime != null)
              _buildWorkingHoursCard(
                selectedPresensi.checkInTime!,
                selectedPresensi.checkOutTime!,
              ),
          ],
        ),
      );
    } else if (_selectedDay != null &&
        isSameDay(_selectedDay, DateTime.now())) {
      // Hari ini tapi belum presensi
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Belum melakukan presensi hari ini',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => {},
              icon: const Icon(Icons.login),
              label: const Text('Check In Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Tanggal lain, tidak ada data
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data presensi\npada tanggal ini',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTimeCard(
    String label,
    DateTime? time,
    double? lat,
    double? lng,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: time != null ? color : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time != null
                          ? DateFormat('HH:mm:ss').format(time)
                          : '--:--:--',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: time != null ? color : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (time != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Sukses',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (lat != null && lng != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkingHoursCard(DateTime checkIn, DateTime checkOut) {
    final duration = checkOut.difference(checkIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Jam Kerja',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '$hours jam $minutes menit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'hadir':
        color = Colors.green;
        break;
      case 'terlambat':
        color = Colors.orange;
        break;
      case 'izin':
        color = Colors.blue;
        break;
      case 'alpha':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Consumer<PresensiViewModel>(
      builder: (context, viewModel, _) {
        final todayPresensi = viewModel.todayPresensi;
        final isToday =
            _selectedDay != null && isSameDay(_selectedDay, DateTime.now());

        if (!isToday) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Check Out Button
            if (todayPresensi?.checkInTime != null &&
                todayPresensi?.checkOutTime == null)
              FloatingActionButton.extended(
                onPressed: viewModel.isLoading ? null : () => {},
                heroTag: 'checkout',
                backgroundColor: Colors.orange,
                icon: const Icon(Icons.logout),
                label: const Text('Check Out'),
              ),

            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  PresensiModel? _getPresensiForSelectedDate(PresensiViewModel viewModel) {
    if (_selectedDay == null) return null;

    try {
      return viewModel.presensiList.firstWhere(
        (p) =>
            p.date.year == _selectedDay!.year &&
            p.date.month == _selectedDay!.month &&
            p.date.day == _selectedDay!.day,
      );
    } catch (e) {
      return null;
    }
  }

  // Future<void> _handleCheckIn() async {
  //   final viewModel = context.read<PresensiViewModel>();
  //   final success = await viewModel.checkIn();

  //   if (!mounted) return;

  //   if (success) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Check-in berhasil!'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //     await _loadData();
  //   } else if (viewModel.errorMessage != null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(viewModel.errorMessage!),
  //         backgroundColor: Colors.red,
  //         duration: const Duration(seconds: 3),
  //       ),
  //     );
  //   }
  // }

  // Future<void> _handleCheckOut() async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Konfirmasi Check Out'),
  //       content: const Text('Apakah Anda yakin ingin melakukan check out?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('Batal'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
  //           child: const Text('Ya, Check Out'),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirmed != true) return;

  //   final viewModel = context.read<PresensiViewModel>();
  //   final success = await viewModel.checkOut();

  //   if (!mounted) return;

  //   if (success) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Check-out berhasil!'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //     await _loadData();
  //   } else if (viewModel.errorMessage != null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(viewModel.errorMessage!),
  //         backgroundColor: Colors.red,
  //         duration: const Duration(seconds: 3),
  //       ),
  //     );
  //   }
  // }
}
