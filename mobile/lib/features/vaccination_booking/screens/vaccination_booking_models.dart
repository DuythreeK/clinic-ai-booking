import 'package:flutter/material.dart';

import '../../../core/api/dio_client.dart';

String? _normalizeProfileDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final raw = value.trim();
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) {
    return parsed.toIso8601String().split('T').first;
  }
  return raw.contains('T') ? raw.split('T').first : raw;
}

class VaccinationFacility {
  const VaccinationFacility({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.rating,
    required this.logoText,
    required this.logoColor,
  });

  final String id;
  final String name;
  final String address;
  final String type;
  final double rating;
  final String logoText;
  final Color logoColor;

  factory VaccinationFacility.fromApi(Map<String, dynamic> json) {
    return VaccinationFacility(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      logoText: VaccinationBookingCatalog._logoTextFromName(json['name']?.toString() ?? ''),
      logoColor: VaccinationBookingCatalog._logoColorFromType(json['type']?.toString() ?? ''),
    );
  }
}

class VaccinationPackage {
  const VaccinationPackage({
    required this.id,
    required this.title,
    required this.facilityId,
    required this.facilityName,
    required this.facilityAddress,
    required this.priceLabel,
    required this.priceValue,
    required this.note,
    required this.badge,
  });

  final String id;
  final String title;
  final String facilityId;
  final String facilityName;
  final String facilityAddress;
  final String priceLabel;
  final int priceValue;
  final String note;
  final String badge;

  factory VaccinationPackage.fromApi(Map<String, dynamic> json) {
    final priceValue = (json['priceValue'] as num?)?.toInt() ?? 0;
    return VaccinationPackage(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      facilityId: json['facilityId']?.toString() ?? '',
      facilityName: json['facilityName']?.toString() ?? '',
      facilityAddress: json['facilityAddress']?.toString() ?? '',
      priceLabel: json['priceLabel']?.toString() ?? '${priceValue.toString()} VND',
      priceValue: priceValue,
      note: json['note']?.toString() ?? '',
      badge: json['badge']?.toString() ?? 'Tiêm chủng',
    );
  }
}

class VaccinationSlotItem {
  const VaccinationSlotItem({
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.availableCount,
  });

  final int slotId;
  final String? startTime;
  final String? endTime;
  final int availableCount;

