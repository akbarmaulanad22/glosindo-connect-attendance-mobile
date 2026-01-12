import 'package:flutter/foundation.dart';
import 'package:glosindo_connect/models/progress_ticket.dart';
import 'package:glosindo_connect/services/progress_ticket_service.dart';

class ProgressTicketViewModel extends ChangeNotifier {
  final ProgressTicketService _service = ProgressTicketService();

  // ==================== STATE ====================

  List<ProgressTicket> _tickets = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Status counts for chart
  int _openCount = 0;
  int _onProgressCount = 0;
  int _closedCount = 0;

  // ==================== GETTERS ====================

  List<ProgressTicket> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get openCount => _openCount;
  int get onProgressCount => _onProgressCount;
  int get closedCount => _closedCount;
  int get totalCount => _tickets.length;

  // ==================== FETCH TICKETS ====================

  Future<void> fetchTickets() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('📊 Fetching progress tickets...');

      final response = await _service.getAllTickets();

      if (response['success'] == true) {
        final List<dynamic> dataList = response['data'] as List;

        _tickets = dataList
            .map((json) => ProgressTicket.fromJson(json))
            .toList();

        // Calculate status counts
        _calculateStatusCounts();

        debugPrint('✅ Loaded ${_tickets.length} tickets');
        debugPrint(
          '📊 Stats: Open=$_openCount, Progress=$_onProgressCount, Closed=$_closedCount',
        );
      } else {
        _errorMessage = response['error'] ?? 'Failed to fetch tickets';
        debugPrint('❌ Error: $_errorMessage');
        _tickets = [];
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      debugPrint('❌ Exception: $_errorMessage');
      _tickets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== UPDATE TICKET STATUS ====================

  Future<bool> updateTicketStatus({
    required String ticketId,
    required String newStatus,
  }) async {
    try {
      debugPrint('🔄 Updating ticket $ticketId to $newStatus...');

      // Find ticket index
      final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
      if (ticketIndex == -1) {
        _errorMessage = 'Ticket not found';
        notifyListeners();
        return false;
      }

      // Store old status for rollback
      final oldStatus = _tickets[ticketIndex].status;

      // Optimistic update (update UI immediately)
      _tickets[ticketIndex] = _tickets[ticketIndex].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      _calculateStatusCounts();
      notifyListeners();

      // Call API
      final response = await _service.updateTicketStatus(
        ticketId: ticketId,
        newStatus: newStatus,
      );

      if (response['success'] == true) {
        debugPrint('✅ Status updated successfully');
        return true;
      } else {
        // Rollback on error
        _errorMessage = response['error'] ?? 'Failed to update status';
        debugPrint('❌ Error: $_errorMessage');

        _tickets[ticketIndex] = _tickets[ticketIndex].copyWith(
          status: oldStatus,
        );
        _calculateStatusCounts();
        notifyListeners();

        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      debugPrint('❌ Exception: $_errorMessage');

      // Rollback on exception
      await fetchTickets(); // Refresh to get correct state

      return false;
    }
  }

  // ==================== HELPER METHODS ====================

  void _calculateStatusCounts() {
    _openCount = _tickets.where((t) => t.status == TicketStatus.open).length;
    _onProgressCount = _tickets
        .where((t) => t.status == TicketStatus.onProgress)
        .length;
    _closedCount = _tickets
        .where((t) => t.status == TicketStatus.closed)
        .length;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearAllData() {
    _tickets = [];
    _openCount = 0;
    _onProgressCount = 0;
    _closedCount = 0;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
