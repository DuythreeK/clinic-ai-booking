import 'package:clinic_ai_booking/core/api/dio_client.dart';
import 'package:clinic_ai_booking/core/models/models.dart';

class AiService {
  final DioClient dioClient;

  AiService({required this.dioClient});

  /// Lọc phân loại triệu chứng AI
  Future<TriageResult> performTriage({
    required List<String> symptoms,
    String? duration,
    String? severity,
    Map<String, dynamic>? additionalInfo,
  }) async {
    final response = await dioClient.post(
      '/ai/triage',
      data: {
        'symptoms': symptoms,
        if (duration != null) 'duration': duration,
        if (severity != null) 'severity': severity,
        if (additionalInfo != null) 'additionalInfo': additionalInfo,
      },
    );

    return TriageResult.fromJson(response.data);
  }

  /// Tạo tóm tắt trước khám
  Future<Map<String, dynamic>> generatePrevisitSummary({
    required Map<String, dynamic> patientData,
    String? appointmentId,
    List<Map<String, dynamic>>? previousAppointments,
  }) async {
    final response = await dioClient.post(
      '/ai/previsit-summary',
      data: {
        'patientData': patientData,
        if (appointmentId != null) 'appointmentId': appointmentId,
        if (previousAppointments != null) 'previousAppointments': previousAppointments,
      },
    );

    return response.data as Map<String, dynamic>;
  }
}
