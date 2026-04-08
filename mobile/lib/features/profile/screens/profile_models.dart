import 'package:flutter/material.dart';

import '../../../core/api/dio_client.dart';

class MobileProfile {
  const MobileProfile({
    required this.userId,
    required this.profileId,
    required this.ecoreId,
    required this.username,
    required this.full_name,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.gender,
    required this.city,
    required this.district,
    required this.ward,
    required this.address,
    required this.occupation,
    required this.emergencyContact,
    required this.citizenId,
    required this.nationality,
    required this.ethnicity,
    required this.relationshipToUser,
    required this.avatarUrl,
  });

  final int userId;
  final int? profileId;
  final String ecoreId;
  final String username;
  final String full_name;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? dateOfBirth;
  final String? gender;
  final String? city;
  final String? district;
  final String? ward;
  final String? address;
  final String? occupation;
  final String? emergencyContact;
  final String? citizenId;
  final String? nationality;
  final String? ethnicity;
  final String? relationshipToUser;
  final String? avatarUrl;

  factory MobileProfile.fromApi(Map<String, dynamic> json) {
    final full_name = json['full_name']?.toString() ?? '';
    final split = _splitName(full_name);
    return MobileProfile(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      profileId: (json['profileId'] as num?)?.toInt(),
      ecoreId: json['ecoreId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      full_name: full_name,
      firstName: json['firstName']?.toString() ?? split.first,
      lastName: json['lastName']?.toString() ?? split.last,
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      dateOfBirth: json['dateOfBirth']?.toString(),
      gender: json['gender']?.toString(),
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      ward: json['ward']?.toString(),
      address: json['address']?.toString(),
      occupation: json['occupation']?.toString(),
      emergencyContact: json['emergencyContact']?.toString(),
      citizenId: json['citizenId']?.toString(),
      nationality: json['nationality']?.toString(),
      ethnicity: json['ethnicity']?.toString(),
      relationshipToUser: json['relationshipToUser']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  MobileProfile copyWith({
    String? full_name,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? occupation,
    String? nationality,
    String? ethnicity,
    String? city,
    String? district,
    String? ward,
    String? address,
    String? emergencyContact,
    String? relationshipToUser,
    String? avatarUrl,
  }) {
    final updatedName = full_name ?? this.full_name;
    final split = _splitName(updatedName);
    return MobileProfile(
      userId: userId,
      profileId: profileId,
      ecoreId: ecoreId,
      username: username,
      full_name: updatedName,
      firstName: split.first,
      lastName: split.last,
      email: email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      address: address ?? this.address,
      occupation: occupation ?? this.occupation,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      citizenId: citizenId,
      nationality: nationality ?? this.nationality,
      ethnicity: ethnicity ?? this.ethnicity,
      relationshipToUser: relationshipToUser ?? this.relationshipToUser,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class ProfileCatalog extends ChangeNotifier {
  ProfileCatalog._();

  static final ProfileCatalog instance = ProfileCatalog._();

  final DioClient _dio = DioClient();
  MobileProfile? _profile;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  MobileProfile? get profile => _profile;
  bool get isLoading => _loading;
  bool get isSaving => _saving;
  String? get error => _error;

  Future<void> loadRemote({bool force = false}) async {
    if (_loading) return;
    if (!force && _profile != null) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dio.get('/users/me/profile');
      final data = _unwrapData(response.data);
      if (data is Map<String, dynamic>) {
        _profile = MobileProfile.fromApi(data);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<MobileProfile?> saveRemote(Map<String, dynamic> payload) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dio.patch('/users/me/profile', data: payload);
      final data = _unwrapData(response.data);
      if (data is Map<String, dynamic>) {
        _profile = MobileProfile.fromApi(data);
      }
      return _profile;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  dynamic _unwrapData(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw['data'] ?? raw;
    }
    return raw;
  }
}

class _NameParts {
  const _NameParts({required this.first, required this.last});

  final String first;
  final String last;
}

_NameParts _splitName(String full_name) {
  final parts = full_name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return const _NameParts(first: '', last: '');
  }
  if (parts.length == 1) {
    return _NameParts(first: parts.first, last: '');
  }
  final first = parts.take(parts.length - 1).join(' ');
  final last = parts.last;
  return _NameParts(first: first, last: last);
}
