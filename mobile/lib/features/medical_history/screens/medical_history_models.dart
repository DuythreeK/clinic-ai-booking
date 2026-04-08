import 'package:flutter/material.dart';

import '../../../core/api/dio_client.dart';
import '../../booking/screens/doctor_hub_models.dart';

class MedicalHistoryItem {
  const MedicalHistoryItem({
    required this.id,
    required this.title,
    required this.day,
    required this.monthYear,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.feeLabel,
    required this.primaryStatus,
    required this.secondaryStatus,
    required this.orderNumber,
    required this.queueNumber,
    required this.clinicFeeLabel,
    required this.totalAmountLabel,
    required this.symptomNote,
    required this.caseSummary,
    required this.fileName,
    required this.fileUrl,
  });

  final String id;
  final String title;
  final String day;
  final String monthYear;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String feeLabel;
  final String primaryStatus;
  final String secondaryStatus;
  final String orderNumber;
  final String queueNumber;
  final String clinicFeeLabel;
  final String totalAmountLabel;
  final String symptomNote;
  final String caseSummary;
  final String fileName;
  final String fileUrl;

  factory MedicalHistoryItem.fromApi(Map<String, dynamic> json) {
    return MedicalHistoryItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      monthYear: json['monthYear']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? '',
      feeLabel: json['feeLabel']?.toString() ?? '',
      primaryStatus: json['primaryStatus']?.toString() ?? '',
      secondaryStatus: json['secondaryStatus']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      queueNumber: json['queueNumber']?.toString() ?? '',
      clinicFeeLabel: json['clinicFeeLabel']?.toString() ?? '',
      totalAmountLabel: json['totalAmountLabel']?.toString() ?? '',
      symptomNote: json['symptomNote']?.toString() ?? '',
      caseSummary: json['caseSummary']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
    );
  }
}

class MedicalHistoryCatalog {
  MedicalHistoryCatalog._();

  static final DioClient _dioClient = DioClient();
  static List<MedicalHistoryItem> _items = <MedicalHistoryItem>[];
  static bool _loading = false;

  static List<MedicalHistoryItem> get items => _items;
  static bool get isLoading => _loading;

  static Future<void> loadRemote({bool force = false}) async {
    if (_loading) return;
    if (!force && _items.isNotEmpty) return;

    _loading = true;
    try {
      final response = await _dioClient.get('/medical-records');
      final items = _unwrapItems(response.data)
          .whereType<Map<String, dynamic>>()
          .map(MedicalHistoryItem.fromApi)
          .where((item) => item.id.isNotEmpty)
          .toList();
      if (items.isNotEmpty) {
        _items = items;
      }
    } catch (_) {
      // keep current local items if the backend is not reachable
    } finally {
      _loading = false;
    }
  }

  static List<dynamic> _unwrapItems(dynamic data) {
    if (data is Map<String, dynamic>) {
      final wrapped = data['data'];
      if (wrapped is List) return wrapped;
      if (wrapped is Map<String, dynamic>) {
        final items = wrapped['items'];
        if (items is List) return items;
      }
      final items = data['items'];
      if (items is List) return items;
    }
    if (data is List) return data;
    return <dynamic>[];
  }

  static MedicalHistoryItem? findById(String id) {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  static DoctorProfile? doctorOf(String doctorId) {
    return DoctorCatalog.instance.findById(doctorId);
  }
  static DoctorProfile fallbackDoctorForItem(MedicalHistoryItem item) {
    return DoctorProfile(
      id: item.doctorId,
      name: item.doctorName,
      specialty: item.specialty,
      focus: item.specialty,
      imageUrl: '',
      rating: 0,
      reviewCount: 0,
      priceValue: 0,
      priceLabel: item.feeLabel,
      bookingToday: 0,
      yearsExperience: 0,
      patientsLabel: item.secondaryStatus,
      nextAvailable: 'Chưa có lịch',
      gender: 'Không rõ',
      email: null,
      phone: null,
      about: item.caseSummary,
      certifications: const <String>[],
      facilities: const <FacilityInfo>[],
      highlight: const Color(0xFF20C8C2),
    );
  }
}