  factory VaccinationSlotItem.fromApi(Map<String, dynamic> json) {
    return VaccinationSlotItem(
      slotId: (json['slotId'] as num?)?.toInt() ?? 0,
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      availableCount: (json['availableCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class VaccinationSlotGroup {
  const VaccinationSlotGroup({
    required this.date,
    required this.weekdayLabel,
    required this.morningSlots,
    required this.afternoonSlots,
  });

  final String date;
  final String weekdayLabel;
  final List<VaccinationSlotItem> morningSlots;
  final List<VaccinationSlotItem> afternoonSlots;

  factory VaccinationSlotGroup.fromApi(Map<String, dynamic> json) {
    List<VaccinationSlotItem> parseSlots(dynamic value) {
      if (value is! List) return const <VaccinationSlotItem>[];
      return value
          .whereType<Map<String, dynamic>>()
          .map(VaccinationSlotItem.fromApi)
          .toList();
    }

    return VaccinationSlotGroup(
      date: json['date']?.toString() ?? '',
      weekdayLabel: json['weekdayLabel']?.toString() ?? '',
      morningSlots: parseSlots(json['morningSlots']),
      afternoonSlots: parseSlots(json['afternoonSlots']),
    );
  }
}

class VaccinationBookingDetail {
  const VaccinationBookingDetail({
    required this.serviceId,
    required this.serviceName,
    required this.specialty,
    required this.servicePriceValue,
    required this.servicePriceLabel,
    required this.note,
    required this.facility,
    required this.slots,
  });

  final int serviceId;
  final String serviceName;
  final String specialty;
  final int servicePriceValue;
  final String servicePriceLabel;
  final String note;
  final VaccinationFacility facility;
  final List<VaccinationSlotGroup> slots;

  factory VaccinationBookingDetail.fromApi(Map<String, dynamic> json) {
    final facilityJson = json['facility'] as Map<String, dynamic>?;
    return VaccinationBookingDetail(
      serviceId: (json['serviceId'] as num?)?.toInt() ?? 0,
      serviceName: json['serviceName']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? 'TIÊM NGỪA',
      servicePriceValue: (json['servicePriceValue'] as num?)?.toInt() ?? 0,
      servicePriceLabel: json['servicePriceLabel']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      facility: VaccinationFacility.fromApi(facilityJson ?? <String, dynamic>{}),
      slots: (json['slots'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(VaccinationSlotGroup.fromApi)
              .toList() ??
          const <VaccinationSlotGroup>[],
    );
  }
}

class VaccinationPatientProfile {
  const VaccinationPatientProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.citizenId,
    required this.insuranceNumber,
    required this.email,
    required this.gender,
    required this.birthDate,
    required this.occupation,
    required this.ethnicity,
    required this.nationality,
    required this.province,
    required this.district,
    required this.ward,
    required this.addressDetail,
    required this.medicalConditions,
    required this.allergies,
    required this.emergencyContact,
    required this.relationshipToUser,
    required this.isPrimary,
  });

  final int id;
  final String fullName;
  final String? phoneNumber;
  final String? citizenId;
  final String? insuranceNumber;
  final String? email;
  final String? gender;
  final String? birthDate;
  final String? occupation;
  final String? ethnicity;
  final String? nationality;
  final String? province;
  final String? district;
  final String? ward;
  final String? addressDetail;
  final String? medicalConditions;
  final String? allergies;
  final String? emergencyContact;
  final String? relationshipToUser;
  final bool isPrimary;

  factory VaccinationPatientProfile.fromApi(Map<String, dynamic> json) {
    final rawGender = json['gender']?.toString();
    return VaccinationPatientProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      citizenId: json['citizenId']?.toString(),
      insuranceNumber: json['insuranceNumber']?.toString(),
      email: json['email']?.toString(),
      gender: rawGender == null
          ? null
          : rawGender == 'male'
              ? 'Nam'
              : rawGender == 'female'
                  ? 'Nữ'
                  : rawGender == 'other'
                      ? 'Khác'
                      : rawGender,
      birthDate: _normalizeProfileDate(json['birthDate']?.toString() ?? json['dateOfBirth']?.toString()),
      occupation: json['occupation']?.toString(),
      ethnicity: json['ethnicity']?.toString(),
      nationality: json['nationality']?.toString(),
      province: json['province']?.toString(),
      district: json['district']?.toString(),
      ward: json['ward']?.toString(),
      addressDetail: json['addressDetail']?.toString(),
      medicalConditions: json['medicalConditions']?.toString(),
      allergies: json['allergies']?.toString(),
      emergencyContact: json['emergencyContact']?.toString(),
      relationshipToUser: json['relationshipToUser']?.toString(),
      isPrimary: json['isPrimary'] == true,
    );
  }
}

class PaymentMethodOption {
  const PaymentMethodOption({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.color,
  });

  final String id;
  final String label;
  final String shortLabel;
  final Color color;
}

class VaccinationBookingDraft {
  const VaccinationBookingDraft({
    this.facilityId,
    this.facilityName,
    this.facilityAddress,
    this.serviceId,
    this.specialty = 'TIÊM NGỪA',
    this.serviceName = 'Tiêm ngừa cúm mùa',
    this.servicePriceLabel = '160.000 VND (Thanh toán tại BV)',
    this.servicePriceValue = 160000,
    this.dateLabel = '05/03/2026',
    this.slotLabel = '07:00 - 08:00',
    this.slotId,
    this.appointmentDate,
    this.appointmentTime,
    this.patientProfileId,
    this.profileLabel = 'CHƯA TỪNG KHÁM ĐĂNG KÝ MỚI',
    this.patientName = 'Nguyễn Văn A',
    this.phone = '',
    this.fullName = '',
    this.birthDate = '',
    this.gender = 'Nam',
    this.identityNumber = '',
    this.insuranceNumber = '',
    this.email = '',
    this.occupation = '',
    this.country = '',
    this.ethnicity = '',
    this.city = '',
    this.district = '',
    this.ward = '',
    this.paymentMethodId = 'vietqr',
  });

  final String? facilityId;
  final String? facilityName;
  final String? facilityAddress;
  final int? serviceId;
  final String specialty;
  final String serviceName;
  final String servicePriceLabel;
  final int servicePriceValue;
  final String dateLabel;
  final String slotLabel;
  final int? slotId;
  final String? appointmentDate;
  final String? appointmentTime;
  final int? patientProfileId;
  final String profileLabel;
  final String patientName;
  final String phone;
  final String fullName;
  final String birthDate;
  final String gender;
  final String identityNumber;
  final String insuranceNumber;
  final String email;
  final String occupation;
  final String country;
  final String ethnicity;
  final String city;
  final String district;
  final String ward;
  final String paymentMethodId;

  VaccinationBookingDraft copyWith({
    String? facilityId,
    String? facilityName,
    String? facilityAddress,
    int? serviceId,
    String? specialty,
    String? serviceName,
    String? servicePriceLabel,
    int? servicePriceValue,
    String? dateLabel,
    String? slotLabel,
    int? slotId,
    String? appointmentDate,
    String? appointmentTime,
    int? patientProfileId,
    String? profileLabel,
    String? patientName,
    String? phone,
    String? fullName,
    String? birthDate,
    String? gender,
    String? identityNumber,
    String? insuranceNumber,
    String? email,
    String? occupation,
    String? country,
    String? ethnicity,
    String? city,
    String? district,
    String? ward,
    String? paymentMethodId,
  }) {
    return VaccinationBookingDraft(
      facilityId: facilityId ?? this.facilityId,
      facilityName: facilityName ?? this.facilityName,
      facilityAddress: facilityAddress ?? this.facilityAddress,
      serviceId: serviceId ?? this.serviceId,
      specialty: specialty ?? this.specialty,
      serviceName: serviceName ?? this.serviceName,
      servicePriceLabel: servicePriceLabel ?? this.servicePriceLabel,
      servicePriceValue: servicePriceValue ?? this.servicePriceValue,
      dateLabel: dateLabel ?? this.dateLabel,
      slotLabel: slotLabel ?? this.slotLabel,
      slotId: slotId ?? this.slotId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      patientProfileId: patientProfileId ?? this.patientProfileId,
      profileLabel: profileLabel ?? this.profileLabel,
      patientName: patientName ?? this.patientName,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      identityNumber: identityNumber ?? this.identityNumber,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      email: email ?? this.email,
      occupation: occupation ?? this.occupation,
      country: country ?? this.country,
      ethnicity: ethnicity ?? this.ethnicity,
      city: city ?? this.city,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
    );
  }
}

class VaccinationBookingCatalog {
  VaccinationBookingCatalog._();

  static final DioClient _dioClient = DioClient();
  static final List<VaccinationPatientProfile> _patientProfiles = <VaccinationPatientProfile>[];
  static final List<VaccinationFacility> _facilities = <VaccinationFacility>[
    const VaccinationFacility(
      id: 'phu-san-can-tho',
      name: 'Bệnh viện Phụ sản Thành Phố Cần Thơ',
      address: '106 Cách Mạng Tháng Tám, Phường Cái Khế, TP. Cần Thơ',
      type: 'Bệnh viện',
      rating: 4.8,
      logoText: 'PS',
      logoColor: Color(0xFF5B8CFF),
    ),
    const VaccinationFacility(
      id: 'ha-noi-general',
      name: 'Bệnh viện đa khoa Hà Nội',
      address: 'Số 29 Hàn Thuyên, Hai Bà Trưng, Hà Nội',
      type: 'Bệnh viện',
      rating: 4.6,
      logoText: 'HN',
      logoColor: Color(0xFF2DC7C4),
    ),
    const VaccinationFacility(
      id: 'acc-ha-noi',
      name: 'Phòng khám ACC Hà Nội',
      address: '55 Lê Đại Hành, Hai Bà Trưng, Hà Nội',
      type: 'Phòng khám',
      rating: 4.5,
      logoText: 'ACC',
      logoColor: Color(0xFFFFB648),
    ),
    const VaccinationFacility(
      id: 'phu-san-sai-gon',
      name: 'Bệnh viện Phụ sản Quốc tế Sài Gòn',
      address: '63 Bùi Viện, Quận 1, TP.HCM',
      type: 'Bệnh viện',
      rating: 4.7,
      logoText: 'SG',
      logoColor: Color(0xFF8E7AF9),
    ),
  ];
  static final List<VaccinationPackage> _packages = <VaccinationPackage>[
    const VaccinationPackage(
      id: 'vac-viem-gan-b',
      title: 'Tiêm chủng Viêm gan siêu vi B người lớn',
      facilityId: 'ha-noi-general',
      facilityName: 'Bệnh viện đa khoa Hà Nội',
      facilityAddress: 'Số 29 Hàn Thuyên, Hai Bà Trưng, Hà Nội',
      priceLabel: 'Giá 150.000 VND',
      priceValue: 150000,
      note: 'Ghi thanh toán tại cơ sở',
      badge: 'Viêm gan',
    ),
    const VaccinationPackage(
      id: 'vac-tiem-ngua',
      title: 'Tiêm ngừa cúm mùa',
      facilityId: 'phu-san-can-tho',
      facilityName: 'Bệnh viện Phụ sản Thành Phố Cần Thơ',
      facilityAddress: '106 Cách Mạng Tháng Tám, Phường Cái Khế, TP. Cần Thơ',
      priceLabel: 'Giá 160.000 VND',
      priceValue: 160000,
      note: 'Thanh toán tại BV',
      badge: 'Tiêm chủng',
    ),
    const VaccinationPackage(
      id: 'vac-hpv',
      title: 'Gói Vaccine HPV (Gói 1)',
      facilityId: 'phu-san-sai-gon',
      facilityName: 'Bệnh viện Phụ sản Quốc tế Sài Gòn',
      facilityAddress: '63 Bùi Viện, Quận 1, TP.HCM',
      priceLabel: 'Giá 7.300.000 VND',
      priceValue: 7300000,
      note: 'Thanh toán tại cơ sở',
      badge: 'HPV',
    ),
  ];
  static const paymentMethods = <PaymentMethodOption>[
    PaymentMethodOption(
      id: 'vietqr',
      label: 'Viet QR',
      shortLabel: 'VietQR',
      color: Color(0xFF2F8CFF),
    ),
    PaymentMethodOption(
      id: 'vnpay',
      label: 'VNPAY QR',
      shortLabel: 'VNPAY',
      color: Color(0xFF2377F5),
    ),
    PaymentMethodOption(
      id: 'momo',
      label: 'Ví Momo',
      shortLabel: 'MOMO',
      color: Color(0xFFD82D8B),
    ),
  ];

  static List<VaccinationFacility> get facilities => _facilities;
  static List<VaccinationPackage> get packages => _packages;
  static List<VaccinationPatientProfile> get patientProfiles => _patientProfiles;

  static Future<void> loadRemote({bool force = false}) async {
    try {
      final [facilityResponse, packageResponse] = await Future.wait([
        _dioClient.get('/facilities/mobile'),
        _dioClient.get('/services/mobile/vaccination-packages'),
      ]);

      final facilities = _unwrapItems(facilityResponse.data)
          .whereType<Map<String, dynamic>>()
          .map(VaccinationFacility.fromApi)
          .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
          .toList();
      final packages = _unwrapItems(packageResponse.data)
          .whereType<Map<String, dynamic>>()
          .map(VaccinationPackage.fromApi)
          .where((item) => item.id.isNotEmpty && item.title.isNotEmpty)
          .toList();

      if (facilities.isNotEmpty) {
        _facilities
          ..clear()
          ..addAll(facilities);
      }
      if (packages.isNotEmpty) {
        _packages
          ..clear()
          ..addAll(packages);
      }
    } catch (_) {
      // keep demo items if the backend is unreachable
    }
  }

  static Future<void> loadPatientProfiles({bool force = false}) async {
    try {
      final response = await _dioClient.get('/patient-profiles/mobile');
      final items = _unwrapItems(response.data);
      final profiles = items
          .whereType<Map<String, dynamic>>()
          .map(VaccinationPatientProfile.fromApi)
          .toList();
      _patientProfiles
        ..clear()
        ..addAll(profiles);
    } catch (_) {
      // keep empty if backend is unavailable
    }
  }

  static Future<VaccinationBookingDetail?> loadDetail({
    required String serviceId,
    String? date,
  }) async {
    try {
      final response = await _dioClient.get(
        '/services/$serviceId/mobile-vaccination-detail',
        queryParameters: date == null ? null : {'date': date},
      );
      final data = _unwrapData(response.data);
      if (data is Map<String, dynamic>) {
        return VaccinationBookingDetail.fromApi(data);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<VaccinationPatientProfile?> createPatientProfile({
    required String fullName,
    required String phoneNumber,
    required String citizenId,
    required String insuranceNumber,
    required String email,
    required String gender,
    required String dateOfBirth,
    required String occupation,
    required String nationality,
    required String ethnicity,
    String? medicalConditions,
    String? allergies,
    required String province,
    required String district,
    required String ward,
    required String addressDetail,
    String? emergencyContact,
    String? relationshipToUser,
    bool? isPrimary,
  }) async {
    final isoDateOfBirth = _normalizeDateString(dateOfBirth);
    final payload = <String, dynamic>{
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'citizenId': citizenId,
      'insuranceNumber': insuranceNumber,
      'email': email,
      'gender': gender == 'Nam'
          ? 'male'
          : gender == 'Nữ'
              ? 'female'
              : 'other',
      'dateOfBirth': isoDateOfBirth,
      'occupation': occupation,
      'nationality': nationality,
      'ethnicity': ethnicity,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'province': province,
      'district': district,
      'ward': ward,
      'addressDetail': addressDetail,
      'emergencyContact': emergencyContact,
      'relationshipToUser': relationshipToUser,
      'isPrimary': isPrimary ?? true,
    };
    final response = await _dioClient.post(
      '/patient-profiles',
      data: payload,
    );

    final responseData = _unwrapData(response.data);
    if (responseData is Map<String, dynamic>) {
      final profile = VaccinationPatientProfile.fromApi(responseData);
      _patientProfiles.insert(0, profile);
      return profile;
    }
    return null;
  }

  static Future<VaccinationPatientProfile?> updatePatientProfile({
    required int patientId,
    required String fullName,
    required String phoneNumber,
    required String citizenId,
    required String insuranceNumber,
    required String email,
    required String gender,
    required String dateOfBirth,
    required String occupation,
    required String nationality,
    required String ethnicity,
    String? medicalConditions,
    String? allergies,
    required String province,
    required String district,
    required String ward,
    required String addressDetail,
    String? emergencyContact,
    String? relationshipToUser,
    bool? isPrimary,
  }) async {
    final isoDateOfBirth = _normalizeDateString(dateOfBirth);
    final payload = <String, dynamic>{
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'citizenId': citizenId,
      'insuranceNumber': insuranceNumber,
      'email': email,
      'gender': gender == 'Nam'
          ? 'male'
          : gender == 'Nữ'
              ? 'female'
              : 'other',
      'dateOfBirth': isoDateOfBirth,
      'occupation': occupation,
      'nationality': nationality,
      'ethnicity': ethnicity,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'province': province,
      'district': district,
      'ward': ward,
      'addressDetail': addressDetail,
      'emergencyContact': emergencyContact,
      'relationshipToUser': relationshipToUser,
    };
    if (isPrimary != null) {
      payload['isPrimary'] = isPrimary;
    }
    final response = await _dioClient.patch(
      '/patient-profiles/$patientId',
      data: payload,
    );

    final responseData = _unwrapData(response.data);
    if (responseData is Map<String, dynamic>) {
      final profile = VaccinationPatientProfile.fromApi(responseData);
      final index = _patientProfiles.indexWhere((item) => item.id == profile.id);
      if (index >= 0) {
        _patientProfiles[index] = profile;
      }
      return profile;
    }
    return null;
  }

  static Future<bool> deletePatientProfile({
    required int patientId,
  }) async {
    final response = await _dioClient.delete('/patient-profiles/$patientId');
    final data = _unwrapData(response.data);
    if (data is Map<String, dynamic>) {
      _patientProfiles.removeWhere((item) => item.id == patientId);
      return true;
    }
    return false;
  }

  static Future<Map<String, dynamic>?> createAppointment({
    required String patientId,
    required String facilityId,
    required String serviceId,
    required String slotId,
    required String appointmentDate,
    required String appointmentTime,
    required String note,
    required String symptomsNote,
  }) async {
    final response = await _dioClient.post(
      '/appointments',
      data: {
        'patientId': patientId,
        'facilityId': facilityId,
        'serviceId': serviceId,
        'slotId': slotId,
        'appointmentType': 'vaccination',
        'appointmentDate': appointmentDate,
        'appointmentTime': appointmentTime,
        'note': note,
        'symptomsNote': symptomsNote,
      },
    );

    final data = _unwrapData(response.data);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> createPayment({
    required String appointmentId,
    required String paymentMethod,
  }) async {
    final response = await _dioClient.post(
      '/payments',
      data: {
        'appointmentId': appointmentId,
        'paymentMethod': paymentMethod,
      },
    );

    final data = _unwrapData(response.data);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return null;
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

  static VaccinationFacility facilityById(String? id) {
    if (id == null || id.isEmpty) {
      return _facilities.first;
    }
    return _facilities.firstWhere(
      (facility) => facility.id == id,
      orElse: () => _facilities.first,
    );
  }

  static PaymentMethodOption paymentMethodById(String id) {
    return paymentMethods.firstWhere(
      (method) => method.id == id,
      orElse: () => paymentMethods.first,
    );
  }

  static VaccinationBookingDraft draftFromPackage(VaccinationPackage package) {
    return VaccinationBookingDraft(
      facilityId: package.facilityId,
      facilityName: package.facilityName,
      facilityAddress: package.facilityAddress,
      serviceId: int.tryParse(package.id),
      serviceName: package.title,
      servicePriceLabel: '${package.priceLabel} (${package.note})',
      servicePriceValue: package.priceValue,
    );
  }

  static VaccinationBookingDraft draftFromFacility(VaccinationFacility facility) {
    return VaccinationBookingDraft(
      facilityId: facility.id,
      facilityName: facility.name,
      facilityAddress: facility.address,
    );
  }

  static dynamic _unwrapData(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw['data'] ?? raw;
    }
    return raw;
  }

  static String? _normalizeDateString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final raw = value.trim();
    final parsedIso = DateTime.tryParse(raw);
    if (parsedIso != null) {
      return parsedIso.toIso8601String();
    }

    final parts = raw.split(RegExp(r'[/\-]')).where((part) => part.isNotEmpty).toList();
    if (parts.length == 3) {
      final first = int.tryParse(parts[0]);
      final second = int.tryParse(parts[1]);
      final third = int.tryParse(parts[2]);
      if (first != null && second != null && third != null) {
        if (parts[0].length == 4) {
          return DateTime(first, second, third).toIso8601String();
        }
        return DateTime(third, second, first).toIso8601String();
      }
    }

    return raw;
  }

  static String _logoTextFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'BV';
    if (parts.length == 1) {
      final text = parts.first.trim();
      return text.length <= 2 ? text.toUpperCase() : text.substring(0, 2).toUpperCase();
    }
    final first = parts.first.trim();
    final last = parts.last.trim();
    return '${first.substring(0, 1)}${last.substring(0, 1)}'.toUpperCase();
  }

  static Color _logoColorFromType(String type) {
    switch (type.toLowerCase()) {
      case 'bệnh viện':
        return const Color(0xFF5B8CFF);
      case 'phòng khám':
        return const Color(0xFFFFB648);
      default:
        return const Color(0xFF2DC7C4);
    }
  }
}



