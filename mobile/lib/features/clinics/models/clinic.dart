/// Model dữ liệu phòng khám/cơ sở y tế.
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

  /// Tạo model từ JSON trả về từ backend.
  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      // Nếu backend chưa có rating thì dùng giá trị mặc định.
      rating: (json['rating'] ?? 4.0).toDouble(),
    );
  }
}