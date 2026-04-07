import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/admin_api_config.dart';
import '../../../core/network/admin_api_exception.dart';
import '../domain/admin_appointment.dart';

class AdminAppointmentsService {
  AdminAppointmentsService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<AdminAppointmentsPage> fetchAppointments({
    String? status,
    String search = '',
    int page = 1,
    int limit = 20,
  }) async {
    _ensureConfigured();

    final response = await _client.get(
      AdminApiConfig.adminUri(
        '/admin/appointments',
        queryParameters: {
          'page': '$page',
          'limit': '$limit',
          'search': search,
          if (status != null) 'status': status,
        },
      ),
      headers: _headers(),
    );

    final decoded = _decodeResponse(response);
    final items = (decoded['data'] as List<dynamic>? ?? const [])
        .map((item) => AdminAppointment.fromJson(item as Map<String, dynamic>))
        .toList();
    final meta = decoded['meta'] as Map<String, dynamic>? ?? const {};

    return AdminAppointmentsPage(
      items: items,
      total: int.tryParse(meta['total']?.toString() ?? '0') ?? 0,
    );
  }

  Future<void> confirmAppointment(String appointmentId) async {
    _ensureConfigured();

    final response = await _client.patch(
      AdminApiConfig.adminUri('/admin/appointments/$appointmentId/status'),
      headers: _headers(),
      body: jsonEncode(const {'status': 'confirmed'}),
    );

    _decodeResponse(response);
  }

  Future<void> cancelAppointment(
    String appointmentId, {
    required String cancelReason,
  }) async {
    _ensureConfigured();

    final response = await _client.patch(
      AdminApiConfig.adminUri('/admin/appointments/$appointmentId/cancel'),
      headers: _headers(),
      body: jsonEncode({'cancelReason': cancelReason}),
    );

    _decodeResponse(response);
  }

  Map<String, String> _headers() {
    return {
      'Authorization': 'Bearer ${AdminApiConfig.accessToken}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
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
