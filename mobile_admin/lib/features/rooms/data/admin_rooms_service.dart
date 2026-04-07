import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/admin_api_config.dart';
import '../../../core/network/admin_api_exception.dart';
import '../domain/admin_room.dart';

class AdminRoomPayload {
  const AdminRoomPayload({
    required this.name,
    required this.code,
    required this.floor,
    required this.isActive,
    this.specialtyId,
    this.description,
  });

  final String name;
  final String code;
  final int floor;
  final bool isActive;
  final String? specialtyId;
  final String? description;

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      'floor': floor,
      'isActive': isActive,
      if (specialtyId != null && specialtyId!.isNotEmpty)
        'specialtyId': specialtyId,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      'floor': floor,
      'isActive': isActive,
      'specialtyId': specialtyId == null || specialtyId!.isEmpty
          ? null
          : specialtyId,
      'description': description == null || description!.trim().isEmpty
          ? null
          : description!.trim(),
    };
  }
}

class AdminRoomsService {
  AdminRoomsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<AdminRoom>> fetchRooms({
    String search = '',
    bool? isActive,
    String? specialtyId,
  }) async {
    _ensureConfigured();

    final response = await _client.get(
      AdminApiConfig.adminUri(
        '/admin/rooms',
        queryParameters: {
          'limit': '100',
          'search': search,
          if (isActive != null) 'isActive': '$isActive',
          if (specialtyId != null && specialtyId.isNotEmpty)
            'specialtyId': specialtyId,
        },
      ),
      headers: _headers(),
    );

    final body = _decodeResponse(response);
    final items = body['data'] as List<dynamic>? ?? const [];
    return items
        .map((item) => AdminRoom.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminRoom> createRoom(AdminRoomPayload payload) async {
    _ensureConfigured();

    final response = await _client.post(
      AdminApiConfig.adminUri('/admin/rooms'),
      headers: _jsonHeaders(),
      body: jsonEncode(payload.toCreateJson()),
    );

    return AdminRoom.fromJson(_decodeResponse(response));
  }

  Future<AdminRoom> updateRoom(String roomId, AdminRoomPayload payload) async {
    _ensureConfigured();

    final response = await _client.patch(
      AdminApiConfig.adminUri('/admin/rooms/$roomId'),
      headers: _jsonHeaders(),
      body: jsonEncode(payload.toUpdateJson()),
    );

    return AdminRoom.fromJson(_decodeResponse(response));
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
