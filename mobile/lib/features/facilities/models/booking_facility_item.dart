class BookingFacilityItem {
  const BookingFacilityItem({
    required this.id,
    required this.name,
    this.type,
    this.address,
  });

  final int id;
  final String name;
  final String? type;
  final String? address;
}
