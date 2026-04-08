import 'package:flutter/material.dart';

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
    this.specialty = 'TIÊM NGỪA',
    this.serviceName = 'Tiêm ngừa',
    this.servicePriceLabel = '160.000 VND (Thanh toán tại BV)',
    this.servicePriceValue = 160000,
    this.dateLabel = '05/03/2026',
    this.slotLabel = '07:00 - 08:00',
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
  final String specialty;
  final String serviceName;
  final String servicePriceLabel;
  final int servicePriceValue;
  final String dateLabel;
  final String slotLabel;
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
    String? specialty,
    String? serviceName,
    String? servicePriceLabel,
    int? servicePriceValue,
    String? dateLabel,
    String? slotLabel,
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
      specialty: specialty ?? this.specialty,
      serviceName: serviceName ?? this.serviceName,
      servicePriceLabel: servicePriceLabel ?? this.servicePriceLabel,
      servicePriceValue: servicePriceValue ?? this.servicePriceValue,
      dateLabel: dateLabel ?? this.dateLabel,
      slotLabel: slotLabel ?? this.slotLabel,
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

  static const facilities = <VaccinationFacility>[
    VaccinationFacility(
      id: 'phu-san-can-tho',
      name: 'Bệnh viện Phụ sản Thành Phố Cần Thơ',
      address: '106 Cách Mạng Tháng Tám, Phường Cái Khế, TP. Cần Thơ',
      type: 'Bệnh viện',
      rating: 4.8,
      logoText: 'PS',
      logoColor: Color(0xFF5B8CFF),
    ),
    VaccinationFacility(
      id: 'ha-noi-general',
      name: 'Bệnh viện đa khoa Hà Nội',
      address: 'Số 29 Hàn Thuyên, Hai Bà Trưng, Hà Nội',
      type: 'Bệnh viện',
      rating: 4.6,
      logoText: 'HN',
      logoColor: Color(0xFF2DC7C4),
    ),
    VaccinationFacility(
      id: 'acc-ha-noi',
      name: 'Phòng khám ACC Hà Nội',
      address: '55 Lê Đại Hành, Hai Bà Trưng, Hà Nội',
      type: 'Phòng khám',
      rating: 4.5,
      logoText: 'ACC',
      logoColor: Color(0xFFFFB648),
    ),
    VaccinationFacility(
      id: 'phu-san-sai-gon',
      name: 'Bệnh viện Phụ sản Quốc tế Sài Gòn',
      address: '63 Bùi Viện, Quận 1, TP.HCM',
      type: 'Bệnh viện',
      rating: 4.7,
      logoText: 'SG',
      logoColor: Color(0xFF8E7AF9),
    ),
  ];

  static const packages = <VaccinationPackage>[
    VaccinationPackage(
      id: 'vac-viem-gan-b',
      title: 'Tiêm chủng Viêm gan siêu vi B người lớn',
      facilityId: 'ha-noi-general',
      facilityName: 'Bệnh viện đa khoa Hà Nội',
      facilityAddress: 'Số 29 Hàn Thuyên, Hai Bà Trưng, Hà Nội',
      priceLabel: 'Giá 0đ',
      priceValue: 0,
      note: 'Ghi thanh toán tại cơ sở',
      badge: 'Viêm gan',
    ),
    VaccinationPackage(
      id: 'vac-tiem-ngua',
      title: 'Tiêm ngừa',
      facilityId: 'phu-san-can-tho',
      facilityName: 'Bệnh viện Phụ sản Thành Phố Cần Thơ',
      facilityAddress: '106 Cách Mạng Tháng Tám, Phường Cái Khế, TP. Cần Thơ',
      priceLabel: 'Giá 160.000 VND',
      priceValue: 160000,
      note: 'Thanh toán tại BV',
      badge: 'Tiêm chủng',
    ),
    VaccinationPackage(
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

  static VaccinationFacility facilityById(String? id) {
    return facilities.firstWhere(
      (facility) => facility.id == id,
      orElse: () => facilities.first,
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
}
