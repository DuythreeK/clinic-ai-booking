import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Nhớ thêm thư viện này vào pubspec.yaml
import '../../chat/screens/chat_detail_screen.dart';
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  // Hàm để gọi điện hotline
  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text("Liên hệ hỗ trợ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Kênh hỗ trợ trực tuyến", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // 1. Chat với bác sĩ
            _buildContactItem(
              icon: Icons.chat_bubble,
              color: Colors.blue,
              title: "Chat với bác sĩ",
              subtitle: "Tư vấn sức khỏe trực tuyến 24/7",
              onTap: () {
                // LỆNH NHẢY SANG MÀN HÌNH CHAT ĐÂY
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatDetailScreen()),
                );
              },
            ),

            // 2. Tổng đài CSKH
            _buildContactItem(
              icon: Icons.headset_mic,
              color: Colors.green,
              title: "Tổng đài chăm sóc khách hàng",
              subtitle: "Giải đáp thắc mắc về ứng dụng",
              onTap: () => _makePhoneCall("19001234"),
            ),

            const SizedBox(height: 30),
            const Text("Câu hỏi thường gặp", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            _buildFAQItem("Làm sao để hủy lịch hẹn?"),
            _buildFAQItem("Tôi có thể thanh toán bằng những hình thức nào?"),
            _buildFAQItem("Bảo mật thông tin bệnh án như thế nào?"),

            const SizedBox(height: 40),
            // Nút hỗ trợ khẩn cấp
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
                  const SizedBox(height: 10),
                  const Text("Hỗ trợ khẩn cấp (Cấp cứu)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: () => _makePhoneCall("115"),
                    icon: const Icon(Icons.phone),
                    label: const Text("GỌI 115 NGAY"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQItem(String question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontSize: 14)),
        children: const [
          Padding(
            padding: EdgeInsets.all(15.0),
            child: Text("Bạn có thể thực hiện thao tác này trong mục 'Lịch hẹn của tôi' trước giờ khám ít nhất 2 tiếng."),
          )
        ],
      ),
    );
  }
}