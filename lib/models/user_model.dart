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
      'position': jabatan,
      'division': divisi,
    };
  }

  // Create a copy with modified fields
  UserModel copyWith({
    String? id,
    String? nik,
    String? name,
    String? email,
    String? phone,
    String? photo,
    String? jabatan,
    String? divisi,
  }) {
    return UserModel(
      id: id ?? this.id,
      nik: nik ?? this.nik,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photo: photo ?? this.photo,
      jabatan: jabatan ?? this.jabatan,
      divisi: divisi ?? this.divisi,
    );
  }
}
