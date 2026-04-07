import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/admin_api_config.dart';
import '../../../core/network/admin_api_exception.dart';
import '../domain/admin_schedule.dart';

class AdminSchedulePayload {
  const AdminSchedulePayload({
    required this.doctorId,
    this.roomId,
    required this.workDate,
    required this.startTime,
    required this.endTime,
    this.slotDurationMin = 30, // Default to 30 mins
    required this.maxSlots,
    required this.isAvailable,
  });

  final String doctorId;
  final String? roomId;
  final DateTime workDate;
  final DateTime startTime;
  final DateTime endTime;
  final int slotDurationMin;
  final int maxSlots;
  final bool isAvailable;

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      if (roomId != null && roomId!.isNotEmpty) 'roomId': roomId,
      'workDate': workDate.toUtc().toIso8601String(),
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'slotDurationMin': slotDurationMin,
      'maxSlots': maxSlots,
      'isAvailable': isAvailable,
    };
  }
}

class AdminSchedulesService {
  AdminSchedulesService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<AdminSchedule>> fetchSchedules({
    String? doctorId,
    String? roomId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _ensureConfigured();

    final response = await _client.get(
      AdminApiConfig.adminUri(
        '/admin/schedules',
        queryParameters: {
          'limit': '100',
          if (doctorId != null && doctorId.isNotEmpty) 'doctorId': doctorId,
          if (roomId != null && roomId.isNotEmpty) 'roomId': roomId,
          if (fromDate != null) 'fromDate': fromDate.toUtc().toIso8601String(),
          if (toDate != null) 'toDate': toDate.toUtc().toIso8601String(),
        },
      ),
      headers: _headers(),
    );

    final body = _decodeResponse(response);
    final items = body['data'] as List<dynamic>? ?? const [];
    return items
        .map((item) => AdminSchedule.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminSchedule> createSchedule(AdminSchedulePayload payload) async {
    _ensureConfigured();

    final response = await _client.post(
      AdminApiConfig.adminUri('/admin/schedules'),
      headers: _jsonHeaders(),
      body: jsonEncode(payload.toJson()),
    );

    return AdminSchedule.fromJson(_decodeResponse(response));
  }

  Future<AdminSchedule> updateSchedule(
    String id,
    AdminSchedulePayload payload,
  ) async {
    _ensureConfigured();

    final response = await _client.patch(
      AdminApiConfig.adminUri('/admin/schedules/$id'),
      headers: _jsonHeaders(),
      body: jsonEncode(payload.toJson()),
    );

    return AdminSchedule.fromJson(_decodeResponse(response));
  }

  Map<String, String> _headers() {
    return {
      'Authorization': 'Bearer ${AdminApiConfig.accessToken}',
      'Accept': 'application/json',
    };
  }

  Map<String, String> _jsonHeaders() {
    return {..._headers(), 'Content-Type': 'application/json'};
  }

  void _ensureConfigured() {
    if (!AdminApiConfig.hasAccessToken) {
      throw const AdminApiException(
        'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
      );
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = response.bodyBytes.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw AdminApiException(
      body['message']?.toString() ??
          'Yêu cầu thất bại với mã ${response.statusCode}.',
    );
  }
}
