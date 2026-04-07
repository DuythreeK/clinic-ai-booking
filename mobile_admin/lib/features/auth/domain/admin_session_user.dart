class AdminSessionUser {
  const AdminSessionUser({
    required this.id,
    required this.fullName,
    required this.role,
    required this.email,
    required this.phone,
  });

  final String id;
  final String fullName;
  final String role;
  final String? email;
  final String? phone;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'AD';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String get roleLabel {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'receptionist':
        return 'Lễ tân';
      case 'doctor':
        return 'Bác sĩ';
      default:
        return role;
    }
  }

  factory AdminSessionUser.fromJson(Map<String, dynamic> json) {
    return AdminSessionUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Admin',
      role: json['role']?.toString() ?? 'admin',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
    );
  }
}
