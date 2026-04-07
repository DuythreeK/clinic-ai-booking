class Clinic {
  final String id;
  final String name;
  final String address;
  final double rating;

  Clinic({
    required this.id,
    required this.name,
    required this.address,
    this.rating = 4.0
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      // Nếu DB chưa có rating, mặc định là 4.0 như trong ảnh
      rating: (json['rating'] ?? 4.0).toDouble(),
    );
  }
}