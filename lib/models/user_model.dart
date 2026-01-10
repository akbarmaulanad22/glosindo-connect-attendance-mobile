class UserModel {
  final String id;
  final String nik;
  final String name;
  final String email;
  final String? phone;
  final String? photo;
  final String jabatan;
  final String divisi;

  UserModel({
    required this.id,
    required this.nik,
    required this.name,
    required this.email,
    this.phone,
    this.photo,
    required this.jabatan,
    required this.divisi,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      nik: json['nik'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      photo: json['photo'],
      jabatan: json['position'] ?? '',
      divisi: json['division'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nik': nik,
      'name': name,
      'email': email,
      'phone': phone,
      'photo': photo,
      'jabatan': jabatan,
      'divisi': divisi,
    };
  }
}
