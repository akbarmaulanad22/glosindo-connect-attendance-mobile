/// Model for Progress Ticket
class ProgressTicket {
  final String id;
  final String title;
  final String description;
  final String technicianName;
  final String status; // "Open", "On Progress", "Closed"
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProgressTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.technicianName,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProgressTicket.fromJson(Map<String, dynamic> json) {
    return ProgressTicket(
      id: json['id'].toString(),
      title: json['title'] ?? 'Untitled Ticket',
      description: json['description'] ?? '',
      technicianName: json['technician_name'] ?? 'Unknown',
      status: json['status'] ?? 'Open',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'technician_name': technicianName,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Copy with method for status updates
  ProgressTicket copyWith({
    String? id,
    String? title,
    String? description,
    String? technicianName,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgressTicket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      technicianName: technicianName ?? this.technicianName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ProgressTicket(id: $id, title: $title, status: $status)';
  }
}

/// Ticket status constants
class TicketStatus {
  static const String open = 'Open';
  static const String onProgress = 'On Progress';
  static const String closed = 'Closed';

  static List<String> get all => [open, onProgress, closed];
}
