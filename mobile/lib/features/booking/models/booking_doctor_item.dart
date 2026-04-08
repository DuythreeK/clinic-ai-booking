class BookingDoctorItem {
  final int id;
  final String fullName;
  final String? avatarUrl;
  final String? specialtyName;
  final int? facilityId;
  final double? consultationFee;

  BookingDoctorItem({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.specialtyName,
    this.facilityId,
    this.consultationFee,
  });
}