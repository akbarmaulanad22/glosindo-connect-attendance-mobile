import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

// ==================== ENUMS ====================

enum RequestType { lembur, ijin, cuti }

enum RequestStatus { pending, approved, rejected }

extension RequestTypeExtension on RequestType {
  String get displayName {
    switch (this) {
      case RequestType.lembur:
        return 'Lembur';
      case RequestType.ijin:
        return 'Ijin';
      case RequestType.cuti:
        return 'Cuti';
    }
  }

  String get value => toString().split('.').last;

  static RequestType fromString(String value) {
    return RequestType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RequestType.ijin,
    );
  }
}

extension RequestStatusExtension on RequestStatus {
  String get displayName {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
    }
  }

  String get value => toString().split('.').last;

  static RequestStatus fromString(String value) {
    return RequestStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RequestStatus.pending,
    );
  }
}

// ==================== MODEL ====================

class PengajuanModel {
  final String id;
  final RequestType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final DateTime createdAt;
  final RequestStatus status;

  PengajuanModel({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'status': status.value,
    };
  }

  factory PengajuanModel.fromJson(Map<String, dynamic> json) {
    return PengajuanModel(
      id: json['id']?.toString() ?? '',
      type: RequestTypeExtension.fromString(json['type']?.toString() ?? 'ijin'),
      startDate: DateTime.parse(
        json['startDate']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      endDate: DateTime.parse(
        json['endDate']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      reason: json['reason']?.toString() ?? '',
      createdAt: DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      status: RequestStatusExtension.fromString(
        json['status']?.toString() ?? 'pending',
      ),
    );
  }

  int get durationDays => endDate.difference(startDate).inDays + 1;
}

// ==================== DUMMY DATA ====================

final List<PengajuanModel> dummyRequests = [
  PengajuanModel(
    id: '1',
    type: RequestType.cuti,
    startDate: DateTime.now().add(const Duration(days: 5)),
    endDate: DateTime.now().add(const Duration(days: 8)),
    reason: 'Acara keluarga di luar kota',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    status: RequestStatus.pending,
  ),
  PengajuanModel(
    id: '2',
    type: RequestType.ijin,
    startDate: DateTime.now().add(const Duration(days: 1)),
    endDate: DateTime.now().add(const Duration(days: 1)),
    reason: 'Mengurus dokumen di kelurahan',
    createdAt: DateTime.now(),
    status: RequestStatus.approved,
  ),
  PengajuanModel(
    id: '3',
    type: RequestType.lembur,
    startDate: DateTime.now().subtract(const Duration(days: 2)),
    endDate: DateTime.now().subtract(const Duration(days: 2)),
    reason: 'Menyelesaikan project deadline',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    status: RequestStatus.rejected,
  ),
];

// ==================== MAIN SCREEN (HISTORY LIST) ====================

class PengajuanScreen extends StatefulWidget {
  const PengajuanScreen({Key? key}) : super(key: key);

  @override
  State<PengajuanScreen> createState() => _PengajuanScreenState();
}

class _PengajuanScreenState extends State<PengajuanScreen> {
  List<PengajuanModel> _requests = [];
  bool _isLoading = true;
  static const String _storageKey = 'leave_requests';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        setState(() {
          _requests = jsonList
              .map(
                (item) => PengajuanModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        });
      } else {
        // First time: load dummy data
        setState(() {
          _requests = dummyRequests;
        });
        await _saveDummyData();
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDummyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList = _requests
          .map((item) => item.toJson())
          .toList();
      final String jsonString = json.encode(jsonList);
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('Error saving dummy data: $e');
    }
  }

  Future<void> _navigateToForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeaveFormScreen()),
    );

    if (result == true) {
      _loadData(); // Refresh list after adding
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'Lembur, Ijin & Cuti',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _requests.isEmpty
            ? _buildEmptyState()
            : _buildHistoryList(),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Pengajuan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Buat pengajuan lembur, ijin, atau cuti\ndengan menekan tombol di bawah',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF0D47A1),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          return _buildHistoryCard(_requests[index]);
        },
      ),
    );
  }

  Widget _buildHistoryCard(PengajuanModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(request.type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.type.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _getTypeColor(request.type),
                    ),
                  ),
                ),
                const Spacer(),
                // Status Badge
                _buildStatusBadge(request.status),
              ],
            ),
            const SizedBox(height: 12),
            // Date Range
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDateRange(request),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (request.durationDays > 1) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${request.durationDays} hari',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            // Reason
            Text(
              request.reason,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 8),
            // Created Date
            Text(
              'Diajukan ${_formatCreatedDate(request.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RequestStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case RequestStatus.pending:
        backgroundColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFF57C00);
        icon = Icons.hourglass_empty;
        break;
      case RequestStatus.approved:
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        icon = Icons.check_circle;
        break;
      case RequestStatus.rejected:
        backgroundColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _navigateToForm,
      backgroundColor: const Color(0xFF0D47A1),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Ajukan Baru',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      elevation: 4,
    );
  }

  Color _getTypeColor(RequestType type) {
    switch (type) {
      case RequestType.lembur:
        return const Color(0xFF1976D2);
      case RequestType.ijin:
        return const Color(0xFFF57C00);
      case RequestType.cuti:
        return const Color(0xFF388E3C);
    }
  }

  String _formatDateRange(PengajuanModel request) {
    if (request.durationDays == 1) {
      return DateFormat('dd MMM yyyy').format(request.startDate);
    } else {
      return '${DateFormat('dd MMM').format(request.startDate)} - ${DateFormat('dd MMM yyyy').format(request.endDate)}';
    }
  }

  String _formatCreatedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} menit yang lalu';
      }
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }
}

