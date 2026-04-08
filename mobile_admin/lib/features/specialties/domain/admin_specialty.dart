import '../../doctors/domain/admin_doctor.dart';

class AdminSpecialty {
  const AdminSpecialty({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.sortOrder,
    required this.isActive,
    this.doctors = const [],
  });

  final String id;
  final String name;
  final String code;
  final String? description;
  final int sortOrder;
  final bool isActive;
  final List<AdminDoctor> doctors;

  factory AdminSpecialty.fromJson(Map<String, dynamic> json) {
    final docsRaw = json['doctors'] as List?;
    final docs = docsRaw?.map((d) {
      final docMap = Map<String, dynamic>.from(d as Map);
      docMap['specialty'] = json;
      return AdminDoctor.fromJson(docMap);
    }).toList() ?? [];

    return AdminSpecialty(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
      sortOrder: _toInt(json['sortOrder']),
      isActive: json['isActive'] == 1 || json['isActive'] == true || json['is_active'] == 1 || json['is_active'] == true,
      doctors: docs,
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
