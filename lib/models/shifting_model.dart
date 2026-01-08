class ShiftingModel {
  final String id;
  final String userId;
  final DateTime date;
  final String shiftType; // 'pagi', 'siang', 'malam'
  final String startTime;
  final String endTime;
  final String location;

  ShiftingModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.shiftType,
    required this.startTime,
    required this.endTime,
    required this.location,
  });

  factory ShiftingModel.fromJson(Map<String, dynamic> json) {
    return ShiftingModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      date: DateTime.parse(json['date']),
      shiftType: json['shift_type'] ?? 'pagi',
      startTime: json['start_time'] ?? '08:00',
      endTime: json['end_time'] ?? '17:00',
      location: json['location'] ?? 'Kantor Pusat',
    );
  }
}
