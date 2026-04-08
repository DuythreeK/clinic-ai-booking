import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/storage/auth_storage.dart';

class FacilityInfo {
  const FacilityInfo({
    required this.name,
    required this.type,
    required this.address,
  });

  final String name;
  final String type;
  final String address;

  factory FacilityInfo.fromApi(Map<String, dynamic> json) {
    return FacilityInfo(
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
    );
  }
}

class SpecialtyChoice {
  const SpecialtyChoice({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  factory SpecialtyChoice.fromApi(Map<String, dynamic> json) {
    return SpecialtyChoice(
      id: json['id']?.toString() ?? json['specialty_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
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
  final String? email;
  final String? phone;
  final String about;
  final List<String> certifications;
  final List<FacilityInfo> facilities;
  final Color highlight;

  factory DoctorProfile.fromApi(Map<String, dynamic> json) {
    final facility = json['facility'] as Map<String, dynamic>?;
    final specialtyRaw = json['specialty'];
    final specialtyName = specialtyRaw is Map<String, dynamic>
        ? specialtyRaw['name']?.toString()
        : specialtyRaw?.toString();
    final priceValue = (json['priceValue'] as num?)?.toInt() ?? 0;
    final bookingToday = (json['bookingToday'] as num?)?.toInt() ?? 0;
    final reviewCount = (json['reviewCount'] as num?)?.toInt() ?? 0;
    final rating = (json['rating'] as num?)?.toDouble() ?? 0;
    final yearsExperience = (json['yearsExperience'] as num?)?.toInt() ?? 0;

    return DoctorProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      specialty: specialtyName ?? 'Chưa cập nhật',
      focus: json['focus']?.toString() ?? json['title']?.toString() ?? 'Khám tổng quát',
      imageUrl: json['imageUrl']?.toString() ?? '',
      rating: rating,
      reviewCount: reviewCount,
      priceValue: priceValue,
      priceLabel: json['priceLabel']?.toString() ?? '${priceValue.toString()}đ/lần',
      bookingToday: bookingToday,
      yearsExperience: yearsExperience,
      patientsLabel: json['patientsLabel']?.toString() ?? '$bookingToday người đã đặt hôm nay',
      nextAvailable: json['nextAvailable']?.toString() ?? 'Chưa có lịch',
      gender: json['gender']?.toString() ?? 'Không rõ',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      about: json['about']?.toString() ?? '',
      certifications: (json['certifications'] as List?)?.whereType<String>().toList() ?? const <String>[],
      facilities: facility == null ? const <FacilityInfo>[] : [FacilityInfo.fromApi(facility)],
      highlight: _highlightFromSpecialty(specialtyName),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'specialty': specialty,
      'focus': focus,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'priceValue': priceValue,
      'priceLabel': priceLabel,
      'bookingToday': bookingToday,
      'yearsExperience': yearsExperience,
      'patientsLabel': patientsLabel,
      'nextAvailable': nextAvailable,
      'gender': gender,
      'email': email,
      'phone': phone,
      'about': about,
      'certifications': certifications,
      'facility': facilities.isEmpty
          ? null
          : <String, dynamic>{
              'name': facilities.first.name,
              'type': facilities.first.type,
              'address': facilities.first.address,
            },
    };
  }

  static Color _highlightFromSpecialty(String? specialty) {
    switch ((specialty ?? '').toLowerCase()) {
      case 'tim mạch':
        return const Color(0xFF2DC7C4);
      case 'nha sĩ':
        return const Color(0xFFFFB648);
      case 'thần kinh':
        return const Color(0xFF8E7AF9);
      case 'da liễu':
        return const Color(0xFFFF8C68);
      case 'nhi khoa':
        return const Color(0xFF4F8DFD);
      case 'tiêm chủng':
        return const Color(0xFF20C8C2);
      default:
        return const Color(0xFF20C8C2);
    }
  }
}

class DoctorCatalog extends ChangeNotifier {
  DoctorCatalog._();

  static final DoctorCatalog instance = DoctorCatalog._();

  static const String _favoriteStorageKey = 'favorite_doctor_profiles';

  final DioClient _dioClient = DioClient();
  final Set<String> _favoriteIds = <String>{};
  final Map<String, DoctorProfile> _favoriteProfiles = <String, DoctorProfile>{};
  List<DoctorProfile> _doctors = <DoctorProfile>[];
  bool _loading = false;
  String? _featuredError;

  bool get isLoading => _loading;
  String? get featuredError => _featuredError;

  Future<void> loadRemote({bool force = false}) async {
    if (_loading) return;
    if (!force && _doctors.isNotEmpty) return;

    _loading = true;
    _featuredError = null;
    notifyListeners();

    await _loadFavoriteProfilesFromStorage();

    try {
      final featured = await _fetchDoctors('/doctors/mobile/featured?limit=50');
      _doctors = featured;
      await _reconcileFavoriteProfiles(featured);
    } on DioException catch (e) {
      _featuredError = 'Không tải được “Bác sĩ nổi bật”${e.response?.statusCode == null ? '' : ' (' + e.response!.statusCode.toString() + ')'}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<DoctorProfile>> _fetchDoctors(String path) async {
    final response = await _dioClient.get(path);
    final items = _unwrapItems(response.data);
    return items
        .whereType<Map<String, dynamic>>()
        .map(DoctorProfile.fromApi)
        .where((doctor) => doctor.id.isNotEmpty && doctor.name.isNotEmpty)
        .toList();
  }

  List<dynamic> _unwrapItems(dynamic data) {
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

  List<DoctorProfile> get featuredDoctors {
    final result = [..._doctors];
    result.sort((a, b) => b.bookingToday.compareTo(a.bookingToday));
    return result;
  }

  List<DoctorProfile> get myDoctors {
    final result = _favoriteProfiles.values.toList();
    result.sort((a, b) => b.rating.compareTo(a.rating));
    return result;
  }

  DoctorProfile? findById(String id) {
    for (final doctor in _doctors) {
      if (doctor.id == id) {
        return doctor;
      }
    }
    final favorite = _favoriteProfiles[id];
    if (favorite != null) {
      return favorite;
    }
    return null;
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  Future<void> toggleFavorite(DoctorProfile doctor) async {
    if (_favoriteIds.contains(doctor.id)) {
      _favoriteIds.remove(doctor.id);
      _favoriteProfiles.remove(doctor.id);
    } else {
      _favoriteIds.add(doctor.id);
      _favoriteProfiles[doctor.id] = doctor;
    }
    await _saveFavoriteProfilesToStorage();
    notifyListeners();
  }

  Future<void> _loadFavoriteProfilesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_favoriteStorageKey) ?? <String>[];
    _favoriteIds.clear();
    _favoriteProfiles.clear();

    for (final encoded in stored) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is Map<String, dynamic>) {
          final doctor = DoctorProfile.fromApi(decoded);
          if (doctor.id.isNotEmpty) {
            _favoriteIds.add(doctor.id);
            _favoriteProfiles[doctor.id] = doctor;
          }
        }
      } catch (_) {
        // Ignore malformed favorites.
      }
    }
  }

  Future<void> _saveFavoriteProfilesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _favoriteProfiles.values.map((doctor) => jsonEncode(doctor.toJson())).toList();
    await prefs.setStringList(_favoriteStorageKey, encoded);
  }

  Future<void> _reconcileFavoriteProfiles(List<DoctorProfile> latestDoctors) async {
    final latestById = <String, DoctorProfile>{
      for (final doctor in latestDoctors) doctor.id: doctor,
    };
    var updated = false;
    for (final id in _favoriteIds) {
      final latest = latestById[id];
      if (latest != null) {
        _favoriteProfiles[id] = latest;
        updated = true;
      }
    }
    if (updated) {
      await _saveFavoriteProfilesToStorage();
    }
  }
}

class SpecialtyCatalog extends ChangeNotifier {
  SpecialtyCatalog._();

  static final SpecialtyCatalog instance = SpecialtyCatalog._();

  final DioClient _dioClient = DioClient();
  List<SpecialtyChoice> _specialties = <SpecialtyChoice>[];
  bool _loading = false;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;
  List<SpecialtyChoice> get specialties => _specialties;

  Future<void> loadRemote({bool force = false}) async {
    if (_loading) return;
    if (!force && _specialties.isNotEmpty) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dioClient.get('/specialties');
      final items = _unwrapItems(response.data)
          .whereType<Map<String, dynamic>>()
          .map(SpecialtyChoice.fromApi)
          .where((specialty) => specialty.id.isNotEmpty && specialty.name.isNotEmpty)
          .toList();
      _specialties = items;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<dynamic> _unwrapItems(dynamic data) {
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
}



