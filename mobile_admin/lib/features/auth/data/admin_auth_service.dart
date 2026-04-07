import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/admin_api_config.dart';
import '../../../core/network/admin_api_exception.dart';
import '../domain/admin_session_user.dart';

class AdminAuthService {
  AdminAuthService({http.Client? client}) : _client = client ?? http.Client();

  static const String _tokenStorageKey = 'admin_access_token';

  final http.Client _client;

  Future<AdminSessionUser?> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final storedToken = preferences.getString(_tokenStorageKey)?.trim() ?? '';

    if (storedToken.isNotEmpty) {
      AdminApiConfig.setAccessToken(storedToken);
    }

    if (!AdminApiConfig.hasAccessToken) {
      return null;
    }

    try {
      return await fetchProfile();
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<AdminSessionUser> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _client.post(
      AdminApiConfig.adminUri('/admin/auth/login'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'identifier': identifier.trim(), 'password': password}),
    );

    final body = _decodeResponse(response);
    final accessToken = body['accessToken']?.toString().trim() ?? '';
    if (accessToken.isEmpty) {
      throw const AdminApiException(
        'Đăng nhập thành công nhưng không nhận được access token.',
      );
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenStorageKey, accessToken);
    AdminApiConfig.setAccessToken(accessToken);

    final userJson = body['user'];
    if (userJson is Map<String, dynamic>) {
      return AdminSessionUser.fromJson(userJson);
    }

    if (userJson is Map) {
      return AdminSessionUser.fromJson(
        userJson.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    return fetchProfile();
  }

  Future<AdminSessionUser> fetchProfile() async {
    final response = await _client.get(
      AdminApiConfig.adminUri('/admin/auth/me'),
      headers: _headers(),
    );

    return AdminSessionUser.fromJson(_decodeResponse(response));
  }

  Future<void> logout() async {
    try {
      if (AdminApiConfig.hasAccessToken) {
        await _client.post(
          AdminApiConfig.adminUri('/admin/auth/logout'),
          headers: _headers(),
        );
      }
    } catch (_) {
      // Ignore logout request failures and clear local session anyway.
    } finally {
      await clearSession();
    }
  }

  Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenStorageKey);
    AdminApiConfig.clearAccessToken();
  }

  Map<String, String> _headers() {
    return {
      'Authorization': 'Bearer ${AdminApiConfig.accessToken}',
      'Accept': 'application/json',
    };
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
