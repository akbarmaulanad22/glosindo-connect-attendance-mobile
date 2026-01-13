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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await context.read<ProgressTicketViewModel>().fetchTickets();
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
        body: Selector<ProgressTicketViewModel, bool>(
          selector: (_, vm) => vm.isLoading && vm.tickets.isEmpty,
          builder: (context, isInitialLoading, _) {
            if (isInitialLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Selector<ProgressTicketViewModel, String?>(
              selector: (_, vm) => vm.errorMessage,
              builder: (context, error, _) {
                if (error != null) {
                  final hasTickets = context
                      .read<ProgressTicketViewModel>()
                      .tickets
                      .isNotEmpty;
                  if (!hasTickets) {
                    return _buildErrorState(error);
                  }
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // Chart Section - Wrapped with RepaintBoundary
                      SliverToBoxAdapter(
                        child: RepaintBoundary(child: _ChartSection()),
                      ),

                      // Summary Section - Wrapped with RepaintBoundary
                      SliverToBoxAdapter(
                        child: RepaintBoundary(child: _SummarySection()),
                      ),

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

                      // Optimized Ticket List
                      Selector<ProgressTicketViewModel, List<ProgressTicket>>(
                        selector: (_, vm) => vm.tickets,
                        builder: (context, tickets, _) {
                          if (tickets.isEmpty) {
                            return SliverFillRemaining(
                              child: _buildEmptyState(),
                            );
                          }

                          return _OptimizedTicketList(tickets: tickets);
                        },
                      ),

                      // Bottom padding
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

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

// ==================== CHART SECTION (Isolated Widget) ====================
class _ChartSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Status Distribusi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Selector<ProgressTicketViewModel, int>(
              selector: (_, vm) => vm.totalCount,
              builder: (context, totalCount, _) {
                if (totalCount == 0) {
                  return const Center(child: Text('Tidak ada data'));
                }

                return Selector<ProgressTicketViewModel, _ChartData>(
                  selector: (_, vm) => _ChartData(
                    openCount: vm.openCount,
                    onProgressCount: vm.onProgressCount,
                    closedCount: vm.closedCount,
                  ),
                  builder: (context, chartData, _) {
                    return PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(chartData),
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        startDegreeOffset: -90,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const _ChartLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(_ChartData data) {
    final sections = <PieChartSectionData>[];

    if (data.openCount > 0) {
      sections.add(
        PieChartSectionData(
          value: data.openCount.toDouble(),
          title: '${data.openCount}',
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

    if (data.onProgressCount > 0) {
      sections.add(
        PieChartSectionData(
          value: data.onProgressCount.toDouble(),
          title: '${data.onProgressCount}',
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

    if (data.closedCount > 0) {
      sections.add(
        PieChartSectionData(
          value: data.closedCount.toDouble(),
          title: '${data.closedCount}',
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
}

class _ChartData {
  final int openCount;
  final int onProgressCount;
  final int closedCount;

  _ChartData({
    required this.openCount,
    required this.onProgressCount,
    required this.closedCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ChartData &&
          openCount == other.openCount &&
          onProgressCount == other.onProgressCount &&
          closedCount == other.closedCount;

  @override
  int get hashCode => Object.hash(openCount, onProgressCount, closedCount);
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _LegendItem(label: 'Open', color: Colors.red),
        _LegendItem(label: 'On Progress', color: Colors.orange),
        _LegendItem(label: 'Closed', color: Colors.green),
      ],
    );
  }
}

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

// ==================== SUMMARY SECTION (Isolated Widget) ====================
class _SummarySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
      child: Selector<ProgressTicketViewModel, _SummaryData>(
        selector: (_, vm) => _SummaryData(
          totalCount: vm.totalCount,
          openCount: vm.openCount,
          onProgressCount: vm.onProgressCount,
          closedCount: vm.closedCount,
        ),
        builder: (context, data, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem(
                label: 'Total',
                count: data.totalCount,
                icon: Icons.analytics,
              ),
              _SummaryItem(
                label: 'Open',
                count: data.openCount,
                icon: Icons.error_outline,
              ),
              _SummaryItem(
                label: 'Progress',
                count: data.onProgressCount,
                icon: Icons.hourglass_empty,
              ),
              _SummaryItem(
                label: 'Closed',
                count: data.closedCount,
                icon: Icons.check_circle_outline,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryData {
  final int totalCount;
  final int openCount;
  final int onProgressCount;
  final int closedCount;

  _SummaryData({
    required this.totalCount,
    required this.openCount,
    required this.onProgressCount,
    required this.closedCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SummaryData &&
          totalCount == other.totalCount &&
          openCount == other.openCount &&
          onProgressCount == other.onProgressCount &&
          closedCount == other.closedCount;

  @override
  int get hashCode =>
      Object.hash(totalCount, openCount, onProgressCount, closedCount);
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
}

// ==================== OPTIMIZED TICKET LIST ====================
class _OptimizedTicketList extends StatelessWidget {
  final List<ProgressTicket> tickets;

  const _OptimizedTicketList({required this.tickets});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ticket = tickets[index];
            return RepaintBoundary(
              child: _TicketCard(key: ValueKey(ticket.id), ticket: ticket),
            );
          },
          childCount: tickets.length,
          findChildIndexCallback: (Key key) {
            final valueKey = key as ValueKey<String>;
            final index = tickets.indexWhere((t) => t.id == valueKey.value);
            return index >= 0 ? index : null;
          },
        ),
      ),
    );
  }
}

// ==================== TICKET CARD (Optimized) ====================
class _TicketCard extends StatelessWidget {
  final ProgressTicket ticket;

  const _TicketCard({Key? key, required this.ticket}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showStatusDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    ticketId: ticket.id,
                  ),
                ],
              ),
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
                  _StatusChip(status: ticket.status),
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
        ticketId: ticket.id,
      ),
    );
  }
}

// ==================== STATUS CHIP ====================
class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

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
  final String ticketId;

  const _StatusMenuButton({
    required this.currentStatus,
    required this.ticketId,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (newStatus) => _handleStatusUpdate(context, newStatus),
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

  Future<void> _handleStatusUpdate(
    BuildContext context,
    String newStatus,
  ) async {
    final viewModel = context.read<ProgressTicketViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await viewModel.updateTicketStatus(
      ticketId: ticketId,
      newStatus: newStatus,
    );

    if (context.mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success
                      ? 'Status updated to $newStatus'
                      : viewModel.errorMessage ?? 'Failed to update status',
                ),
              ),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: Duration(seconds: success ? 2 : 3),
        ),
      );
    }
  }
}

// ==================== STATUS UPDATE BOTTOM SHEET ====================
class _StatusUpdateSheet extends StatelessWidget {
  final String currentStatus;
  final String ticketTitle;
  final String ticketId;

  const _StatusUpdateSheet({
    required this.currentStatus,
    required this.ticketTitle,
    required this.ticketId,
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
              onTap: () {
                Navigator.pop(context);
                _handleStatusUpdate(context, status);
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _handleStatusUpdate(
    BuildContext context,
    String newStatus,
  ) async {
    final viewModel = context.read<ProgressTicketViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await viewModel.updateTicketStatus(
      ticketId: ticketId,
      newStatus: newStatus,
    );

    if (context.mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success
                      ? 'Status updated to $newStatus'
                      : viewModel.errorMessage ?? 'Failed to update status',
                ),
              ),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: Duration(seconds: success ? 2 : 3),
        ),
      );
    }
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
