import 'package:flutter/material.dart';

class ClinicDetailScreen extends StatelessWidget {
  final dynamic clinic; // Đây là "chìa khóa": Dữ liệu của đúng viện bạn vừa ấn

  const ClinicDetailScreen({super.key, required this.clinic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Tự động hiển thị Tên viện dựa trên biến 'clinic'
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF2F80ED)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      clinic['name'] ?? 'Tên bệnh viện', // HIỂN THỊ TÊN ĐỘNG
                      style: const TextStyle(
                        color: Color(0xFF2F80ED),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hiển thị Địa chỉ động
                    Text(
                      "Địa chỉ: ${clinic['address'] ?? 'Đang cập nhật'}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // HIỂN THỊ MÔ TẢ ĐỘNG (Lấy từ trường description trong DB)
                    Text(
                      clinic['description'] ?? "Thông tin chi tiết về ${clinic['name']} đang được cập nhật...",
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),

                    // Ảnh minh họa (Nếu mỗi viện có ảnh riêng thì dùng clinic['imageUrl'])
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        clinic['imageUrl'] ?? 'https://picsum.photos/seed/${clinic['id']}/600/400',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}