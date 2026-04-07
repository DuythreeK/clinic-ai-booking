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
      specialty: 'Tim mach',
      focus: 'Noi tim mach can thiep',
      imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=900&q=80',
      rating: 4.8,
      reviewCount: 2821,
      priceValue: 100000,
      priceLabel: '100.000d/lan',
      bookingToday: 36,
      yearsExperience: 25,
      patientsLabel: '2821 quan tam',
      nextAvailable: '10:00 AM ngay mai',
      gender: 'Male',
      email: 'paulliston@gmail.com',
      phone: '0937.444.333',
      about: 'Bac si chuyen dieu tri benh tim mach va tam soat nguy co dot quy. Lich kham trai dai o nhieu co so de phu hop lich trinh cua benh nhan.',
      certifications: [
        'MBBS - Lady Hardinge Medical College, Delhi',
        'MD (Obstetrics & Gynecology, Delhi)',
        'MRCOG (London, UK)',
        'Fellowship in ART and Reproductive Medicine (London)',
      ],
      facilities: [
        FacilityInfo(
          name: 'Phong kham Da khoa Song Xanh',
          type: 'Phong kham',
          address: '74 Nguyen Thi Minh Khai, Quan 3, TP.HCM',
        ),
        FacilityInfo(
          name: 'Benh vien Thanh Pho Thu Duc',
          type: 'Benh vien',
          address: '211 Le Van Viet, Thu Duc, TP.HCM',
        ),
      ],
      highlight: Color(0xFF2DC7C4),
    ),
    DoctorProfile(
      id: 'dr-fillerup-grab',
      name: 'Dr. Fillerup Grab',
      specialty: 'Nha si',
      focus: 'Chinh nha & phuc hinh rang',
      imageUrl: 'https://images.unsplash.com/photo-1614608682850-e0d6ed316d47?auto=format&fit=crop&w=900&q=80',
      rating: 4.7,
      reviewCount: 1944,
      priceValue: 120000,
      priceLabel: '120.000d/lan',
      bookingToday: 33,
      yearsExperience: 9,
      patientsLabel: '69 nguoi da dat hom nay',
      nextAvailable: '10:00 AM ngay mai',
      gender: 'Female',
      email: 'grab.dental@clinic.vn',
      phone: '0901.111.222',
      about: 'Bac si chuyen chinh nha tham my va dieu tri khop can. Phu hop benh nhan tre, nguoi can lich kham nhanh va linh hoat giua nhieu co so.',
      certifications: [
        'Bac si Rang Ham Mat - Dai hoc Y Duoc TP.HCM',
        'Chung chi phuc hinh rang su tham my',
        'Dao tao chinh nha trong suot Invisalign',
      ],
      facilities: [
        FacilityInfo(
          name: 'Nha khoa Blue Pearl',
          type: 'Phong kham',
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
      specialty: 'Nha si',
      focus: 'Nho rang khon & implant',
      imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=900&q=80',
      rating: 4.6,
      reviewCount: 1680,
      priceValue: 150000,
      priceLabel: '150.000d/lan',
      bookingToday: 29,
      yearsExperience: 8,
      patientsLabel: '56 lich dat trong ngay',
      nextAvailable: '10:00 AM ngay mai',
      gender: 'Female',
      email: 'balestra.implant@hospital.vn',
      phone: '0908.111.868',
      about: 'Bac si co the manh ve tieu phau rang khon va implant phuc hinh toan ham. Lich kham da co mat tai ca phong kham va benh vien.',
      certifications: [
        'Chung chi Implant Nha khoa ITI',
        'Dao tao tieu phau rang ham mat',
      ],
      facilities: [
        FacilityInfo(
          name: 'Benh vien Rang Ham Mat Trung Uong',
          type: 'Benh vien',
          address: '201A Nguyen Chi Thanh, Quan 5, TP.HCM',
        ),
      ],
      highlight: Color(0xFF4F8DFD),
    ),
    DoctorProfile(
      id: 'dr-mistry-brick',
      name: 'Dr. Mistry Brick',
      specialty: 'Nha si',
      focus: 'Dieu tri tuy & nha khoa tong quat',
      imageUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=900&q=80',
      rating: 4.3,
      reviewCount: 1208,
      priceValue: 90000,
      priceLabel: '90.000d/lan',
      bookingToday: 20,
      yearsExperience: 11,
      patientsLabel: '1208 quan tam',
      nextAvailable: '09:30 AM hom nay',
      gender: 'Male',
      email: 'brick.general@clinic.vn',
      phone: '0912.332.663',
      about: 'Bac si tong quat phu hop kham dinh ky va dieu tri tuy rang. Co lich lam viec xen ke giua phong kham va benh vien de benh nhan chu dong hon.',
      certifications: [
        'Dao tao dieu tri noi nha khoa',
        'Chung chi nha khoa ky thuat so',
      ],
      facilities: [
        FacilityInfo(
          name: 'Phong kham Nha khoa Binh An',
          type: 'Phong kham',
          address: '44 Nguyen Dinh Chieu, Quan 1, TP.HCM',
        ),
        FacilityInfo(
          name: 'Benh vien Quoc te Nam Sai Gon',
          type: 'Benh vien',
          address: '88 Nguyen Huu Tho, Quan 7, TP.HCM',
        ),
      ],
      highlight: Color(0xFFFFB648),
    ),
    DoctorProfile(
      id: 'dr-ether-wall',
      name: 'Dr. Ether Wall',
      specialty: 'Than kinh',
      focus: 'Than kinh co xuong khop',
      imageUrl: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&w=900&q=80',
      rating: 4.4,
      reviewCount: 1462,
      priceValue: 130000,
      priceLabel: '130.000d/lan',
      bookingToday: 18,
      yearsExperience: 13,
      patientsLabel: '1462 quan tam',
      nextAvailable: '02:00 PM hom nay',
      gender: 'Female',
      email: 'ether.wall@neurology.vn',
      phone: '0938.007.229',
      about: 'Bac si co kinh nghiem voi dau nua dau, roi loan giac ngu va benh ly than kinh ngoai bien. Benh nhan co the chon kham tai benh vien hoac co so ve tinh.',
      certifications: [
        'Bac si chuyen khoa II Than kinh',
        'Dao tao dien co va dien nao do',
      ],
      facilities: [
        FacilityInfo(
          name: 'Benh vien Dai hoc Y Duoc',
          type: 'Benh vien',
          address: '215 Hong Bang, Quan 5, TP.HCM',
        ),
      ],
      highlight: Color(0xFF8E7AF9),
    ),
    DoctorProfile(
      id: 'dr-johan-smith',
      name: 'Dr. Johan Smith',
      specialty: 'Tim mach',
      focus: 'Noi tim mach tong quat',
      imageUrl: 'https://images.unsplash.com/photo-1612531386530-97286d97c2d2?auto=format&fit=crop&w=900&q=80',
      rating: 4.2,
      reviewCount: 1020,
      priceValue: 95000,
      priceLabel: '95.000d/lan',
      bookingToday: 17,
      yearsExperience: 10,
      patientsLabel: '1020 quan tam',
      nextAvailable: '08:30 AM ngay mai',
      gender: 'Male',
      email: 'johan.smith@heartcare.vn',
      phone: '0907.777.224',
      about: 'Theo doi huyet ap, roi loan mo mau va tu van phong ngua benh tim mach. Lich kham tap trung vao ca sang tai cac co so gan trung tam.',
      certifications: [
        'Dao tao sieu am tim',
        'Cap cuu noi khoa tim mach',
      ],
      facilities: [
        FacilityInfo(
          name: 'Phong kham HeartCare Central',
          type: 'Phong kham',
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
