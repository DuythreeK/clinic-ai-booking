class AdminDashboardOverview {
  const AdminDashboardOverview({
    required this.metrics,
    required this.weeklyAppointments,
    required this.recentActivities,
  });

  final AdminDashboardMetrics metrics;
  final List<AdminWeeklyAppointmentPoint> weeklyAppointments;
  final List<AdminRecentActivity> recentActivities;

  factory AdminDashboardOverview.fromJson(Map<String, dynamic> json) {
    return AdminDashboardOverview(
      metrics: AdminDashboardMetrics.fromJson(_asMap(json['metrics'])),
      weeklyAppointments: (_asList(
        json['weeklyAppointments'],
      )).map(AdminWeeklyAppointmentPoint.fromJson).toList(),
      recentActivities: (_asList(
        json['recentActivities'],
      )).map(AdminRecentActivity.fromJson).toList(),
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

  static List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is List) {
      return value.map((item) => _asMap(item)).toList(growable: false);
    }

    return const [];
  }
}

class AdminDashboardMetrics {
  const AdminDashboardMetrics({
    required this.totalAppointments,
    required this.pendingAppointments,
    required this.activeDoctors,
    required this.totalPatients,
  });

  final int totalAppointments;
  final int pendingAppointments;
  final int activeDoctors;
  final int totalPatients;

  factory AdminDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return AdminDashboardMetrics(
      totalAppointments: _toInt(json['totalAppointments']),
      pendingAppointments: _toInt(json['pendingAppointments']),
      activeDoctors: _toInt(json['activeDoctors']),
      totalPatients: _toInt(json['totalPatients']),
    );
  }
}

class AdminWeeklyAppointmentPoint {
  const AdminWeeklyAppointmentPoint({
    required this.label,
    required this.date,
    required this.count,
  });

  final String label;
  final DateTime date;
  final int count;

  factory AdminWeeklyAppointmentPoint.fromJson(Map<String, dynamic> json) {
    return AdminWeeklyAppointmentPoint(
      label: json['label']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      count: _toInt(json['count']),
    );
  }
}

class AdminRecentActivity {
  const AdminRecentActivity({
    required this.id,
    required this.patientName,
    required this.patientInitial,
    required this.actionLabel,
    required this.occurredAt,
  });

  final String id;
  final String patientName;
  final String patientInitial;
  final String actionLabel;
  final DateTime occurredAt;

  factory AdminRecentActivity.fromJson(Map<String, dynamic> json) {
    return AdminRecentActivity(
      id: json['id']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? 'Chưa rõ bệnh nhân',
      patientInitial: json['patientInitial']?.toString() ?? 'N',
      actionLabel: json['actionLabel']?.toString() ?? 'Cập nhật lịch hẹn',
      occurredAt:
          DateTime.tryParse(json['occurredAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
