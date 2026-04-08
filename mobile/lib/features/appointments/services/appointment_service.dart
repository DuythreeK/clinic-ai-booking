import 'package:clinic_ai_booking/core/api/dio_client.dart';

class BookingAppointment {
  BookingAppointment({
    required this.appointment_id,
    required this.slot_id,
    required this.facility_id,
    required this.appointmentType,
    required this.status,
    required this.total_amount,
    this.appointment_code,
    this.doctor_id,
  });

  final int appointment_id;
  final int slot_id;
  final int facility_id;
  final String appointmentType;
  final String status;
  final double total_amount;
  final String? appointment_code;
  final int? doctor_id;

  factory BookingAppointment.fromJson(Map<String, dynamic> json) {
    return BookingAppointment(
      appointment_id: (json['appointment_id'] as num?)?.toInt() ?? 0,
      slot_id: (json['slot_id'] as num?)?.toInt() ?? 0,
      facility_id: (json['facility_id'] as num?)?.toInt() ?? 0,
      appointmentType: (json['appointment_type'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      total_amount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      appointment_code: json['appointment_code']?.toString(),
      doctor_id: (json['doctor_id'] as num?)?.toInt(),
    );
  }
}

class BookingPayment {
  BookingPayment({
    required this.paymentId,
    required this.appointment_id,
    required this.paymentMethod,
    required this.amount,
    required this.status,
    this.paymentUrl,
    this.transactionCode,
  });

  final int paymentId;
  final int appointment_id;
  final String paymentMethod;
  final double amount;
  final String status;
  final String? paymentUrl;
  final String? transactionCode;

  factory BookingPayment.fromJson(Map<String, dynamic> json) {
    return BookingPayment(
      paymentId: (json['payment_id'] as num?)?.toInt() ?? 0,
      appointment_id: (json['appointment_id'] as num?)?.toInt() ?? 0,
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
    required int patient_id,
    required int facility_id,
    int? doctor_id,
    required int slot_id,
    required String appointmentType,
    int? service_id,
    int? triageSessionId,
    String? symptomsNote,
    required double total_amount,
  }) async {
    final response = await dioClient.post(
      '/appointments',
      data: {
        'patient_id': patient_id,
        'facility_id': facility_id,
        if (doctor_id != null) 'doctor_id': doctor_id,
        'slot_id': slot_id,
        'appointment_type': appointmentType,
        if (service_id != null) 'service_id': service_id,
        if (triageSessionId != null) 'triage_session_id': triageSessionId,
        if (symptomsNote != null && symptomsNote.isNotEmpty)
          'symptoms_note': symptomsNote,
        'total_amount': total_amount,
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

  Future<BookingPayment> getPaymentByAppointment(int appointment_id) async {
    final response =
        await dioClient.get('/appointments/$appointment_id/payment');
    final data = _unwrapData(response.data);
    return BookingPayment.fromJson(data);
  }

  Future<BookingPayment> createPayment({
    required int appointment_id,
    required String paymentMethod,
    required double amount,
  }) async {
    final response = await dioClient.post(
      '/appointments/$appointment_id/payment',
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
