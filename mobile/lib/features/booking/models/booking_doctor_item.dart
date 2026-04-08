class BookingDoctorItem {
  final int id;
  final String full_name;
  final String? avatarUrl;
  final String? specialtyName;
  final int? facility_id;
  final double? consultationFee;

  BookingDoctorItem({
    required this.id,
    required this.full_name,
    this.avatarUrl,
    this.specialtyName,
    this.facility_id,
    this.consultationFee,
  });
}