// ==================== FORM SCREEN ====================

class LeaveFormScreen extends StatefulWidget {
  const LeaveFormScreen({Key? key}) : super(key: key);

  @override
  State<LeaveFormScreen> createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends State<LeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  RequestType _selectedType = RequestType.cuti;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // Toggle untuk mode selection
  bool _isRangeMode = false;

  bool _isLoading = false;
  static const String _storageKey = 'leave_requests';

  @override
  void initState() {
    super.initState();
    // Add listener to text controller for reactive validation
    _reasonController.addListener(() {
      setState(() {}); // Trigger rebuild when text changes
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ==================== STORAGE ====================

  Future<void> _saveData(PengajuanModel newRequest) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);

      List<PengajuanModel> requests = [];

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        requests = jsonList
            .map(
              (item) => PengajuanModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      requests.insert(0, newRequest);

      final List<Map<String, dynamic>> jsonList = requests
          .map((item) => item.toJson())
          .toList();
      final String newJsonString = json.encode(jsonList);
      await prefs.setString(_storageKey, newJsonString);

      print('Saved successfully: ${requests.length} total requests');
    } catch (e) {
      print('Error saving data: $e');
      rethrow;
    }
  }

  // ==================== VALIDATION & SUBMISSION ====================

  bool _isFormValid() {
    final hasDate = _isRangeMode
        ? (_rangeStart != null && _rangeEnd != null)
        : (_selectedDay != null);

    return hasDate && _reasonController.text.trim().length >= 10;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Mohon lengkapi form dengan benar');
      return;
    }

    if (_isRangeMode && (_rangeStart == null || _rangeEnd == null)) {
      _showErrorSnackBar('Pilih rentang tanggal');
      return;
    }

    if (!_isRangeMode && _selectedDay == null) {
      _showErrorSnackBar('Pilih tanggal untuk ${_selectedType.displayName}');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newRequest = PengajuanModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedType,
        startDate: _isRangeMode ? _rangeStart! : _selectedDay!,
        endDate: _isRangeMode ? _rangeEnd! : _selectedDay!,
        reason: _reasonController.text.trim(),
        createdAt: DateTime.now(),
        status: RequestStatus.pending,
      );

      await _saveData(newRequest);

      print('=== ${_selectedType.displayName.toUpperCase()} REQUEST ===');
      print('ID: ${newRequest.id}');
      print('Type: ${newRequest.type.displayName}');
      print('Mode: ${_isRangeMode ? "Range" : "Single"}');
      print('Start: ${DateFormat('dd MMM yyyy').format(newRequest.startDate)}');
      print('End: ${DateFormat('dd MMM yyyy').format(newRequest.endDate)}');
      print('Duration: ${newRequest.durationDays} hari');
      print('Reason: ${newRequest.reason}');
      print('Status: ${newRequest.status.displayName}');
      print('=====================');

      _showSuccessDialog();
    } catch (e) {
      _showErrorSnackBar('Gagal menyimpan data: $e');
      setState(() => _isLoading = false);
    }
  }

  // ==================== UI FEEDBACK ====================

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Berhasil Diajukan!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pengajuan ${_selectedType.displayName} Anda telah tersimpan dan menunggu persetujuan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Return to list with result
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UI BUILD ====================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'Buat Pengajuan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildTypeSelector(),
                      const SizedBox(height: 20),
                      _buildCalendarSection(),
                      const SizedBox(height: 20),
                      _buildReasonInput(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
        floatingActionButton: _buildSubmitButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // ==================== TYPE SELECTOR ====================

  Widget _buildTypeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_note,
                  color: Color(0xFF0D47A1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Pilih Jenis Pengajuan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: RequestType.values.map((type) {
              final isSelected = _selectedType == type;
              return ChoiceChip(
                label: Text(
                  type.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = type;
                    _selectedDay = null;
                    _rangeStart = null;
                    _rangeEnd = null;
                  });
                },
                selectedColor: const Color(0xFF0D47A1),
                backgroundColor: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF0D47A1)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== CALENDAR SECTION ====================

  Widget _buildCalendarSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF0D47A1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pilih Tanggal',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
              ),
              // Toggle Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildModeButton(
                      icon: Icons.event,
                      label: 'Tunggal',
                      isSelected: !_isRangeMode,
                      onTap: () {
                        setState(() {
                          _isRangeMode = false;
                          _rangeStart = null;
                          _rangeEnd = null;
                        });
                      },
                    ),
                    _buildModeButton(
                      icon: Icons.date_range,
                      label: 'Range',
                      isSelected: _isRangeMode,
                      onTap: () {
                        setState(() {
                          _isRangeMode = true;
                          _selectedDay = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendar(),
          if (_isRangeMode && _rangeStart != null && _rangeEnd != null)
            _buildDateRangeInfo(),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D47A1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      rangeSelectionMode: _isRangeMode
          ? RangeSelectionMode.toggledOn
          : RangeSelectionMode.disabled,
      selectedDayPredicate: (day) {
        if (_isRangeMode) {
          return false;
        }
        return isSameDay(_selectedDay, day);
      },
      rangeStartDay: _isRangeMode ? _rangeStart : null,
      rangeEndDay: _isRangeMode ? _rangeEnd : null,
      onDaySelected: !_isRangeMode
          ? (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          : null,
      onRangeSelected: _isRangeMode
          ? (start, end, focusedDay) {
              setState(() {
                _rangeStart = start;
                _rangeEnd = end;
                _focusedDay = focusedDay;
              });
            }
          : null,
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: const Color(0xFF0D47A1).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Color(0xFF0D47A1),
          shape: BoxShape.circle,
        ),
        rangeStartDecoration: const BoxDecoration(
          color: Color(0xFF0D47A1),
          shape: BoxShape.circle,
        ),
        rangeEndDecoration: const BoxDecoration(
          color: Color(0xFF0D47A1),
          shape: BoxShape.circle,
        ),
        rangeHighlightColor: const Color(0xFF0D47A1).withOpacity(0.15),
        outsideDaysVisible: false,
        weekendTextStyle: const TextStyle(color: Colors.red),
        defaultTextStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFF212121),
        ),
        leftChevronIcon: const Icon(
          Icons.chevron_left,
          color: Color(0xFF0D47A1),
        ),
        rightChevronIcon: const Icon(
          Icons.chevron_right,
          color: Color(0xFF0D47A1),
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
        weekendStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.red.shade400,
        ),
      ),
    );
  }

  Widget _buildDateRangeInfo() {
    final days = _rangeEnd!.difference(_rangeStart!).inDays + 1;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF0D47A1), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Durasi Cuti',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$days hari kerja',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('dd MMM yyyy').format(_rangeStart!)} - ${DateFormat('dd MMM yyyy').format(_rangeEnd!)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== REASON INPUT ====================

  Widget _buildReasonInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: Color(0xFF0D47A1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Alasan Pengajuan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _reasonController,
            maxLines: 4,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Jelaskan alasan pengajuan Anda...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF0D47A1),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              counterStyle: TextStyle(color: Colors.grey.shade600),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Alasan tidak boleh kosong';
              }
              if (value.trim().length < 10) {
                return 'Alasan minimal 10 karakter';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ==================== SUBMIT BUTTON ====================

  Widget _buildSubmitButton() {
    final isValid = _isFormValid();

    return Container(
      width: MediaQuery.of(context).size.width - 32,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isValid
            ? [
                BoxShadow(
                  color: const Color(0xFF0D47A1).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isValid ? _submitForm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E88E5),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_rounded,
              color: isValid ? Colors.white : Colors.grey.shade500,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              'Ajukan Sekarang',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isValid ? Colors.white : Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
