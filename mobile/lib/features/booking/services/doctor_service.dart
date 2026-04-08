import 'package:clinic_ai_booking/core/api/dio_client.dart';
import 'package:clinic_ai_booking/core/models/models.dart';

class DoctorService {
  final DioClient dioClient;

  DoctorService({required this.dioClient});

  /// Lấy danh sách tất cả bác sĩ
  Future<List<Doctor>> getAllDoctors({
    String? specialtyId,
    bool? isApproved,
  }) async {
    final queryParams = <String, dynamic>{};

    if (specialtyId != null) queryParams['specialtyId'] = specialtyId;
    if (isApproved != null) queryParams['isApproved'] = isApproved;

    final response = await dioClient.get(
      '/doctors',
      queryParameters: queryParams,
    );

    final doctors = (response.data as List)
        .map((json) => Doctor.fromJson(json as Map<String, dynamic>))
        .toList();

    return doctors;
  }

  /// Lấy chi tiết bác sĩ
  Future<Doctor> getDoctorById(String doctor_id) async {
    final response = await dioClient.get('/doctors/$doctor_id');
    return Doctor.fromJson(response.data);
  }

  /// Lấy các bác sĩ theo chuyên khoa
  Future<List<Doctor>> getDoctorsBySpecialty(String specialtyId) async {
    return getAllDoctors(specialtyId: specialtyId, isApproved: true);
  }

  /// Tìm kiếm bác sĩ
  Future<List<Doctor>> searchDoctors(String query) async {
    final response = await dioClient.get(
      '/doctors',
      queryParameters: {'search': query},
    );

    final doctors = (response.data as List)
        .map((json) => Doctor.fromJson(json as Map<String, dynamic>))
        .toList();

    return doctors;
  }

  /// Lấy tính khả dụng của bác sĩ
  Future<List<Slot>> getDoctorAvailability(
    String doctor_id, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, dynamic>{};

    if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();

    final response = await dioClient.get(
      '/slots/available',
      queryParameters: {
        ...queryParams,
        'doctor_id': doctor_id,
      },
    );

    final slots = (response.data as List)
        .map((json) => Slot.fromJson(json as Map<String, dynamic>))
        .toList();

    return slots;
  }
}
