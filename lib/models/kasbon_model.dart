class KasbonModel {
  final String id;
  final String userId;
  final double amount;
  final String reason;
  final String status;
  final DateTime requestDate;
  final DateTime? approvedDate;
  final String? approvedBy;
  final String? notes;

  KasbonModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.reason,
    required this.status,
    required this.requestDate,
    this.approvedDate,
    this.approvedBy,
    this.notes,
  });

  factory KasbonModel.fromJson(Map<String, dynamic> json) {
    return KasbonModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      amount: (json['amount'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
      requestDate: DateTime.parse(json['request_date']),
      approvedDate: json['approved_date'] != null
          ? DateTime.parse(json['approved_date'])
          : null,
      approvedBy: json['approved_by'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'reason': reason};
  }
}
