import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:clinic_ai_booking/core/api/dio_client.dart';
import 'package:clinic_ai_booking/features/auth/services/auth_service.dart';
import 'package:clinic_ai_booking/features/booking/screens/doctor_hub_models.dart';
import 'package:clinic_ai_booking/features/booking/screens/featured_doctors_screen.dart';
import 'package:clinic_ai_booking/features/booking/screens/my_doctors_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.authService,
    this.initialTab = 0,
    this.prefilledSpecialty,
  });

  final AuthService authService;
  final int initialTab;
  final String? prefilledSpecialty;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  bool _isLoading = true;
  List<dynamic> _doctors = [];
  List<dynamic> _clinics = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab.clamp(0, 3);
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dioClient = DioClient(secureStorage: const FlutterSecureStorage());

      // Gọi đúng endpoint với tiền tố /api/ từ main.ts
      final results = await Future.wait([
        dioClient.dio.get('/api/doctors', queryParameters: {'limit': 10}),
        dioClient.dio.get('/api/facilities', queryParameters: {'limit': 5}),
      ]);

      setState(() {
        // Bóc tách dữ liệu Bác sĩ
        final docRes = results[0].data;
        if (docRes is Map && docRes['data'] != null) {
          _doctors = docRes['data']['items'] ?? [];
        } else {
          _doctors = docRes is List ? docRes : [];
        }

        // Bóc tách dữ liệu Phòng khám
        final clinicRes = results[1].data;
        if (clinicRes is Map && clinicRes['data'] != null) {
          _clinics = clinicRes['data']['items'] ?? [];
        } else {
          _clinics = clinicRes is List ? clinicRes : [];
        }

        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi Dashboard: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Không thể tải dữ liệu. Dũng kiểm tra 'npx prisma db seed' đã chạy xong chưa nhé!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2DC7C4)))
          : _errorMessage != null
          ? _buildErrorState()
          : _UnifiedDashboard(
        doctors: _doctors,
        clinics: _clinics,
        onRefresh: _fetchDashboardData,
      ),
      MyDoctorsScreen(onOpenDoctor: _openDoctor),
      const _ComingSoonPage(icon: Icons.vaccines_rounded, title: 'Lịch tiêm'),
      const _ComingSoonPage(icon: Icons.chat_bubble_rounded, title: 'Tin nhắn'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEAF9FF), // Màu nền xanh nhạt
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: pages),
          _buildHeader(),
        ],
      ),
      bottomNavigationBar: _MainBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 4) { context.push('/ai-triage'); return; }
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 54),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchDashboardData,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2DC7C4)),
              child: const Text("Thử lại", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Thông báo bên TRÁI
            _headerBtn(Icons.notifications_none_rounded, () {}, hasBadge: true),
            const Text(
                "Clinic AI",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF20304A))
            ),
            // Profile bên PHẢI
            _headerBtn(Icons.person_outline_rounded, () => context.push('/profile')),
          ],
        ),
      ),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap, {bool hasBadge = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
        ),
        child: Stack(alignment: Alignment.center, children: [
          Icon(icon, color: const Color(0xFF5D718A), size: 24),
          if (hasBadge)
            Positioned(
                top: 10, right: 12,
                child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF2DC7C4), shape: BoxShape.circle))
            ),
        ]),
      ),
    );
  }

  void _openDoctor(DoctorProfile doctor) => context.push('/doctor/${doctor.id}');
}

class _UnifiedDashboard extends StatelessWidget {
  final List<dynamic> doctors;
  final List<dynamic> clinics;
  final VoidCallback onRefresh;

