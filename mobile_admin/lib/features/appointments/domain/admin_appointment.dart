class AdminAppointment {
  const AdminAppointment({
    required this.id,
    required this.refCode,
    required this.status,
    required this.patientName,
    required this.doctorName,
    required this.specialtyName,
    required this.apptDate,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final String refCode;
  final String status;
  final String patientName;
  final String doctorName;
  final String specialtyName;
  final DateTime? apptDate;
  final DateTime? startTime;
  final DateTime? endTime;

  String get patientInitial {
    final trimmed = patientName.trim();
    if (trimmed.isEmpty) {
      return 'A';
    }

    return trimmed[0].toUpperCase();
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String get doctorDisplayName =>
      doctorName.trim().isEmpty ? 'Chưa gán bác sĩ' : 'BS. $doctorName';

  String get timeRangeLabel {
    final start = _formatTime(startTime);
    final end = _formatTime(endTime);

    if (start.isEmpty && end.isEmpty) {
      return 'Chưa có thời gian';
    }

    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start - $end';
    }

    return start.isNotEmpty ? start : end;
  }

  String get dateTimeLabel {
    final date = _formatDate(apptDate);
    final time = timeRangeLabel;

    if (date.isEmpty) {
      return time;
    }

    if (time == 'Chưa có thời gian') {
      return date;
    }

    return '$date  |  $time';
  }

  String get dialogTimeLabel {
    final date = _formatCompactDate(apptDate);
    final time = timeRangeLabel;

    if (date.isEmpty) {
      return time;
    }

    return '$time, $date';
  }

  factory AdminAppointment.fromJson(Map<String, dynamic> json) {
    final patient = _asMap(json['patient']);
    final doctor = _asMap(json['doctor']);
    final doctorUser = _asMap(doctor['user']);
    final specialty = _asMap(doctor['specialty']);
    final schedule = _asMap(json['schedule']);

    return AdminAppointment(
      id: json['id']?.toString() ?? '',
      refCode: json['refCode']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      patientName: patient['fullName']?.toString() ?? 'Chưa rõ bệnh nhân',
      doctorName: doctorUser['fullName']?.toString() ?? '',
      specialtyName: specialty['name']?.toString() ?? 'Chưa rõ chuyên khoa',
      apptDate: _tryParseDate(json['apptDate']),
      startTime: _tryParseDate(schedule['startTime'] ?? json['apptTime']),
      endTime: _tryParseDate(schedule['endTime']),
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

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  static String _formatCompactDate(DateTime? value) {
    if (value == null) {
      return '';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  static String _formatTime(DateTime? value) {
    if (value == null) {
      return '';
    }

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class AdminAppointmentsPage {
  const AdminAppointmentsPage({required this.items, required this.total});

  final List<AdminAppointment> items;
  final int total;
}
