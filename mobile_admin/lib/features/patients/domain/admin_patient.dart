class AdminPatient {
  const AdminPatient({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.allergies,
    required this.bloodType,
    required this.insuranceNumber,
    required this.address,
    required this.gender,
    required this.isActive,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? allergies;
  final String? bloodType;
  final String? insuranceNumber;
  final String? address;
  final String? gender;
  final bool isActive;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'BN';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  List<String> get allergyItems {
    final raw = allergies?.trim() ?? '';
    if (raw.isEmpty) {
      return const [];
    }

    return raw
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  factory AdminPatient.fromJson(Map<String, dynamic> json) {
    return AdminPatient(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Chưa rõ bệnh nhân',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      allergies: json['allergies']?.toString(),
      bloodType: json['bloodType']?.toString(),
      insuranceNumber: json['insuranceNumber']?.toString(),
      address: json['address']?.toString(),
      gender: json['gender']?.toString(),
      isActive: json['isActive'] == true,
    );
  }
}

class AdminPatientsPage {
  const AdminPatientsPage({required this.items, required this.total});

  final List<AdminPatient> items;
  final int total;
}

class AdminMedicationItem {
  const AdminMedicationItem({required this.name, required this.dosage});

  final String name;
  final String dosage;
}

class AdminHistoryItem {
  const AdminHistoryItem({required this.label});

  final String label;
}

class AdminPatientProfile {
  const AdminPatientProfile({
    required this.patient,
    required this.medications,
    required this.history,
  });

  final AdminPatient patient;
  final List<AdminMedicationItem> medications;
  final List<AdminHistoryItem> history;
}
