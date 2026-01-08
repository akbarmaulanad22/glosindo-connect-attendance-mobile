class PresensiModel {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? checkInLat;
  final double? checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final String status;

  PresensiModel({
    required this.id,
    required this.userId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    required this.status,
  });

  factory PresensiModel.fromJson(Map<String, dynamic> json) {
    return PresensiModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      date: DateTime.parse(json['date']),
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'])
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'])
          : null,
      checkInLat: json['check_in_lat']?.toDouble(),
      checkInLng: json['check_in_lng']?.toDouble(),
      checkOutLat: json['check_out_lat']?.toDouble(),
      checkOutLng: json['check_out_lng']?.toDouble(),
      status: json['status'] ?? 'pending',
    );
  }
}
