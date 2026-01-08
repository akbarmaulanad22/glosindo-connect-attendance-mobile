import 'package:flutter/material.dart';
import 'package:glosindo_connect/viewmodels/pengajuan_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PengajuanScreen extends StatefulWidget {
  const PengajuanScreen({super.key});

  @override
  State<PengajuanScreen> createState() => _PengajuanScreenState();
}

class _PengajuanScreenState extends State<PengajuanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lembur, Izin & Cuti'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Lembur'),
            Tab(text: 'Izin'),
            Tab(text: 'Cuti'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PengajuanListView(type: 'lembur'),
          _PengajuanListView(type: 'izin'),
          _PengajuanListView(type: 'cuti'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormPengajuan(),
        icon: const Icon(Icons.add),
        label: const Text('Ajukan'),
      ),
    );
  }

  void _showFormPengajuan() {
    final formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController();
    DateTimeRange? dateRange;
    final viewModel = context.read<PengajuanViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Form Pengajuan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Date Range Picker Card
                  InkWell(
                    onTap: () async {
                      final DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: dateRange,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Colors.blue.shade700,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                        helpText: viewModel.selectedType == 'cuti'
                            ? 'Pilih Rentang Tanggal Cuti'
                            : 'Pilih Tanggal',
                        cancelText: 'Batal',
                        confirmText: 'OK',
                        saveText: 'Simpan',
                        fieldStartHintText: 'Tanggal Mulai',
                        fieldEndHintText: 'Tanggal Akhir',
                        fieldStartLabelText: 'Dari',
                        fieldEndLabelText: 'Sampai',
                      );

                      if (picked != null) {
                        setModalState(() => dateRange = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  viewModel.selectedType == 'cuti'
                                      ? 'Rentang Tanggal'
                                      : 'Tanggal',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateRange != null
                                      ? dateRange!.start == dateRange!.end
                                            ? DateFormat(
                                                'dd MMMM yyyy',
                                              ).format(dateRange!.start)
                                            : '${DateFormat('dd MMM yyyy').format(dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(dateRange!.end)}'
                                      : 'Pilih tanggal',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: dateRange != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: dateRange != null
                                        ? Colors.black
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Info durasi untuk cuti
                  if (viewModel.selectedType == 'cuti' &&
                      dateRange != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Durasi: ${dateRange!.duration.inDays + 1} hari',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Alasan',
                      hintText: 'Masukkan alasan',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Alasan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (dateRange == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pilih tanggal terlebih dahulu'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (formKey.currentState!.validate()) {
                        final success = await viewModel.submitPengajuan(
                          type: viewModel.selectedType,
                          startDate: dateRange!.start,
                          endDate: viewModel.selectedType == 'cuti'
                              ? dateRange!.end
                              : null,
                          reason: reasonController.text,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pengajuan berhasil dikirim'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  viewModel.errorMessage ?? 'Pengajuan gagal',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kirim Pengajuan',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PengajuanListView extends StatefulWidget {
  final String type;
  const _PengajuanListView({required this.type});

  @override
  State<_PengajuanListView> createState() => _PengajuanListViewState();
}

class _PengajuanListViewState extends State<_PengajuanListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<PengajuanViewModel>();
      viewModel.setSelectedType(widget.type);
      viewModel.fetchPengajuanList(widget.type);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PengajuanViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.pengajuanList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada pengajuan ${widget.type}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: viewModel.pengajuanList.length,
          itemBuilder: (context, index) {
            final pengajuan = viewModel.pengajuanList[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(
                    pengajuan.status,
                  ).withOpacity(0.2),
                  child: Icon(
                    _getTypeIcon(pengajuan.type),
                    color: _getStatusColor(pengajuan.status),
                  ),
                ),
                title: Text(
                  pengajuan.endDate != null
                      ? '${DateFormat('dd MMM').format(pengajuan.startDate)} - ${DateFormat('dd MMM yyyy').format(pengajuan.endDate!)}'
                      : DateFormat('dd MMMM yyyy').format(pengajuan.startDate),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(pengajuan.reason),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(pengajuan.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pengajuan.status,
                    style: TextStyle(
                      color: _getStatusColor(pengajuan.status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'lembur':
        return Icons.access_time;
      case 'izin':
        return Icons.event_note;
      case 'cuti':
        return Icons.beach_access;
      default:
        return Icons.note;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
