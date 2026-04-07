class AdminNotificationSettings {
  const AdminNotificationSettings({
    required this.pushEnabled,
    required this.soundEnabled,
    required this.appointmentReminder,
    required this.statusUpdates,
    required this.reminderLeadMinutes,
  });

  final bool pushEnabled;
  final bool soundEnabled;
  final bool appointmentReminder;
  final bool statusUpdates;
  final int reminderLeadMinutes;

  AdminNotificationSettings copyWith({
    bool? pushEnabled,
    bool? soundEnabled,
    bool? appointmentReminder,
    bool? statusUpdates,
    int? reminderLeadMinutes,
  }) {
    return AdminNotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      appointmentReminder: appointmentReminder ?? this.appointmentReminder,
      statusUpdates: statusUpdates ?? this.statusUpdates,
      reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushEnabled,
      'soundEnabled': soundEnabled,
      'appointmentReminder': appointmentReminder,
      'statusUpdates': statusUpdates,
      'reminderLeadMinutes': reminderLeadMinutes,
    };
  }

  factory AdminNotificationSettings.fromJson(Map<String, dynamic> json) {
    return AdminNotificationSettings(
      pushEnabled: json['pushEnabled'] == true,
      soundEnabled: json['soundEnabled'] == true,
      appointmentReminder: json['appointmentReminder'] == true,
      statusUpdates: json['statusUpdates'] == true,
      reminderLeadMinutes: _toInt(json['reminderLeadMinutes'], 30),
    );
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
