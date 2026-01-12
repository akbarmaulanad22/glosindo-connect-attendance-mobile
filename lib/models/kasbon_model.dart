class KasbonModel {
  final String id;
  final String date;
  final double amount;
  final String reason;
  final String status;

  KasbonModel({
    required this.id,
    required this.date,
    required this.amount,
    required this.reason,
    required this.status,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'amount': amount,
      'reason': reason,
      'status': status,
    };
  }

  // Create from JSON
  factory KasbonModel.fromJson(Map<String, dynamic> json) {
    return KasbonModel(
      id: json['id'] as String,
      date: json['date'] as String,
      amount: (json['amount'] as num).toDouble(),
      reason: json['reason'] as String,
      status: json['status'] as String,
    );
  }
}
