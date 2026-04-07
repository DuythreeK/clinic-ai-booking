import 'package:clinic_ai_booking/core/api/dio_client.dart';
import 'package:clinic_ai_booking/core/models/models.dart';

class PatientService {
  final DioClient dioClient;

  PatientService({required this.dioClient});

  /// Lấy hồ sơ bệnh nhân của tôi
  Future<PatientProfile> getMyProfile() async {
    final response = await dioClient.get('/patients/profile');
    return PatientProfile.fromJson(response.data);
  }

  /// Cập nhật hồ sơ bệnh nhân
  Future<PatientProfile> updateProfile({
    required String dateOfBirth,
    required String gender,
    required String address,
    required String city,
    required String country,
    String? emergencyPhone,
    String? medicalHistory,
    String? allergies,
    String? currentMedications,
  }) async {
    final response = await dioClient.patch(
      '/patients/profile',
      data: {
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'address': address,
        'city': city,
        'country': country,
        if (emergencyPhone != null) 'emergencyPhone': emergencyPhone,
        if (medicalHistory != null) 'medicalHistory': medicalHistory,
        if (allergies != null) 'allergies': allergies,
        if (currentMedications != null) 'currentMedications': currentMedications,
      },
    );

    return PatientProfile.fromJson(response.data);
  }

  /// Xóa hồ sơ bệnh nhân
  Future<void> deleteProfile() async {
    await dioClient.delete('/patients/profile');
  }
}
