import 'package:clinic_ai_booking/core/api/dio_client.dart';
import 'package:clinic_ai_booking/core/models/models.dart';

class SlotService {
  final DioClient dioClient;

  SlotService({required this.dioClient});

  /// Lấy các khe thời gian có sẵn
  Future<List<Slot>> getAvailableSlots({
    required String doctorId,
    required String clinicId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, dynamic>{
      'doctorId': doctorId,
      'clinicId': clinicId,
    };

    if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();

    final response = await dioClient.get(
      '/slots/available',
      queryParameters: queryParams,
    );

    final slots = (response.data as List)
        .map((json) => Slot.fromJson(json as Map<String, dynamic>))
        .toList();

    return slots;
  }

  /// Lấy các khe thời gian theo ngày
  Future<List<Slot>> getSlotsByDate({
    required String doctorId,
    required DateTime date,
    required String clinicId,
  }) async {
    final nextDay = date.add(const Duration(days: 1));

    return getAvailableSlots(
      doctorId: doctorId,
      clinicId: clinicId,
      fromDate: date,
      toDate: nextDay,
    );
  }

  /// Lấy các khe thời gian theo tuần
  Future<List<Slot>> getSlotsByWeek({
    required String doctorId,
    required String clinicId,
    required DateTime startDate,
  }) async {
    final endDate = startDate.add(const Duration(days: 7));

    return getAvailableSlots(
      doctorId: doctorId,
      clinicId: clinicId,
      fromDate: startDate,
      toDate: endDate,
    );
  }
}
