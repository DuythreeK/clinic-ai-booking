import 'package:clinic_ai_booking/core/api/dio_client.dart';

class BookingAppointment {
  BookingAppointment({
    required this.appointmentId,
    required this.slotId,
    required this.facilityId,
    required this.appointmentType,
    required this.status,
    required this.totalAmount,
    this.appointmentCode,
    this.doctorId,
  });

  final int appointmentId;
  final int slotId;
  final int facilityId;
  final String appointmentType;
  final String status;
  final double totalAmount;
  final String? appointmentCode;
  final int? doctorId;

  factory BookingAppointment.fromJson(Map<String, dynamic> json) {
    return BookingAppointment(
      appointmentId: (json['appointment_id'] as num?)?.toInt() ?? 0,
      slotId: (json['slot_id'] as num?)?.toInt() ?? 0,
      facilityId: (json['facility_id'] as num?)?.toInt() ?? 0,
      appointmentType: (json['appointment_type'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      appointmentCode: json['appointment_code']?.toString(),
      doctorId: (json['doctor_id'] as num?)?.toInt(),
    );
  }
}

class BookingPayment {
  BookingPayment({
    required this.paymentId,
    required this.appointmentId,
    required this.paymentMethod,
    required this.amount,
    required this.status,
    this.paymentUrl,
    this.transactionCode,
  });

  final int paymentId;
  final int appointmentId;
  final String paymentMethod;
  final double amount;
  final String status;
  final String? paymentUrl;
  final String? transactionCode;

  factory BookingPayment.fromJson(Map<String, dynamic> json) {
    return BookingPayment(
      paymentId: (json['payment_id'] as num?)?.toInt() ?? 0,
      appointmentId: (json['appointment_id'] as num?)?.toInt() ?? 0,
      paymentMethod: (json['payment_method'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: (json['status'] ?? '').toString(),
      paymentUrl: json['payment_url']?.toString(),
      transactionCode: json['transaction_code']?.toString(),
    );
  }
}

class AppointmentService {
  AppointmentService({required this.dioClient});

  final DioClient dioClient;

  Future<BookingAppointment> createAppointment({
    required int patientId,
    required int facilityId,
    int? doctorId,
    required int slotId,
    required String appointmentType,
    int? serviceId,
    int? triageSessionId,
    String? symptomsNote,
    required double totalAmount,
  }) async {
    final response = await dioClient.post(
      '/appointments',
      data: {
        'patient_id': patientId,
        'facility_id': facilityId,
        if (doctorId != null) 'doctor_id': doctorId,
        'slot_id': slotId,
        'appointment_type': appointmentType,
        if (serviceId != null) 'service_id': serviceId,
        if (triageSessionId != null) 'triage_session_id': triageSessionId,
        if (symptomsNote != null && symptomsNote.isNotEmpty)
          'symptoms_note': symptomsNote,
        'total_amount': totalAmount,
      },
    );

    final data = _unwrapData(response.data);
    return BookingAppointment.fromJson(data);
  }

  Future<List<BookingAppointment>> getAppointments({
    String? status,
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await dioClient.get(
      '/appointments',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'limit': limit,
        'offset': offset,
      },
    );

    final body = response.data;
    if (body is Map<String, dynamic>) {
      final list = body['data'];
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(BookingAppointment.fromJson)
            .toList();
      }
    }

    return <BookingAppointment>[];
  }

  Future<BookingPayment> getPaymentByAppointment(int appointmentId) async {
    final response =
        await dioClient.get('/appointments/$appointmentId/payment');
    final data = _unwrapData(response.data);
    return BookingPayment.fromJson(data);
  }

  Future<BookingPayment> createPayment({
    required int appointmentId,
    required String paymentMethod,
    required double amount,
  }) async {
    final response = await dioClient.post(
      '/appointments/$appointmentId/payment',
      data: {
        'payment_method': paymentMethod,
        'amount': amount,
      },
    );

    final data = _unwrapData(response.data);
    return BookingPayment.fromJson(data);
  }

  Future<BookingPayment> checkPaymentStatus(int paymentId) async {
    final response = await dioClient.get('/payments/$paymentId/status');
    final data = _unwrapData(response.data);
    return BookingPayment.fromJson(data);
  }

  Map<String, dynamic> _unwrapData(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return body;
    }
    return <String, dynamic>{};
  }
}
