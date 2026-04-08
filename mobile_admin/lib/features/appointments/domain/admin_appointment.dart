class AdminAppointment {
  const AdminAppointment({
    required this.id,
    required this.patientId,
    required this.refCode,
    required this.status,
    required this.patientName,
    required this.patientPhone,
    required this.patientGender,
    this.patientDob,
    required this.doctorName,
    required this.specialtyName,
    required this.apptDate,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final String patientId;
  final String refCode;
  final String status;
  final String patientName;
  final String patientPhone;
  final String patientGender;
  final DateTime? patientDob;
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
  bool get isCheckedIn => status == 'checked_in';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isNoShow => status == 'no_show';
  bool get isCancelled => status == 'cancelled';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'checked_in':
        return 'Đã Check-in';
      case 'in_progress':
        return 'Đang khám';
      case 'completed':
        return 'Hoàn thành';
      case 'no_show':
        return 'Không đến';
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
      id: (json['appointment_id'] ?? json['id'] ?? '').toString(),
      patientId: (patient['patient_id'] ?? patient['id'] ?? '').toString(),
      refCode: json['appointment_code']?.toString() ?? json['refCode']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      patientName: patient['full_name']?.toString() ?? patient['fullName']?.toString() ?? 'Chưa rõ bệnh nhân',
      patientPhone: patient['phone_number']?.toString() ?? patient['phone']?.toString() ?? '',
      patientGender: patient['gender']?.toString() ?? 'Chưa cập nhật',
      patientDob: _tryParseDate(patient['date_of_birth'] ?? patient['dob']),
      doctorName: doctorUser['full_name']?.toString() ?? doctorUser['fullName']?.toString() ?? '',
      specialtyName: specialty['name']?.toString() ?? 'Chưa rõ chuyên khoa',
      apptDate: _tryParseDate(json['appointment_date'] ?? json['apptDate']),
      startTime: _tryParseDate(schedule['startTime'] ?? json['appointment_time'] ?? json['apptTime']),
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

  String get patientDobLabel {
    if (patientDob == null) return 'Chưa có năm sinh';
    return _formatDate(patientDob);
  }

  String get patientGenderLabel {
    if (patientGender == 'male') return 'Nam';
    if (patientGender == 'female') return 'Nữ';
    return 'Khác';
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
