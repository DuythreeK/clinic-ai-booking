import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';

class AiTriageResult {
  const AiTriageResult({
    required this.urgency,
    required this.specialty,
    required this.reasoning,
  });

  final String urgency;   // Mức độ khẩn cấp
  final String specialty; // Chuyên khoa gợi ý
  final String reasoning; // Lý do/Giải thích

  factory AiTriageResult.fromJson(Map<String, dynamic> json) {
    return AiTriageResult(
      urgency: (json['urgency'] as String? ?? 'Không xác định').trim(),
      specialty: (json['specialty'] as String? ?? 'Chuyên khoa chung').trim(),
      reasoning: (json['reasoning'] as String? ?? 'Không có mô tả chi tiết').trim(),
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

      // Kiểm tra mã trạng thái HTTP
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Yêu cầu chẩn đoán thất bại (Mã lỗi: ${response.statusCode})');
      }

      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        throw Exception('Định dạng phản hồi từ AI không hợp lệ');
      }

      final result = AiTriageResult.fromJson(payload);

      // Kiểm tra dữ liệu rỗng
      if (result.urgency.isEmpty || result.specialty.isEmpty) {
        throw Exception('Phản hồi từ AI thiếu các thông tin quan trọng');
      }

      return result;
    } on DioException catch (e) {
      // Lấy thông báo lỗi từ server nếu có, nếu không thì dùng thông báo mặc định bằng tiếng Việt
      final serverMessage = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString())
          : null;

      throw Exception(serverMessage ?? 'Dịch vụ AI đang gặp sự cố. Vui lòng thử lại sau.');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi ngoài ý muốn: $e');
    }
  }
}