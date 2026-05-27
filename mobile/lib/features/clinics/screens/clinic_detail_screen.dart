import 'package:flutter/material.dart';

/// Màn hiển thị thông tin chi tiết của một cơ sở/phòng khám.
class ClinicDetailScreen extends StatelessWidget {
  /// Dữ liệu phòng khám được truyền từ màn danh sách qua `go_router`.
  final Map<String, dynamic> clinic;

  const ClinicDetailScreen({super.key, required this.clinic});

  @override
  Widget build(BuildContext context) {
    // Chuẩn hoá dữ liệu hiển thị, có fallback nếu backend trả thiếu.
    final clinicName = (clinic['name'] ?? 'Tên bệnh viện').toString();
    final clinicAddress = (clinic['address'] ?? clinic['addressDetail'] ?? 'Đang cập nhật').toString();
    final clinicDescription = (clinic['description'] ?? 'Thông tin chi tiết về $clinicName đang được cập nhật...').toString();
    final clinicImageUrl = (clinic['imageUrl'] ?? 'https://picsum.photos/seed/${clinic['id']}/600/400').toString();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header hiển thị tên cơ sở.
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
                      clinicName,
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
                    // Địa chỉ, ưu tiên `address`, fallback `addressDetail`.
                    Text(
                      'Địa chỉ: $clinicAddress',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Mô tả, có fallback nếu backend chưa trả dữ liệu.
                    Text(
                      clinicDescription,
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),

                    // Ảnh minh họa, có fallback theo id.
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        clinicImageUrl,
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