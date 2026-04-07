import 'package:flutter/material.dart';
import '../../clinics/screens/clinic_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Danh sách các màn hình tương ứng với các tab bên dưới
  final List<Widget> _pages = [
    const HomeContent(), // Trang chủ (Giao diện chính bạn gửi)
    const Center(child: Text("Yêu thích")),
    const ClinicListScreen(), // Nút hình cái kim tiêm sẽ mở trang Phòng khám của bạn
    const Center(child: Text("Tin nhắn")),
    const Center(child: Text("Cá nhân")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Widget Thanh điều hướng dưới cùng giống ảnh
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home, 0),
          _navItem(Icons.favorite_border, 1),
          // Nút giữa đặc biệt (Hình cái kim tiêm/y tế)
          _navItem(Icons.vaccines, 2, isSpecial: true),
          _navItem(Icons.chat_bubble_outline, 3),
          _navItem(Icons.auto_awesome_outlined, 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index, {bool isSpecial = false}) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: isSpecial && isSelected
            ? const BoxDecoration(color: Color(0xFF2CB9D8), shape: BoxShape.circle)
            : null,
        child: Icon(
          icon,
          color: isSelected ? (isSpecial ? Colors.white : const Color(0xFF2CB9D8)) : Colors.grey,
          size: isSpecial ? 30 : 28,
        ),
      ),
    );
  }
}

// --- PHẦN NỘI DUNG CHÍNH CỦA TRANG CHỦ ---
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSectionTitle("Phòng khám hiện có"),
          _buildClinicCategories(),
          _buildSectionTitle("Phòng khám nổi bật", hasViewAll: true),
          _buildFeaturedClinics(),
          _buildSectionTitle("Phòng khám của tôi", hasViewAll: true),
          _buildMyClinics(),
        ],
      ),
    );
  }

  // 1. Header Gradient xanh
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00B4D8), Color(0xFF48CAE4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 25, backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.grey)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Hi Dũng!", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      Text("Tìm phòng khám của bạn", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.notifications_none, color: Colors.white, size: 30),
            ],
          ),
          const SizedBox(height: 25),
          // Thanh tìm kiếm
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: const TextField(
              decoration: InputDecoration(
                hintText: "Tìm kiếm....",
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: Icon(Icons.close, color: Colors.grey, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool hasViewAll = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          if (hasViewAll) const Text("Xem >", style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  // 2. Các icon chuyên khoa (đã đổi thành icon phòng khám)
  Widget _buildClinicCategories() {
    final List<Map<String, dynamic>> cats = [
      {"icon": Icons.local_hospital, "color": Colors.indigo},
      {"icon": Icons.medical_services, "color": Colors.teal},
      {"icon": Icons.biotech, "color": Colors.orange},
      {"icon": Icons.personal_video, "color": Colors.red},
    ];
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: cats.length,
        itemBuilder: (context, i) => Container(
          width: 85,
          margin: const EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [cats[i]['color'].withOpacity(0.7), cats[i]['color']]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(cats[i]['icon'], color: Colors.white, size: 40),
        ),
      ),
    );
  }

  // 3. Danh sách phòng khám nổi bật
  Widget _buildFeaturedClinics() {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: 3,
        itemBuilder: (context, i) => Container(
          width: 180,
          margin: const EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Phòng khám PTIT", style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text("Đa khoa", style: TextStyle(color: Colors.cyan, fontSize: 12)),
                    Row(
                      children: const [
                        Icon(Icons.star, color: Colors.orange, size: 14),
                        Icon(Icons.star, color: Colors.orange, size: 14),
                        Icon(Icons.star, color: Colors.orange, size: 14),
                        Text(" 4.0", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 4. Phòng khám của tôi (Dưới cùng)
  Widget _buildMyClinics() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 2,
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.local_hospital)),
            const SizedBox(width: 15),
            const Expanded(child: Text("Bệnh viện Bạch Mai", style: TextStyle(fontWeight: FontWeight.bold))),
            const Icon(Icons.favorite, color: Colors.red, size: 20),
          ],
        ),
      ),
    );
  }
}