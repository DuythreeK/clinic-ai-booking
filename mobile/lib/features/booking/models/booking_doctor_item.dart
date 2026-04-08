class BookingDoctorItem {
  final int id;
  final String fullName;
  final String? specialtyName;
  final int? facilityId;
  final double? consultationFee;

  BookingDoctorItem({
    required this.id,
    required this.fullName,
    this.specialtyName,
    this.facilityId,
    this.consultationFee,
  });
}