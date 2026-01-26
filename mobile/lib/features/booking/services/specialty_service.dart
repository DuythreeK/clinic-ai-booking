import 'package:clinic_ai_booking/core/api/dio_client.dart';
import 'package:clinic_ai_booking/core/models/models.dart';

class SpecialtyService {
  final DioClient dioClient;

  SpecialtyService({required this.dioClient});

  /// Lấy danh sách tất cả chuyên khoa
  Future<List<Specialty>> getAllSpecialties() async {
    final response = await dioClient.get('/specialties');

    final specialties = (response.data as List)
        .map((json) => Specialty.fromJson(json as Map<String, dynamic>))
        .toList();

    return specialties;
  }

  /// Lấy chi tiết chuyên khoa
  Future<Specialty> getSpecialtyById(String specialtyId) async {
    final response = await dioClient.get('/specialties/$specialtyId');
    return Specialty.fromJson(response.data);
  }

  /// Tìm kiếm chuyên khoa
  Future<List<Specialty>> searchSpecialties(String query) async {
    final response = await dioClient.get(
      '/specialties',
      queryParameters: {'search': query},
    );

    final specialties = (response.data as List)
        .map((json) => Specialty.fromJson(json as Map<String, dynamic>))
        .toList();

    return specialties;
  }
}
