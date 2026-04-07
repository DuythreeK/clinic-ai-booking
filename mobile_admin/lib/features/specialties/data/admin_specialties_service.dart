import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/admin_api_config.dart';
import '../../../core/network/admin_api_exception.dart';
import '../domain/admin_specialty.dart';

class AdminSpecialtyPayload {
  const AdminSpecialtyPayload({
    required this.name,
    required this.code,
    required this.description,
    required this.sortOrder,
    required this.isActive,
  });

  final String name;
  final String code;
  final String description;
  final int sortOrder;
  final bool isActive;

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      if (description.trim().isNotEmpty) 'description': description.trim(),
      'sortOrder': sortOrder,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      'description': description.trim().isEmpty ? null : description.trim(),
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}

class AdminSpecialtiesService {
  AdminSpecialtiesService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<AdminSpecialty>> fetchSpecialties({
    String search = '',
    bool? isActive,
  }) async {
    _ensureConfigured();

    final response = await _client.get(
      AdminApiConfig.adminUri(
        '/admin/specialties',
        queryParameters: {
          'limit': '100',
          'search': search,
          if (isActive != null) 'isActive': '$isActive',
        },
      ),
      headers: _headers(),
    );

    final body = _decodeResponse(response);
    final items = body['data'] as List<dynamic>? ?? const [];
    return items
        .map((item) => AdminSpecialty.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminSpecialty> createSpecialty(AdminSpecialtyPayload payload) async {
    _ensureConfigured();

    final response = await _client.post(
      AdminApiConfig.adminUri('/admin/specialties'),
      headers: _jsonHeaders(),
      body: jsonEncode(payload.toCreateJson()),
    );

    return AdminSpecialty.fromJson(_decodeResponse(response));
  }

  Future<AdminSpecialty> updateSpecialty(
    String specialtyId,
    AdminSpecialtyPayload payload,
  ) async {
    _ensureConfigured();

    final response = await _client.patch(
      AdminApiConfig.adminUri('/admin/specialties/$specialtyId'),
      headers: _jsonHeaders(),
      body: jsonEncode(payload.toUpdateJson()),
    );

    return AdminSpecialty.fromJson(_decodeResponse(response));
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
