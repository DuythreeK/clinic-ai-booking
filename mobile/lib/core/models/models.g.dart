// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      role: json['role'] as String,
      is_active: json['is_active'] as bool,
      created_at: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'phone': instance.phone,
      'avatar': instance.avatar,
      'role': instance.role,
      'is_active': instance.is_active,
      'created_at': instance.created_at.toIso8601String(),
    };

Doctor _$DoctorFromJson(Map<String, dynamic> json) => Doctor(
      id: json['id'] as String,
      user_id: json['user_id'] as String,
      licenseNumber: json['licenseNumber'] as String,
      specialtyId: json['specialtyId'] as String?,
      isApproved: json['isApproved'] as bool,
      bio: json['bio'] as String?,
      yearsExperience: (json['yearsExperience'] as num).toInt(),
      rating: (json['rating'] as num).toDouble(),
      totalReviews: (json['totalReviews'] as num).toInt(),
      created_at: DateTime.parse(json['created_at'] as String),
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
      specialty: json['specialty'] == null
          ? null
          : Specialty.fromJson(json['specialty'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DoctorToJson(Doctor instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.user_id,
      'licenseNumber': instance.licenseNumber,
      'specialtyId': instance.specialtyId,
      'isApproved': instance.isApproved,
      'bio': instance.bio,
      'yearsExperience': instance.yearsExperience,
      'rating': instance.rating,
      'totalReviews': instance.totalReviews,
      'created_at': instance.created_at.toIso8601String(),
      'user': instance.user,
      'specialty': instance.specialty,
    };

Specialty _$SpecialtyFromJson(Map<String, dynamic> json) => Specialty(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$SpecialtyToJson(Specialty instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
    };

Clinic _$ClinicFromJson(Map<String, dynamic> json) => Clinic(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$ClinicToJson(Clinic instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'city': instance.city,
      'country': instance.country,
      'phone': instance.phone,
      'email': instance.email,
    };

Slot _$SlotFromJson(Map<String, dynamic> json) => Slot(
      id: json['id'] as String,
      doctor_id: json['doctor_id'] as String,
      clinicId: json['clinicId'] as String,
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      isBlocked: json['isBlocked'] as bool,
      doctor: json['doctor'] == null
          ? null
          : Doctor.fromJson(json['doctor'] as Map<String, dynamic>),
      clinic: json['clinic'] == null
          ? null
          : Clinic.fromJson(json['clinic'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SlotToJson(Slot instance) => <String, dynamic>{
      'id': instance.id,
      'doctor_id': instance.doctor_id,
      'clinicId': instance.clinicId,
      'startAt': instance.startAt.toIso8601String(),
      'endAt': instance.endAt.toIso8601String(),
      'isBlocked': instance.isBlocked,
      'doctor': instance.doctor,
      'clinic': instance.clinic,
    };

Appointment _$AppointmentFromJson(Map<String, dynamic> json) => Appointment(
      id: json['id'] as String,
      patient_id: json['patient_id'] as String,
      doctor_id: json['doctor_id'] as String,
      slot_id: json['slot_id'] as String,
      status: json['status'] as String,
      reason: json['reason'] as String,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      doctorNotes: json['doctorNotes'] as String?,
      rescheduledFromId: json['rescheduledFromId'] as String?,
      created_at: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      patient: json['patient'] == null
          ? null
          : User.fromJson(json['patient'] as Map<String, dynamic>),
      doctor: json['doctor'] == null
          ? null
          : Doctor.fromJson(json['doctor'] as Map<String, dynamic>),
      slot: json['slot'] == null
          ? null
          : Slot.fromJson(json['slot'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppointmentToJson(Appointment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patient_id,
      'doctor_id': instance.doctor_id,
      'slot_id': instance.slot_id,
      'status': instance.status,
      'reason': instance.reason,
      'attachments': instance.attachments,
      'doctorNotes': instance.doctorNotes,
      'rescheduledFromId': instance.rescheduledFromId,
      'created_at': instance.created_at.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'patient': instance.patient,
      'doctor': instance.doctor,
      'slot': instance.slot,
    };

PatientProfile _$PatientProfileFromJson(Map<String, dynamic> json) =>
    PatientProfile(
      id: json['id'] as String,
      user_id: json['user_id'] as String,
      dateOfBirth: json['dateOfBirth'] == null
          ? null
          : DateTime.parse(json['dateOfBirth'] as String),
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      emergencyPhone: json['emergencyPhone'] as String?,
      medicalHistory: json['medicalHistory'] as String?,
      allergies: json['allergies'] as String?,
      currentMedications: json['currentMedications'] as String?,
    );

Map<String, dynamic> _$PatientProfileToJson(PatientProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.user_id,
      'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
      'gender': instance.gender,
      'address': instance.address,
      'city': instance.city,
      'country': instance.country,
      'emergencyPhone': instance.emergencyPhone,
      'medicalHistory': instance.medicalHistory,
      'allergies': instance.allergies,
      'currentMedications': instance.currentMedications,
    };

TriageResult _$TriageResultFromJson(Map<String, dynamic> json) => TriageResult(
      recommendedSpecialties: (json['recommendedSpecialties'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      urgencyLevel: json['urgencyLevel'] as String,
      followUpQuestions: (json['followUpQuestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      disclaimer: json['disclaimer'] as String,
    );

Map<String, dynamic> _$TriageResultToJson(TriageResult instance) =>
    <String, dynamic>{
      'recommendedSpecialties': instance.recommendedSpecialties,
      'urgencyLevel': instance.urgencyLevel,
      'followUpQuestions': instance.followUpQuestions,
      'disclaimer': instance.disclaimer,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
    };
