import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/admin_api_config.dart';
import '../../../core/network/admin_api_exception.dart';
import '../domain/admin_dashboard_overview.dart';

class AdminDashboardService {
  AdminDashboardService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<AdminDashboardOverview> fetchOverview() async {
    _ensureConfigured();

    final response = await _client.get(
      AdminApiConfig.adminUri('/admin/stats/overview'),
      headers: _headers(),
    );

    return AdminDashboardOverview.fromJson(_decodeResponse(response));
  }

  Map<String, String> _headers() {
    return {
      'Authorization': 'Bearer ${AdminApiConfig.accessToken}',
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
