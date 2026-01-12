import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/presensi_model.dart';
import '../viewmodels/presensi_viewmodel.dart';

class PresensiScreen extends StatefulWidget {
  const PresensiScreen({super.key});

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
    _loadMonthlyData();
  }

  Future<void> _loadMonthlyData() async {
    final viewModel = context.read<PresensiViewModel>();

    // 🔥 Use NEW method: fetchMonthlyPresensi
    await viewModel.fetchMonthlyPresensi(
      month: _focusedDay.month,
      year: _focusedDay.year,
    );
  }

  /// Refresh current month data
  Future<void> _refreshData() async {
    final viewModel = context.read<PresensiViewModel>();
    await viewModel.refreshCurrentMonth();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Riwayat Presensi'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
              tooltip: 'Refresh',
            ),
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
                    onPageChanged: (focusedDay) async {
                      setState(() {
                        _focusedDay = focusedDay;
                      });

                      // 🔥 Use NEW method when month changes
                      await viewModel.fetchMonthlyPresensi(
                        month: focusedDay.month,
                        year: focusedDay.year,
                      );
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        // 🔥 Check from cached data (NO API call)
                        final hasPresensi = viewModel.hasPresensiForDate(date);

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

                // Presensi Details
                Expanded(
                  child:
                      viewModel.isLoadingMonthly &&
                          viewModel.presensiList.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _buildAttendanceDetails(viewModel),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAttendanceDetails(PresensiViewModel viewModel) {
    if (_selectedDay == null) {
      return const Center(child: Text('Pilih tanggal untuk melihat detail'));
    }

    // 🔥 Get presensi from CACHED data (NO API call)
    final selectedPresensi = viewModel.getPresensiForDate(_selectedDay!);

    if (selectedPresensi != null) {
      // Show attendance details
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
    } else {
      // No attendance for this date
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
}
