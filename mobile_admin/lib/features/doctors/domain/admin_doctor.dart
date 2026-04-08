class AdminDoctor {
  const AdminDoctor({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.specialtyId,
    required this.specialtyName,
    required this.title,
    required this.licenseNumber,
    required this.bio,
    required this.yearsExperience,
    required this.consultationFee,
    required this.isActive,
  });

  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String? email;
  final String specialtyId;
  final String specialtyName;
  final String title;
  final String licenseNumber;
  final String? bio;
  final double yearsExperience;
  final double consultationFee;
  final bool isActive;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'BS';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    final first = parts[0].substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }

  factory AdminDoctor.fromJson(Map<String, dynamic> json) {
    final user = _asMap(json['user']);
    final specialty = _asMap(json['specialty']);

    return AdminDoctor(
      id: (json['doctor_id'] ?? json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? user['user_id'] ?? '').toString(),
      fullName: json['full_name']?.toString() ?? user['full_name']?.toString() ?? user['fullName']?.toString() ?? 'Chưa rõ bác sĩ',
      phone: user['phone']?.toString() ?? '',
      email: user['email']?.toString(),
      specialtyId:
          (json['specialty_id'] ?? json['specialtyId'] ?? specialty['specialty_id'] ?? specialty['id'] ?? '').toString(),
      specialtyName: specialty['name']?.toString() ?? 'Chưa rõ chuyên khoa',
      title: json['title']?.toString() ?? 'BS',
      licenseNumber: json['license_number']?.toString() ?? json['licenseNumber']?.toString() ?? '',
      bio: json['bio']?.toString(),
      yearsExperience: _toDouble(json['experience_years'] ?? json['yearsExperience']),
      consultationFee: _toDouble(json['consultation_fee'] ?? json['consultationFee']),
      isActive: json['is_active'] == 1 || json['isActive'] == true || user['status'] == 'active',
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }

    return const <String, dynamic>{};
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}

class AdminDoctorsPage {
  const AdminDoctorsPage({required this.items, required this.total});

  final List<AdminDoctor> items;
  final int total;
}
