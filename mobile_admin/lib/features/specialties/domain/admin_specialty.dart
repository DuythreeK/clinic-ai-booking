class AdminSpecialty {
  const AdminSpecialty({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String name;
  final String code;
  final String? description;
  final int sortOrder;
  final bool isActive;

  factory AdminSpecialty.fromJson(Map<String, dynamic> json) {
    return AdminSpecialty(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
      sortOrder: _toInt(json['sortOrder']),
      isActive: json['isActive'] == true,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }
}
