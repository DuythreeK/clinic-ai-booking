class AdminRoom {
  const AdminRoom({
    required this.id,
    required this.name,
    required this.code,
    required this.floor,
    required this.isActive,
    this.specialtyId,
    this.specialtyName,
    this.description,
  });

  final String id;
  final String name;
  final String code;
  final int floor;
  final bool isActive;
  final String? specialtyId;
  final String? specialtyName;
  final String? description;

  factory AdminRoom.fromJson(Map<String, dynamic> json) {
    final specialty = json['specialty'] as Map<String, dynamic>?;
    return AdminRoom(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      floor: _toInt(json['floor']),
      isActive: json['isActive'] == true,
      specialtyId: json['specialtyId']?.toString(),
      specialtyName: specialty?['name']?.toString(),
      description: json['description']?.toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 1;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 1;
  }
}
