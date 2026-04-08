// Models for API responses
import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

// User Model
@JsonSerializable()
class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatar;
  final String role;
  final bool is_active;
  final DateTime created_at;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatar,
    required this.role,
    required this.is_active,
    required this.created_at,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  String get full_name => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}

// Doctor Model
@JsonSerializable()
class Doctor {
  final String id;
  final String user_id;
  final String licenseNumber;
  final String? specialtyId;
  final bool isApproved;
  final String? bio;
  final int yearsExperience;
  final double rating;
  final int totalReviews;
  final DateTime created_at;
  final User? user;
  final Specialty? specialty;

  Doctor({
    required this.id,
    required this.user_id,
    required this.licenseNumber,
    this.specialtyId,
    required this.isApproved,
    this.bio,
    required this.yearsExperience,
    required this.rating,
    required this.totalReviews,
    required this.created_at,
    this.user,
    this.specialty,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) => _$DoctorFromJson(json);
  Map<String, dynamic> toJson() => _$DoctorToJson(this);
}

// Specialty Model
@JsonSerializable()
class Specialty {
  final String id;
  final String name;
  final String? description;
  final String? icon;

  Specialty({
    required this.id,
    required this.name,
    this.description,
    this.icon,
  });

  factory Specialty.fromJson(Map<String, dynamic> json) => _$SpecialtyFromJson(json);
  Map<String, dynamic> toJson() => _$SpecialtyToJson(this);
}

// Clinic Model
@JsonSerializable()
class Clinic {
  final String id;
  final String name;
  final String address;
  final String city;
  final String country;
  final String phone;
  final String email;

  Clinic({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.country,
    required this.phone,
    required this.email,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) => _$ClinicFromJson(json);
  Map<String, dynamic> toJson() => _$ClinicToJson(this);
}

// Slot Model
@JsonSerializable()
class Slot {
  final String id;
  final String doctor_id;
  final String clinicId;
  final DateTime startAt;
  final DateTime endAt;
  final bool isBlocked;
  final Doctor? doctor;
  final Clinic? clinic;

  Slot({
    required this.id,
    required this.doctor_id,
    required this.clinicId,
    required this.startAt,
    required this.endAt,
    required this.isBlocked,
    this.doctor,
    this.clinic,
  });

  factory Slot.fromJson(Map<String, dynamic> json) => _$SlotFromJson(json);
  Map<String, dynamic> toJson() => _$SlotToJson(this);
}

// Appointment Model
@JsonSerializable()
class Appointment {
  final String id;
  final String patient_id;
  final String doctor_id;
  final String slot_id;
  final String status;
  final String reason;
  final List<String>? attachments;
  final String? doctorNotes;
  final String? rescheduledFromId;
  final DateTime created_at;
  final DateTime updatedAt;
  final User? patient;
  final Doctor? doctor;
  final Slot? slot;

  Appointment({
    required this.id,
    required this.patient_id,
    required this.doctor_id,
    required this.slot_id,
    required this.status,
    required this.reason,
    this.attachments,
    this.doctorNotes,
    this.rescheduledFromId,
    required this.created_at,
    required this.updatedAt,
    this.patient,
    this.doctor,
    this.slot,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => _$AppointmentFromJson(json);
  Map<String, dynamic> toJson() => _$AppointmentToJson(this);

  bool get isPending => status == 'PENDING';
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isNoShow => status == 'NO_SHOW';
}

// Patient Profile Model
@JsonSerializable()
class PatientProfile {
  final String id;
  final String user_id;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final String? country;
  final String? emergencyPhone;
  final String? medicalHistory;
  final String? allergies;
  final String? currentMedications;

  PatientProfile({
    required this.id,
    required this.user_id,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.country,
    this.emergencyPhone,
    this.medicalHistory,
    this.allergies,
    this.currentMedications,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) => _$PatientProfileFromJson(json);
  Map<String, dynamic> toJson() => _$PatientProfileToJson(this);
}

// Triage Result Model
@JsonSerializable()
class TriageResult {
  final List<String> recommendedSpecialties;
  final String urgencyLevel;
  final List<String> followUpQuestions;
  final String disclaimer;

  TriageResult({
    required this.recommendedSpecialties,
    required this.urgencyLevel,
    required this.followUpQuestions,
    required this.disclaimer,
  });

  factory TriageResult.fromJson(Map<String, dynamic> json) => _$TriageResultFromJson(json);
  Map<String, dynamic> toJson() => _$TriageResultToJson(this);
}

// Auth Response Model
@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
