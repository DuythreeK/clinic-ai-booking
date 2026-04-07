import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/admin_api_config.dart';
import '../../../core/network/admin_api_exception.dart';
import '../domain/admin_doctor.dart';

class AdminDoctorPayload {
  const AdminDoctorPayload({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
    required this.specialtyId,
    required this.title,
    required this.licenseNumber,
    required this.bio,
    required this.yearsExperience,
    required this.consultationFee,
    required this.isActive,
  });

  final String fullName;
  final String phone;
  final String email;
  final String password;
  final String specialtyId;
  final String title;
  final String licenseNumber;
  final String bio;
  final double yearsExperience;
  final double consultationFee;
  final bool isActive;

  Map<String, dynamic> toCreateJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      if (email.trim().isNotEmpty) 'email': email.trim(),
      'password': password,
      'specialtyId': specialtyId,
      'title': title,
      'licenseNumber': licenseNumber,
      if (bio.trim().isNotEmpty) 'bio': bio.trim(),
      'yearsExperience': yearsExperience,
      'consultationFee': consultationFee,
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'email': email.trim().isEmpty ? null : email.trim(),
      if (password.trim().isNotEmpty) 'password': password,
      'specialtyId': specialtyId,
      'title': title,
      'licenseNumber': licenseNumber,
      'bio': bio.trim().isEmpty ? null : bio.trim(),
      'yearsExperience': yearsExperience,
      'consultationFee': consultationFee,
      'isActive': isActive,
    };
  }
}

class AdminDoctorsService {
  AdminDoctorsService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<AdminDoctorsPage> fetchDoctors({
    String search = '',
    String? specialtyId,
    int limit = 100,
  }) async {
    _ensureConfigured();

    final response = await _client.get(
      AdminApiConfig.adminUri(
        '/admin/doctors',
        queryParameters: {
          'limit': '$limit',
          'search': search,
          if (specialtyId != null) 'specialtyId': specialtyId,
        },
      ),
      headers: _headers(),
    );

    final body = _decodeResponse(response);
    final items = (body['data'] as List<dynamic>? ?? const [])
        .map((item) => AdminDoctor.fromJson(item as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>? ?? const {};

    return AdminDoctorsPage(
      items: items,
      total: int.tryParse(meta['total']?.toString() ?? '0') ?? 0,
    );
  }

  Future<AdminDoctor> createDoctor(AdminDoctorPayload payload) async {
    _ensureConfigured();

    final response = await _client.post(
      AdminApiConfig.adminUri('/admin/doctors'),
      headers: _jsonHeaders(),
      body: jsonEncode(payload.toCreateJson()),
    );

    return AdminDoctor.fromJson(_decodeResponse(response));
  }

  Future<AdminDoctor> updateDoctor(
    String doctorId,
    AdminDoctorPayload payload,
  ) async {
    _ensureConfigured();

    final response = await _client.patch(
      AdminApiConfig.adminUri('/admin/doctors/$doctorId'),
      headers: _jsonHeaders(),
      body: jsonEncode(payload.toUpdateJson()),
    );

    return AdminDoctor.fromJson(_decodeResponse(response));
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
