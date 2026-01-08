class PengajuanModel {
  final String id;
  final String userId;
  final String type; // 'lembur', 'izin', 'cuti'
  final DateTime startDate;
  final DateTime? endDate;
  final String reason;
  final String status;
  final DateTime requestDate;
  final String? approvedBy;
  final String? notes;

  PengajuanModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.startDate,
    this.endDate,
    required this.reason,
    required this.status,
    required this.requestDate,
    this.approvedBy,
    this.notes,
  });

  factory PengajuanModel.fromJson(Map<String, dynamic> json) {
    return PengajuanModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      type: json['type'] ?? 'izin',
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
      requestDate: DateTime.parse(json['request_date']),
      approvedBy: json['approved_by'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'reason': reason,
    };
  }
}
