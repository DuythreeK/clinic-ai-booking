import 'package:flutter/material.dart';

class FacilityInfo {
  const FacilityInfo({
    required this.name,
    required this.type,
    required this.address,
  });

  final String name;
  final String type;
  final String address;
}

class DoctorProfile {
  const DoctorProfile({
    required this.id,
    required this.name,
    required this.specialty,
    required this.focus,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.priceValue,
    required this.priceLabel,
    required this.bookingToday,
    required this.yearsExperience,
    required this.patientsLabel,
    required this.nextAvailable,
    required this.gender,
    required this.email,
    required this.phone,
    required this.about,
    required this.certifications,
    required this.facilities,
    required this.highlight,
  });

  final String id;
  final String name;
  final String specialty;
  final String focus;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final int priceValue;
  final String priceLabel;
  final int bookingToday;
  final int yearsExperience;
  final String patientsLabel;
  final String nextAvailable;
  final String gender;
  final String email;
  final String phone;
  final String about;
  final List<String> certifications;
  final List<FacilityInfo> facilities;
  final Color highlight;
}

class DoctorCatalog extends ChangeNotifier {
  DoctorCatalog._();

  static final DoctorCatalog instance = DoctorCatalog._();

  final List<DoctorProfile> _doctors = const [
    DoctorProfile(
      id: 'dr-pediatrician',
      name: 'Dr. Pediatrician',
      specialty: 'Tim mạch',
      focus: 'Nội tim mạch can thiệp',
      imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=900&q=80',
      rating: 4.8,
      reviewCount: 2821,
      priceValue: 100000,
      priceLabel: '100.000đ/lần',
      bookingToday: 36,
      yearsExperience: 25,
      patientsLabel: '2821 quan tâm',
      nextAvailable: '10:00 AM ngày mai',
      gender: 'Male',
      email: 'paulliston@gmail.com',
      phone: '0937.444.333',
      about: 'Bác sĩ chuyên điều trị bệnh tim mạch và tầm soát nguy cơ đột quỵ. Lịch khám trải dài ở nhiều cơ sở để phù hợp lịch trình của bệnh nhân.',
      certifications: [
        'MBBS - Lady Hardinge Medical College, Delhi',
        'MD (Obstetrics & Gynecology, Delhi)',
        'MRCOG (London, UK)',
        'Fellowship in ART and Reproductive Medicine (London)',
      ],
      facilities: [
        FacilityInfo(
          name: 'Phòng khám Đa khoa Sông Xanh',
          type: 'Phòng khám',
          address: '74 Nguyen Thi Minh Khai, Quan 3, TP.HCM',
        ),
        FacilityInfo(
          name: 'Bệnh viện Thành Phố Thủ Đức',
          type: 'Bệnh viện',
          address: '211 Le Van Viet, Thu Duc, TP.HCM',
        ),
      ],
      highlight: Color(0xFF2DC7C4),
    ),
    DoctorProfile(
      id: 'dr-fillerup-grab',
      name: 'Dr. Fillerup Grab',
      specialty: 'Nha sĩ',
      focus: 'Chỉnh nha & phục hình răng',
      imageUrl: 'https://images.unsplash.com/photo-1614608682850-e0d6ed316d47?auto=format&fit=crop&w=900&q=80',
      rating: 4.7,
      reviewCount: 1944,
      priceValue: 120000,
      priceLabel: '120.000đ/lần',
      bookingToday: 33,
      yearsExperience: 9,
      patientsLabel: '69 người đã đặt hôm nay',
      nextAvailable: '10:00 AM ngày mai',
      gender: 'Female',
      email: 'grab.dental@clinic.vn',
      phone: '0901.111.222',
      about: 'Bác sĩ chuyên chỉnh nha thẩm mỹ và điều trị khớp cắn. Phù hợp bệnh nhân trẻ, người cần lịch khám nhanh và linh hoạt giữa nhiều cơ sở.',
      certifications: [
        'Bác sĩ Răng Hàm Mặt - Đại học Y Dược TP.HCM',
        'Chung chi phuc hinh rang su tham my',
        'Dao tao chinh nha trong suot Invisalign',
      ],
      facilities: [
        FacilityInfo(
          name: 'Nha khoa Blue Pearl',
          type: 'Phòng khám',
          address: '25 Tran Quoc Thao, Quan 3, TP.HCM',
        ),
        FacilityInfo(
          name: 'Trung tam Rang Ham Mat Sai Gon',
          type: 'Trung tam',
          address: '138 Cach Mang Thang 8, Quan 10, TP.HCM',
        ),
      ],
      highlight: Color(0xFF28C76F),
    ),
    DoctorProfile(
      id: 'dr-balestra',
      name: 'Dr. Balestra',
      specialty: 'Nha sĩ',
      focus: 'Nhổ răng khôn & implant',
      imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=900&q=80',
      rating: 4.6,
      reviewCount: 1680,
      priceValue: 150000,
      priceLabel: '150.000đ/lần',
      bookingToday: 29,
      yearsExperience: 8,
      patientsLabel: '56 lịch đặt trong ngày',
      nextAvailable: '10:00 AM ngày mai',
      gender: 'Female',
      email: 'balestra.implant@hospital.vn',
      phone: '0908.111.868',
      about: 'Bác sĩ có thế mạnh về tiểu phẫu răng khôn và implant phục hình toàn hàm. Lịch khám đã có mặt tại cả phòng khám và bệnh viện.',
      certifications: [
        'Chung chi Implant Nha khoa ITI',
        'Dao tao tieu phau rang ham mat',
      ],
      facilities: [
        FacilityInfo(
          name: 'Bệnh viện Răng Hàm Mặt Trung Ương',
          type: 'Bệnh viện',
          address: '201A Nguyen Chi Thanh, Quan 5, TP.HCM',
        ),
      ],
      highlight: Color(0xFF4F8DFD),
    ),
    DoctorProfile(
      id: 'dr-mistry-brick',
      name: 'Dr. Mistry Brick',
      specialty: 'Nha sĩ',
      focus: 'Điều trị tủy & nha khoa tổng quát',
      imageUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=900&q=80',
      rating: 4.3,
      reviewCount: 1208,
      priceValue: 90000,
      priceLabel: '90.000đ/lần',
      bookingToday: 20,
      yearsExperience: 11,
      patientsLabel: '1208 quan tâm',
      nextAvailable: '09:30 AM hôm nay',
      gender: 'Male',
      email: 'brick.general@clinic.vn',
      phone: '0912.332.663',
      about: 'Bác sĩ tổng quát phù hợp khám định kỳ và điều trị tủy răng. Có lịch làm việc xen kẽ giữa phòng khám và bệnh viện để bệnh nhân chủ động hơn.',
      certifications: [
        'Dao tao dieu tri noi nha khoa',
        'Chung chi nha khoa ky thuat so',
      ],
      facilities: [
        FacilityInfo(
          name: 'Phòng khám Nha khoa Bình An',
          type: 'Phòng khám',
          address: '44 Nguyen Dinh Chieu, Quan 1, TP.HCM',
        ),
        FacilityInfo(
          name: 'Bệnh viện Quốc tế Nam Sài Gòn',
          type: 'Bệnh viện',
          address: '88 Nguyen Huu Tho, Quan 7, TP.HCM',
        ),
      ],
      highlight: Color(0xFFFFB648),
    ),
    DoctorProfile(
      id: 'dr-ether-wall',
      name: 'Dr. Ether Wall',
      specialty: 'Thần kinh',
      focus: 'Thần kinh cơ xương khớp',
      imageUrl: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&w=900&q=80',
      rating: 4.4,
      reviewCount: 1462,
      priceValue: 130000,
      priceLabel: '130.000đ/lần',
      bookingToday: 18,
      yearsExperience: 13,
      patientsLabel: '1462 quan tâm',
      nextAvailable: '02:00 PM hôm nay',
      gender: 'Female',
      email: 'ether.wall@neurology.vn',
      phone: '0938.007.229',
      about: 'Bác sĩ có kinh nghiệm với đau nửa đầu, rối loạn giấc ngủ và bệnh lý thần kinh ngoại biên. Bệnh nhân có thể chọn khám tại bệnh viện hoặc cơ sở vệ tinh.',
      certifications: [
        'Bác sĩ chuyên khoa II Thần kinh',
        'Dao tao dien co va dien nao do',
      ],
      facilities: [
        FacilityInfo(
          name: 'Bệnh viện Đại học Y Dược',
          type: 'Bệnh viện',
          address: '215 Hong Bang, Quan 5, TP.HCM',
        ),
      ],
      highlight: Color(0xFF8E7AF9),
    ),
    DoctorProfile(
      id: 'dr-johan-smith',
      name: 'Dr. Johan Smith',
      specialty: 'Tim mạch',
      focus: 'Nội tim mạch tổng quát',
      imageUrl: 'https://images.unsplash.com/photo-1612531386530-97286d97c2d2?auto=format&fit=crop&w=900&q=80',
      rating: 4.2,
      reviewCount: 1020,
      priceValue: 95000,
      priceLabel: '95.000đ/lần',
      bookingToday: 17,
      yearsExperience: 10,
      patientsLabel: '1020 quan tâm',
      nextAvailable: '08:30 AM ngày mai',
      gender: 'Male',
      email: 'johan.smith@heartcare.vn',
      phone: '0907.777.224',
      about: 'Theo dõi huyết áp, rối loạn mỡ máu và tư vấn phòng ngừa bệnh tim mạch. Lịch khám tập trung vào ca sáng tại các cơ sở gần trung tâm.',
      certifications: [
        'Dao tao sieu am tim',
        'Cap cuu noi khoa tim mach',
      ],
      facilities: [
        FacilityInfo(
          name: 'Phòng khám HeartCare Central',
          type: 'Phòng khám',
          address: '65 Pasteur, Quan 1, TP.HCM',
        ),
      ],
      highlight: Color(0xFF2DC7C4),
    ),
  ];

  final Set<String> _favoriteIds = <String>{
    'dr-pediatrician',
    'dr-fillerup-grab',
    'dr-mistry-brick',
    'dr-ether-wall',
    'dr-johan-smith',
  };

  List<DoctorProfile> get featuredDoctors {
    final result = [..._doctors];
    result.sort((a, b) => b.bookingToday.compareTo(a.bookingToday));
    return result;
  }

  List<DoctorProfile> get myDoctors =>
      _doctors.where((doctor) => _favoriteIds.contains(doctor.id)).toList();

  DoctorProfile? findById(String id) {
    for (final doctor in _doctors) {
      if (doctor.id == id) {
        return doctor;
      }
    }
    return null;
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void toggleFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
  }
}
