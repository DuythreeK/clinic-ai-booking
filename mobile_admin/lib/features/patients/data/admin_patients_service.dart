import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/admin_api_config.dart';
import '../../../core/network/admin_api_exception.dart';
import '../domain/admin_patient.dart';

class AdminPatientsService {
  AdminPatientsService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<AdminPatientsPage> fetchPatients({String search = ''}) async {
    _ensureConfigured();

    final response = await _client.get(
      AdminApiConfig.adminUri(
        '/admin/patients',
        queryParameters: {'limit': '100', 'search': search},
      ),
      headers: _headers(),
    );

    final body = _decodeResponse(response);
    final items = (body['data'] as List<dynamic>? ?? const [])
        .map((item) => AdminPatient.fromJson(item as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>? ?? const {};

    return AdminPatientsPage(
      items: items,
      total: int.tryParse(meta['total']?.toString() ?? '0') ?? 0,
    );
  }

  Future<AdminPatient> fetchPatient(String patientId) async {
    _ensureConfigured();

    final response = await _client.get(
      AdminApiConfig.adminUri('/admin/patients/$patientId'),
      headers: _headers(),
    );

    return AdminPatient.fromJson(_decodeResponse(response));
  }

  Future<List<dynamic>> fetchMedicalRecords(String patientId) async {
    _ensureConfigured();

    final response = await _client.get(
      AdminApiConfig.adminUri(
        '/admin/medical-records',
        queryParameters: {'limit': '50', 'patientId': patientId},
      ),
      headers: _headers(),
    );

    final body = _decodeResponse(response);
    return body['data'] as List<dynamic>? ?? const [];
  }

  Future<AdminPatientProfile> fetchPatientProfile(String patientId) async {
    final results = await Future.wait([
      fetchPatient(patientId),
      fetchMedicalRecords(patientId),
    ]);

    final patient = results[0] as AdminPatient;
    final records = results[1] as List<dynamic>;
    final medications = <AdminMedicationItem>[];
    final history = <AdminHistoryItem>[];

    for (final item in records) {
      final record = item is Map<String, dynamic>
          ? item
          : (item as Map).map((key, value) => MapEntry(key.toString(), value));

      final diagnosis = record['diagnosis']?.toString().trim();
      if (diagnosis != null && diagnosis.isNotEmpty) {
        history.add(AdminHistoryItem(label: diagnosis));
      }

      final prescription = record['prescription'];
      if (prescription is List) {
        for (final medicine in prescription) {
          if (medicine is Map) {
            final name =
                medicine['name']?.toString() ??
                medicine['drug']?.toString() ??
                medicine['medicine']?.toString() ??
                '';
            final dosage =
                medicine['dosage']?.toString() ??
                medicine['instruction']?.toString() ??
                medicine['frequency']?.toString() ??
                '';

            if (name.trim().isNotEmpty) {
              medications.add(
                AdminMedicationItem(
                  name: name.trim(),
                  dosage: dosage.trim().isEmpty
                      ? 'Đang cập nhật'
                      : dosage.trim(),
                ),
              );
            }
          }
        }
      }
    }

    return AdminPatientProfile(
      patient: patient,
      medications: medications,
      history: history,
    );
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
