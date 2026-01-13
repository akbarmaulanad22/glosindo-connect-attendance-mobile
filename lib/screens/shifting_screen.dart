import 'package:flutter/material.dart';
import 'package:glosindo_connect/viewmodels/shifting_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class ShiftingScreen extends StatefulWidget {
  const ShiftingScreen({super.key});

  @override
  State<ShiftingScreen> createState() => _ShiftingScreenState();
}

class _ShiftingScreenState extends State<ShiftingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    final viewModel = context.read<ShiftingViewModel>();
    final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    await viewModel.fetchShiftSchedule(startDate, endDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Shifting')),
      body: Consumer<ShiftingViewModel>(
        builder: (context, viewModel, _) {
          return Column(
            children: [
              // Wrap TableCalendar dengan Container untuk memberikan constraint
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  startingDayOfWeek: StartingDayOfWeek.monday,

                  // Properti penting untuk sizing yang konsisten
                  daysOfWeekHeight: 40,
                  rowHeight: 48,

                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                    CalendarFormat.twoWeeks: '2 Weeks',
                    CalendarFormat.week: 'Week',
                  },

                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF1E88E5),
                      shape: BoxShape.circle,
                    ),
                    // Properti tambahan untuk styling yang lebih baik
                    markersMaxCount: 1,
                    canMarkersOverflow: false,
                  ),

                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
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
                    _loadData();
                  },

                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },

                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      final shift = viewModel.getShiftForDate(date);
                      if (shift != null) {
                        return Positioned(
                          bottom: 1,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getShiftColor(shift.shiftType),
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

              // Gunakan Expanded untuk konten detail shift
              Expanded(
                child: SingleChildScrollView(
                  child: _selectedDay != null
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildShiftDetail(
                            viewModel.getShiftForDate(_selectedDay!),
                          ),
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Pilih tanggal untuk melihat detail shift',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShiftDetail(shift) {
    if (shift == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Tidak ada shift pada tanggal ini'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getShiftColor(shift.shiftType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getShiftColor(shift.shiftType)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: _getShiftColor(shift.shiftType)),
              const SizedBox(width: 8),
              Text(
                'Shift ${shift.shiftType.toUpperCase()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getShiftColor(shift.shiftType),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text('${shift.startTime} - ${shift.endTime}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(shift.location),
            ],
          ),
        ],
      ),
    );
  }

  Color _getShiftColor(String shiftType) {
    switch (shiftType.toLowerCase()) {
      case 'pagi':
        return Colors.orange;
      case 'siang':
        return Colors.blue;
      case 'malam':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
