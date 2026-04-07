import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/admin_api_config.dart';
import '../../../core/network/admin_api_exception.dart';
import '../domain/admin_notification_settings.dart';

class AdminSettingsService {
  AdminSettingsService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<AdminNotificationSettings> fetchNotificationSettings() async {
    _ensureConfigured();

    final response = await _client.get(
      AdminApiConfig.adminUri('/admin/settings/notifications'),
      headers: _headers(),
    );

    return AdminNotificationSettings.fromJson(_decodeResponse(response));
  }

  Future<AdminNotificationSettings> updateNotificationSettings(
    AdminNotificationSettings settings,
  ) async {
    _ensureConfigured();

    final response = await _client.patch(
      AdminApiConfig.adminUri('/admin/settings/notifications'),
      headers: _jsonHeaders(),
      body: jsonEncode(settings.toJson()),
    );

    return AdminNotificationSettings.fromJson(_decodeResponse(response));
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
