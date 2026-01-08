class TiketModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? assignedTo;

  TiketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
    this.assignedTo,
  });

  factory TiketModel.fromJson(Map<String, dynamic> json) {
    return TiketModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      status: json['status'] ?? 'Open',
      priority: json['priority'] ?? 'Medium',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      assignedTo: json['assigned_to'],
    );
  }
}