  const _UnifiedDashboard({
    required this.doctors,
    required this.clinics,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 90, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Chào mừng Dũng!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const Text("Hệ thống đã sẵn sàng hỗ trợ bạn.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          _buildSearch(),
          const SizedBox(height: 28),

          const Text("Các chuyên khoa hiện có", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF20304A))),
          const SizedBox(height: 16),
          _buildSpecialtyGrid(),
          const SizedBox(height: 24),

          _buildBookingBtn(context),
          const SizedBox(height: 28),

          _buildHeaderSection("Bác sĩ nổi bật", () {}),
          const SizedBox(height: 12),
          _buildDoctorList(context),
          const SizedBox(height: 28),

          _buildHeaderSection("Phòng khám nổi bật", () => context.push('/clinics')),
          const SizedBox(height: 12),
          _buildClinicList(context),
        ]),
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: const TextField(decoration: InputDecoration(icon: Icon(Icons.search, color: Color(0xFF2DC7C4)), hintText: "Tìm bác sĩ, chuyên khoa...", border: InputBorder.none)),
    );
  }

  Widget _buildSpecialtyGrid() {
    final specs = [
      {'icon': Icons.opacity, 'color': const Color(0xFF4C6FFF)},
      {'icon': Icons.favorite, 'color': const Color(0xFF20D0A4)},
      {'icon': Icons.health_and_safety, 'color': const Color(0xFFFFB258)},
      {'icon': Icons.accessibility_new, 'color': const Color(0xFFFF5E5E)},
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: specs.map((s) => Container(
        width: 75, height: 75,
        decoration: BoxDecoration(color: s['color'] as Color, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: (s['color'] as Color).withOpacity(0.2), blurRadius: 8)]),
        child: Icon(s['icon'] as IconData, color: Colors.white, size: 32),
      )).toList(),
    );
  }

  Widget _buildBookingBtn(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/clinics'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
            color: const Color(0xFF2DC7C4),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF2DC7C4).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.calendar_month_rounded, color: Colors.white),
          SizedBox(width: 12),
          Text("Đặt lịch khám ngay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
      ),
    );
  }

  Widget _buildDoctorList(BuildContext context) {
    if (doctors.isEmpty) return const Text("Đang cập nhật danh sách bác sĩ...");
    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: doctors.length,
        itemBuilder: (ctx, i) {
          final doc = doctors[i];

          // FIX LỖI: Kiểm tra xem specialty là String hay Map
          final specialtyData = doc['specialty'];
          String specialtyName = "Đa khoa";
          if (specialtyData is Map) {
            specialtyName = specialtyData['name'] ?? "Đa khoa";
          } else if (specialtyData is String) {
            specialtyName = specialtyData;
          }

          return InkWell(
            onTap: () => context.push('/doctor/${doc['id'].toString()}'),
            child: Container(
              width: 140, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
              child: Column(children: [
                const CircleAvatar(radius: 30, backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.person, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(doc['fullName'] ?? "Bác sĩ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),

                // Hiển thị tên chuyên khoa đã được fix
                Text(specialtyName, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),

                const Spacer(),
                const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.star, size: 14, color: Colors.orange), Text(" 4.9", style: TextStyle(fontSize: 12))])
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClinicList(BuildContext context) {
    if (clinics.isEmpty) return const Text("Đang cập nhật danh sách phòng khám...");
    return ListView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: clinics.length,
      itemBuilder: (ctx, i) {
        final clinic = clinics[i];
        return InkWell(
          onTap: () => context.push('/clinic-detail', extra: clinic),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.local_hospital, color: Color(0xFF2DC7C4))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(clinic['name'] ?? "Bệnh viện", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(clinic['addressDetail'] ?? clinic['address'] ?? "Địa chỉ", style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)
              ])),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(String t, VoidCallback onTap) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), TextButton(onPressed: onTap, child: const Text("Tất cả", style: TextStyle(color: Color(0xFF2DC7C4))))]);
}

class _MainBottomNav extends StatelessWidget {
  final int currentIndex; final ValueChanged<int> onTap;
  const _MainBottomNav({required this.currentIndex, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final items = [Icons.home_rounded, Icons.favorite_rounded, Icons.calendar_month_rounded, Icons.chat_bubble_rounded, Icons.auto_awesome_rounded];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x180A4A6A), blurRadius: 22, offset: Offset(0, 10))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(items.length, (i) {
        final sel = i == currentIndex && i != 4;
        return InkWell(onTap: () => onTap(i), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: sel ? const Color(0x162DC7C4) : Colors.transparent, shape: BoxShape.circle), child: Icon(items[i], color: sel ? const Color(0xFF2DC7C4) : const Color(0xFF94A3B8), size: 24)));
      })),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  final IconData icon; final String title;
  const _ComingSoonPage({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 64, color: const Color(0xFF2DC7C4)), const SizedBox(height: 16), Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))]));
}