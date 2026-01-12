import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glosindo_connect/models/ticket_model.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({Key? key}) : super(key: key);

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  // Dummy data
  final List<Ticket> allTickets = [
    Ticket(
      id: '1',
      title: 'Wifi Lantai 3 Mati',
      description:
          'Koneksi terputus total sejak jam 8 pagi, user tidak bisa connect.',
      category: 'Jaringan',
      date: '12 Jan 2026',
      customerName: 'PT Berkah Jaya',
      customerAddress: 'Jl. Sudirman No. 45, Jakarta Pusat',
    ),
    Ticket(
      id: '2',
      title: 'Printer HRD Macet',
      description: 'Kertas nyangkut di printer Epson L3110 ruangan HRD.',
      category: 'Hardware',
      date: '11 Jan 2026',
      customerName: 'CV Maju Bersama',
      customerAddress: 'Jl. Gatot Subroto No. 12, Bandung',
    ),
    Ticket(
      id: '3',
      title: 'Install VS Code',
      description: 'Permintaan install tools development untuk staff baru IT.',
      category: 'Software',
      date: '11 Jan 2026',
      customerName: 'PT Digital Nusantara',
      customerAddress: 'Jl. TB Simatupang Kav. 88, Jakarta Selatan',
    ),
    Ticket(
      id: '4',
      title: 'AC Server Bocor',
      description: 'Ada tetesan air dari AC tepat diatas rack server utama.',
      category: 'Lainnya',
      date: '10 Jan 2026',
      customerName: 'PT Sejahtera Abadi',
      customerAddress: 'Jl. Ahmad Yani No. 67, Surabaya',
    ),
    Ticket(
      id: '5',
      title: 'LAN Tidak Connect',
      description: 'PC Admin 2 tidak mendapatkan IP Address dari DHCP.',
      category: 'Jaringan',
      date: '10 Jan 2026',
      customerName: 'Toko Elektronik Jaya',
      customerAddress: 'Jl. Diponegoro No. 23, Semarang',
    ),
    Ticket(
      id: '6',
      title: 'Monitor Berkedip',
      description: 'Layar monitor divisi finance berkedip-kedip ungu.',
      category: 'Hardware',
      date: '09 Jan 2026',
      customerName: 'PT Sukses Mandiri',
      customerAddress: 'Jl. Asia Afrika No. 10, Bandung',
    ),
  ];

  // Filter categories
  final List<String> categories = [
    'Semua',
    'Jaringan',
    'Hardware',
    'Software',
    'Lainnya',
  ];

  // State variables
  String selectedCategory = 'Semua';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  // Filtered tickets based on search and category
  List<Ticket> get filteredTickets {
    return allTickets.where((ticket) {
      // Search matches either title OR customer name
      final matchesSearch =
          ticket.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          ticket.customerName.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesCategory =
          selectedCategory == 'Semua' || ticket.category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Informasi Tiket',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search Bar Section
            _buildSearchBar(),

            // Filter Chips Section
            _buildFilterChips(),

            // Ticket List
            Expanded(
              child: filteredTickets.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTickets.length,
                      itemBuilder: (context, index) {
                        return _buildTicketCard(filteredTickets[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SEARCH BAR ====================

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari tiket...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ==================== FILTER CHIPS ====================

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category;
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: const Color(0xFF1E88E5),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: isSelected ? 2 : 0,
              pressElevation: 4,
            ),
          );
        },
      ),
    );
  }

  // ==================== TICKET CARD ====================

  Widget _buildTicketCard(Ticket ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showTicketDetails(ticket);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Date Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        ticket.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ticket.date,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Customer Name
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ticket.customerName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  ticket.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Address and Category Badge Row
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ticket.customerAddress,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildCategoryBadge(ticket.category),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== CATEGORY BADGE ====================

  Widget _buildCategoryBadge(String category) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (category) {
      case 'Jaringan':
        backgroundColor = const Color(0xFF2196F3);
        textColor = Colors.white;
        icon = Icons.wifi;
        break;
      case 'Hardware':
        backgroundColor = const Color(0xFFFF9800);
        textColor = Colors.white;
        icon = Icons.computer;
        break;
      case 'Software':
        backgroundColor = const Color(0xFF4CAF50);
        textColor = Colors.white;
        icon = Icons.apps;
        break;
      case 'Lainnya':
        backgroundColor = const Color(0xFF9C27B0);
        textColor = Colors.white;
        icon = Icons.more_horiz;
        break;
      default:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            category,
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

  // ==================== EMPTY STATE ====================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada tiket ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah kata kunci atau filter',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ==================== TICKET DETAILS DIALOG ====================

  void _showTicketDetails(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Detail Tiket',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ID
              _buildDetailRow('ID', ticket.id),
              const SizedBox(height: 12),

              // Title
              _buildDetailRow('Judul', ticket.title),
              const SizedBox(height: 12),

              // Customer Name
              _buildDetailRow('Nama Pelanggan', ticket.customerName),
              const SizedBox(height: 12),

              // Customer Address
              _buildDetailRow('Alamat', ticket.customerAddress),
              const SizedBox(height: 12),

              // Description
              _buildDetailRow('Deskripsi', ticket.description),
              const SizedBox(height: 12),

              // Date
              _buildDetailRow('Tanggal', ticket.date),
              const SizedBox(height: 12),

              // Category
              const Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              _buildCategoryBadge(ticket.category),
              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 15, color: Color(0xFF212121)),
        ),
      ],
    );
  }
}
