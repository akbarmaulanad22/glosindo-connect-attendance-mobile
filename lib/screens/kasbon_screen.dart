import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glosindo_connect/models/kasbon_model.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parse and format
    final int value = int.parse(digitsOnly);
    final String formatted = _formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ==================== MAIN SCREEN ====================

class KasbonScreen extends StatefulWidget {
  const KasbonScreen({Key? key}) : super(key: key);

  @override
  State<KasbonScreen> createState() => _KasbonScreenState();
}

class _KasbonScreenState extends State<KasbonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nominalController = TextEditingController();
  final _reasonController = TextEditingController();

  List<KasbonModel> historyData = [];
  bool _isFormValid = false;
  bool _isLoading = true;

  static const String _storageKey = 'kasbon_history';

  @override
  void initState() {
    super.initState();
    _nominalController.addListener(_validateForm);
    _reasonController.addListener(_validateForm);
    _loadData();
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // ==================== LOCAL STORAGE ====================

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        setState(() {
          historyData = jsonList
              .map((item) => KasbonModel.fromJson(item as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList = historyData
          .map((item) => item.toJson())
          .toList();
      final String jsonString = json.encode(jsonList);
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  // ==================== VALIDATION ====================

  void _validateForm() {
    final nominal = _extractNominal(_nominalController.text);
    final reason = _reasonController.text.trim();
    final charCount = _countCharacters(reason);

    setState(() {
      // Form valid jika nominal >= 20000 DAN alasan minimal 10 karakter
      _isFormValid = nominal >= 20000 && charCount >= 10;
    });

    // Debug print
    print(
      'Validasi: Nominal=$nominal, Karakter=$charCount, Valid=$_isFormValid',
    );
  }

  double _extractNominal(String text) {
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly.isEmpty ? 0 : double.parse(digitsOnly);
  }

  int _countCharacters(String text) {
    if (text.isEmpty) return 0;
    // Hitung hanya huruf dan angka (tanpa spasi dan karakter khusus)
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').length;
  }

  // ==================== FORM SUBMISSION ====================

  Future<void> _submitForm() async {
    // Force validation check
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Mohon lengkapi form dengan benar');
      return;
    }

    final nominal = _extractNominal(_nominalController.text);
    final reason = _reasonController.text.trim();
    final charCount = _countCharacters(reason);

    // Additional validation
    if (nominal < 20000) {
      _showErrorSnackBar('Nominal minimal Rp 20.000');
      return;
    }

    if (charCount < 10) {
      _showErrorSnackBar(
        'Alasan harus minimal 10 karakter huruf/angka (saat ini: $charCount karakter)',
      );
      return;
    }

    // Generate new ID
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

    // Format date
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(now);

    // Create new kasbon request
    final newRequest = KasbonModel(
      id: newId,
      date: formattedDate,
      amount: nominal,
      reason: reason,
      status: 'Pending',
    );

    // Add to list (newest first)
    setState(() {
      historyData.insert(0, newRequest);
    });

    // Save to local storage
    await _saveData();

    // Print to console
    print('=== KASBON REQUEST ===');
    print('ID: $newId');
    print('Nominal: Rp ${NumberFormat('#,###', 'id_ID').format(nominal)}');
    print('Alasan: $reason');
    print('Jumlah Karakter: $charCount');
    print('Status: Pending');
    print('=====================');

    // Show success dialog
    _showSuccessDialog();
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Text('Berhasil!'),
          ],
        ),
        content: const Text(
          'Pengajuan kasbon Anda telah dikirim dan sedang menunggu persetujuan.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nominalController.clear();
              _reasonController.clear();
            },
            child: const Text('OK'),
          ),
        ],
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
            'Pengajuan Kasbon',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Form Section
                    _buildFormSection(),

                    const SizedBox(height: 24),

                    // History Section
                    _buildHistorySection(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  // ==================== FORM SECTION ====================

  Widget _buildFormSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title (Now Clickable)
            InkWell(
              onTap: () {
                // Optional: Add any action when title is clicked
                // For example, scroll to form or show info
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Silakan isi form di bawah ini'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFF0D47A1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Ajukan Kasbon Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nominal Input
            TextFormField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Nominal',
                hintText: 'Rp 0',
                prefixIcon: const Icon(Icons.money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
              ),
              validator: (value) {
                final nominal = _extractNominal(value ?? '');
                if (nominal == 0) {
                  return 'Nominal tidak boleh kosong';
                }
                if (nominal < 20000) {
                  return 'Minimal nominal Rp 20.000';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Reason Input
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: 'Alasan',
                hintText: 'Jelaskan alasan pengajuan kasbon...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 50),
                  child: Icon(Icons.description),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Alasan tidak boleh kosong';
                }
                final charCount = _countCharacters(value.trim());
                if (charCount < 10) {
                  return 'Alasan minimal 10 huruf/angka (saat ini: $charCount)';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isFormValid
                    ? () {
                        print('Button pressed! Valid: $_isFormValid');
                        _submitForm();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isFormValid ? 2 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.send,
                      color: _isFormValid ? Colors.white : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ajukan Kasbon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isFormValid
                            ? Colors.white
                            : Colors.grey.shade500,
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

  // ==================== HISTORY SECTION ====================

  Widget _buildHistorySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.history, color: Color(0xFF0D47A1), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Riwayat Pengajuan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),

          // History List
          if (historyData.isEmpty)
            _buildEmptyHistory()
          else
            ...historyData.map((request) => _buildHistoryCard(request)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(KasbonModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date Section
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    request.date.split(' ')[0],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  Text(
                    request.date.split(' ')[1],
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Content Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.reason,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF424242),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(request.amount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Status Badge
            _buildStatusBadge(request.status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'Pending':
        backgroundColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFF57C00);
        icon = Icons.hourglass_empty;
        break;
      case 'Approved':
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        icon = Icons.check_circle;
        break;
      case 'Rejected':
        backgroundColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
