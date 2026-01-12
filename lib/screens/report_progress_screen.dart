import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/progress_ticket_viewmodel.dart';
import 'package:glosindo_connect/models/progress_ticket.dart';

class ReportProgressScreen extends StatefulWidget {
  const ReportProgressScreen({Key? key}) : super(key: key);

  @override
  State<ReportProgressScreen> createState() => _ReportProgressScreenState();
}

class _ReportProgressScreenState extends State<ReportProgressScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final viewModel = context.read<ProgressTicketViewModel>();
    await viewModel.fetchTickets();
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
          title: const Text('Report Progress Tiket'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Consumer<ProgressTicketViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading && viewModel.tickets.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null && viewModel.tickets.isEmpty) {
              return _buildErrorState(viewModel.errorMessage!);
            }

            return RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Chart Section
                  SliverToBoxAdapter(child: _buildChartSection(viewModel)),

                  // Summary Section
                  SliverToBoxAdapter(child: _buildSummarySection(viewModel)),

                  // List Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'Daftar Tiket',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Ticket List
                  viewModel.tickets.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final ticket = viewModel.tickets[index];
                              return _buildTicketCard(ticket, viewModel);
                            }, childCount: viewModel.tickets.length),
                          ),
                        ),

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== CHART SECTION ====================

  Widget _buildChartSection(ProgressTicketViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Status Distribusi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: viewModel.totalCount == 0
                ? const Center(child: Text('Tidak ada data'))
                : PieChart(
                    PieChartData(
                      sections: _buildPieChartSections(viewModel),
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      startDegreeOffset: -90,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          _buildChartLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    ProgressTicketViewModel viewModel,
  ) {
    final sections = <PieChartSectionData>[];

    if (viewModel.openCount > 0) {
      sections.add(
        PieChartSectionData(
          value: viewModel.openCount.toDouble(),
          title: '${viewModel.openCount}',
          color: Colors.red,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (viewModel.onProgressCount > 0) {
      sections.add(
        PieChartSectionData(
          value: viewModel.onProgressCount.toDouble(),
          title: '${viewModel.onProgressCount}',
          color: Colors.orange,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (viewModel.closedCount > 0) {
      sections.add(
        PieChartSectionData(
          value: viewModel.closedCount.toDouble(),
          title: '${viewModel.closedCount}',
          color: Colors.green,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Open', Colors.red),
        _buildLegendItem('On Progress', Colors.orange),
        _buildLegendItem('Closed', Colors.green),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ==================== SUMMARY SECTION ====================

  Widget _buildSummarySection(ProgressTicketViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E88E5).withOpacity(0.1),
            const Color(0xFF1976D2).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total', viewModel.totalCount, Icons.analytics),
          _buildSummaryItem('Open', viewModel.openCount, Icons.error_outline),
          _buildSummaryItem(
            'Progress',
            viewModel.onProgressCount,
            Icons.hourglass_empty,
          ),
          _buildSummaryItem(
            'Closed',
            viewModel.closedCount,
            Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1E88E5), size: 28),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E88E5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ==================== TICKET CARD ====================

  Widget _buildTicketCard(
    ProgressTicket ticket,
    ProgressTicketViewModel viewModel,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${ticket.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (newStatus) async {
                    await _handleStatusUpdate(ticket, newStatus, viewModel);
                  },
                  itemBuilder: (context) => TicketStatus.all
                      .where((status) => status != ticket.status)
                      .map((status) {
                        return PopupMenuItem<String>(
                          value: status,
                          child: Text('Set to $status'),
                        );
                      })
                      .toList(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            if (ticket.description.isNotEmpty)
              Text(
                ticket.description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 12),

            // Technician & Status Row
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  ticket.technicianName,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const Spacer(),
                _buildStatusChip(ticket.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case TicketStatus.open:
        color = Colors.red;
        icon = Icons.error_outline;
        break;
      case TicketStatus.onProgress:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case TicketStatus.closed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STATUS UPDATE ====================

  Future<void> _handleStatusUpdate(
    ProgressTicket ticket,
    String newStatus,
    ProgressTicketViewModel viewModel,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Call API
    final success = await viewModel.updateTicketStatus(
      ticketId: ticket.id,
      newStatus: newStatus,
    );

    // Close loading
    if (mounted) {
      Navigator.pop(context);
    }

    // Show result
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Status updated to $newStatus'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    viewModel.errorMessage ?? 'Failed to update status',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ==================== EMPTY & ERROR STATES ====================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Tidak ada tiket',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
