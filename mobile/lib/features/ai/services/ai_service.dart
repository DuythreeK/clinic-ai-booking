import 'package:dio/dio.dart';

import '../../../core/api/dio_client.dart';

class AiTriageResult {
  const AiTriageResult({
    required this.urgency,
    required this.specialty,
    required this.reasoning,
  });

  final String urgency;
  final String specialty;
  final String reasoning;

  factory AiTriageResult.fromJson(Map<String, dynamic> json) {
    return AiTriageResult(
      urgency: (json['urgency'] as String? ?? '').trim(),
      specialty: (json['specialty'] as String? ?? '').trim(),
      reasoning: (json['reasoning'] as String? ?? '').trim(),
    );
  }
}

class AiService {
  AiService({required this.dioClient});

  final DioClient dioClient;

  Future<AiTriageResult> triageSymptoms(String symptoms) async {
    try {
      final response = await dioClient.post<dynamic>(
        '/ai/triage',
        data: {
          'symptoms': symptoms,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Triage request failed with status ${response.statusCode}');
      }

      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        throw Exception('Invalid AI response format');
      }

      final result = AiTriageResult.fromJson(payload);
      if (result.urgency.isEmpty || result.specialty.isEmpty || result.reasoning.isEmpty) {
        throw Exception('AI response is missing required fields');
      }

      return result;
    } on DioException catch (e) {
      final serverMessage = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString())
          : null;
      throw Exception(serverMessage ?? 'AI service failed. Please try again.');
    }
  }
}
