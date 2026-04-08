class AdminSchedule {
  const AdminSchedule({
    required this.id,
    required this.doctorId,
    this.roomId,
    required this.workDate,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMin,
    required this.maxSlots,
    required this.bookedSlots,
    required this.isAvailable,
    this.doctorName,
    this.doctorTitle,
    this.roomName,
  });

  final String id;
  final String doctorId;
  final String? roomId;
  final DateTime workDate;
  final DateTime startTime;
  final DateTime endTime;
  final int slotDurationMin;
  final int maxSlots;
  final int bookedSlots;
  final bool isAvailable;

  // Extra fields from relations
  final String? doctorName;
  final String? doctorTitle;
  final String? roomName;

  factory AdminSchedule.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'] as Map<String, dynamic>?;
    final room = json['room'] as Map<String, dynamic>?;

    return AdminSchedule(
      id: (json['scheduleId'] ?? json['id'] ?? '').toString(),
      doctorId: (json['doctor_id'] ?? json['doctorId'] ?? '').toString(),
      roomId: (json['room_id'] ?? json['roomId'])?.toString(),
      workDate: _parseDate(json['workDate']),
      startTime: _parseDate(json['startTime']),
      endTime: _parseDate(json['endTime']),
      slotDurationMin: _toInt(json['slotDuration'] ?? json['slotDurationMin'], fallback: 30),
      maxSlots: _toInt(json['maxSlots'], fallback: 1),
      bookedSlots: _toInt(json['bookedSlots'], fallback: 0),
      isAvailable: json['is_active'] == 1 || json['isAvailable'] == true,

      doctorName:
          doctor?['full_name']?.toString() ??
          doctor?['fullName']?.toString() ??
          doctor?['user']?['full_name']?.toString() ??
          doctor?['user']?['fullName']?.toString(),
      doctorTitle: doctor?['title']?.toString(),
      roomName: room?['name']?.toString(),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }
}
