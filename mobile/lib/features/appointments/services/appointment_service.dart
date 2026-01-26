import 'package:clinic_ai_booking/core/api/dio_client.dart';
import 'package:clinic_ai_booking/core/models/models.dart';

class AppointmentService {
  final DioClient dioClient;

  AppointmentService({required this.dioClient});

  /// Tạo lịch hẹn mới
  Future<Appointment> createAppointment({
    required String doctorId,
    required String slotId,
    required String reason,
    List<String>? attachments,
  }) async {
    final response = await dioClient.post(
      '/appointments',
      data: {
        'doctorId': doctorId,
        'slotId': slotId,
        'reason': reason,
        'attachments': attachments ?? [],
      },
    );

    return Appointment.fromJson(response.data);
  }

  /// Lấy danh sách lịch hẹn của bệnh nhân
  Future<List<Appointment>> getMyAppointments({
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, dynamic>{};

    if (status != null) queryParams['status'] = status;
    if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();

    final response = await dioClient.get(
      '/appointments',
      queryParameters: queryParams,
    );

    final appointments = (response.data as List)
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();

    return appointments;
  }

  /// Lấy chi tiết lịch hẹn
  Future<Appointment> getAppointmentById(String appointmentId) async {
    final response = await dioClient.get('/appointments/$appointmentId');
    return Appointment.fromJson(response.data);
  }

  /// Cập nhật lịch hẹn
  Future<Appointment> updateAppointment(
    String appointmentId, {
    required String reason,
    List<String>? attachments,
  }) async {
    final response = await dioClient.patch(
      '/appointments/$appointmentId',
      data: {
        'reason': reason,
        'attachments': attachments ?? [],
      },
    );

    return Appointment.fromJson(response.data);
  }

  /// Cập nhật trạng thái lịch hẹn
  Future<Appointment> updateAppointmentStatus(
    String appointmentId,
    String newStatus,
  ) async {
    final response = await dioClient.patch(
      '/appointments/$appointmentId/status',
      data: {'status': newStatus},
    );

    return Appointment.fromJson(response.data);
  }

  /// Lên lịch lại lịch hẹn
  Future<Appointment> rescheduleAppointment(
    String appointmentId,
    String newSlotId, {
    String? reason,
  }) async {
    final response = await dioClient.post(
      '/appointments/$appointmentId/reschedule',
      data: {
        'newSlotId': newSlotId,
        if (reason != null) 'reason': reason,
      },
    );

    return Appointment.fromJson(response.data);
  }

  /// Hủy lịch hẹn
  Future<void> cancelAppointment(String appointmentId) async {
    await dioClient.post('/appointments/$appointmentId/cancel');
  }

  /// Xóa lịch hẹn (chỉ admin)
  Future<void> deleteAppointment(String appointmentId) async {
    await dioClient.delete('/appointments/$appointmentId');
  }
}
