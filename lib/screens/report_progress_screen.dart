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
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'Daftar Tiket',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // OPTIMIZED TICKET LIST
                  viewModel.tickets.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : OptimizedTicketList(
                          tickets: viewModel.tickets,
                          viewModel: viewModel,
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
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _LegendItem(label: 'Open', color: Colors.red),
        _LegendItem(label: 'On Progress', color: Colors.orange),
        _LegendItem(label: 'Closed', color: Colors.green),
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

// ==================== OPTIMIZED TICKET LIST ====================
// Uses SliverList.builder for efficient lazy loading
class OptimizedTicketList extends StatelessWidget {
  final List<ProgressTicket> tickets;
  final ProgressTicketViewModel viewModel;

  const OptimizedTicketList({
    Key? key,
    required this.tickets,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ticket = tickets[index];
            // RepaintBoundary prevents unnecessary repaints
            return RepaintBoundary(
              child: TicketCard(
                key: ValueKey(ticket.id),
                ticket: ticket,
                onStatusUpdate: (newStatus) =>
                    _handleStatusUpdate(context, ticket, newStatus),
              ),
            );
          },
          childCount: tickets.length,
          // Performance optimization: find items by key instead of rebuilding
          findChildIndexCallback: (Key key) {
            final valueKey = key as ValueKey<String>;
            final index = tickets.indexWhere((t) => t.id == valueKey.value);
            return index >= 0 ? index : null;
          },
        ),
      ),
    );
  }

  Future<void> _handleStatusUpdate(
    BuildContext context,
    ProgressTicket ticket,
    String newStatus,
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
    if (context.mounted) {
      Navigator.pop(context);
    }

    // Show result
    if (context.mounted) {
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
}

// ==================== OPTIMIZED TICKET CARD ====================
// Lightweight widget with minimal nesting and efficient rendering
class TicketCard extends StatelessWidget {
  final ProgressTicket ticket;
  final Function(String) onStatusUpdate;

  const TicketCard({
    Key? key,
    required this.ticket,
    required this.onStatusUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1, // Reduced elevation for better performance
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showStatusDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Minimize layout calculations
            children: [
              // Header with title and menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ticket.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${ticket.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusMenuButton(
                    currentStatus: ticket.status,
                    onSelected: onStatusUpdate,
                  ),
                ],
              ),

              // Description (if available)
              if (ticket.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  ticket.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Bottom row: Technician and Status
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ticket.technicianName,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: ticket.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _StatusUpdateSheet(
        currentStatus: ticket.status,
        ticketTitle: ticket.title,
        onStatusSelected: (newStatus) {
          Navigator.pop(context);
          onStatusUpdate(newStatus);
        },
      ),
    );
  }
}

// ==================== STATUS CHIP (Const-friendly) ====================
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 13, color: config.color),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case TicketStatus.open:
        return const _StatusConfig(
          color: Colors.red,
          icon: Icons.error_outline,
        );
      case TicketStatus.onProgress:
        return const _StatusConfig(
          color: Colors.orange,
          icon: Icons.hourglass_empty,
        );
      case TicketStatus.closed:
        return const _StatusConfig(
          color: Colors.green,
          icon: Icons.check_circle,
        );
      default:
        return const _StatusConfig(
          color: Colors.grey,
          icon: Icons.help_outline,
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;

  const _StatusConfig({required this.color, required this.icon});
}

// ==================== STATUS MENU BUTTON ====================
class _StatusMenuButton extends StatelessWidget {
  final String currentStatus;
  final Function(String) onSelected;

  const _StatusMenuButton({
    required this.currentStatus,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: onSelected,
      itemBuilder: (context) => TicketStatus.all
          .where((status) => status != currentStatus)
          .map((status) {
            return PopupMenuItem<String>(
              value: status,
              child: Row(
                children: [
                  Icon(_getStatusIcon(status), size: 18),
                  const SizedBox(width: 12),
                  Text('Set to $status'),
                ],
              ),
            );
          })
          .toList(),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case TicketStatus.open:
        return Icons.error_outline;
      case TicketStatus.onProgress:
        return Icons.hourglass_empty;
      case TicketStatus.closed:
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }
}

// ==================== STATUS UPDATE BOTTOM SHEET ====================
class _StatusUpdateSheet extends StatelessWidget {
  final String currentStatus;
  final String ticketTitle;
  final Function(String) onStatusSelected;

  const _StatusUpdateSheet({
    required this.currentStatus,
    required this.ticketTitle,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Status',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            ticketTitle,
            style: TextStyle(color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          ...TicketStatus.all.where((status) => status != currentStatus).map((
            status,
          ) {
            return _StatusOption(
              status: status,
              onTap: () => onStatusSelected(status),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String status;
  final VoidCallback onTap;

  const _StatusOption({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: config.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: config.color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(config.icon, color: config.color),
            const SizedBox(width: 16),
            Text(
              status,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: config.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusConfig _getConfig(String status) {
    switch (status) {
      case TicketStatus.open:
        return const _StatusConfig(
          color: Colors.red,
          icon: Icons.error_outline,
        );
      case TicketStatus.onProgress:
        return const _StatusConfig(
          color: Colors.orange,
          icon: Icons.hourglass_empty,
        );
      case TicketStatus.closed:
        return const _StatusConfig(
          color: Colors.green,
          icon: Icons.check_circle,
        );
      default:
        return const _StatusConfig(
          color: Colors.grey,
          icon: Icons.help_outline,
        );
    }
  }
}

// ==================== LEGEND ITEM (Const) ====================
class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
}
