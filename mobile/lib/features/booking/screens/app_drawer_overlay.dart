import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/services/auth_service.dart';

class AppDrawerOverlay extends StatefulWidget {
  const AppDrawerOverlay({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<AppDrawerOverlay> createState() => _AppDrawerOverlayState();
}

class _AppDrawerOverlayState extends State<AppDrawerOverlay> {
  String _userName = 'Nguyễn Văn A';
  String _userPhone = '081892319321';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await widget.authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        if (user['full_name'] != null && user['full_name'].toString().isNotEmpty) {
          _userName = user['full_name'].toString();
        }
        if (user['phone'] != null && user['phone'].toString().isNotEmpty) {
          _userPhone = user['phone'].toString();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Background gradient similar to the reference image
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1CB1A3), Color(0xFF2879B5)], // Approximate from screenshot
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 16, right: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Color(0xFFDDE8EF),
                          child: Icon(Icons.person, color: Color(0xFF9FB1BF), size: 48),
                        ),
                        const SizedBox(width: 14),
                        // User Info
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, color: Colors.white70, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      _userPhone,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Close Button
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF1B1B), // Red close button
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Menu Items
                          _buildMenuItem(Icons.home, 'Trang chủ', onTap: () {
                            Navigator.of(context).pop();
                            context.go('/home');
                          }),
                          _buildMenuItem(Icons.person, 'Thông tin cá nhân', onTap: () {
                            Navigator.of(context).pop();
                            context.push('/profile');
                          }),
                          _buildMenuItem(Icons.folder_shared_outlined, 'Hồ sơ khám', onTap: () {
                            Navigator.of(context).pop();
                            context.push('/medical-profiles');
                          }),
                          _buildMenuItem(Icons.calendar_month_outlined, 'Lịch hẹn', onTap: () {
                            Navigator.of(context).pop();
                            context.push('/appointments');
                          }),
                          _buildMenuItem(Icons.assignment_outlined, 'Lịch sử phiếu khám', onTap: () {
                            Navigator.of(context).pop();
                            context.push('/history');
                          }),
                          _buildMenuItem(Icons.verified_user_outlined, 'Chính sách &\nBảo mật', onTap: () {}),
                          _buildMenuItem(Icons.help_outline, 'Trung tâm trợ\ngiúp', onTap: () {}),
                          _buildMenuItem(Icons.settings, 'Cài đặt', onTap: () {}),
                          _buildMenuItem(Icons.tune_rounded, 'Điều chỉnh chỗ cho lịch tiêm (Admin)', onTap: () {
                            Navigator.of(context).pop();
                            context.push('/admin/slots-capacity');
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 24),
                    child: InkWell(
                      onTap: () async {
                        await widget.authService.logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.logout, color: Color(0xFFF19729), size: 28),
                          const SizedBox(width: 16),
                          const Text(
                            'Đăng xuất',
                            style: TextStyle(
                              color: Color(0xFFF19729),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Vertically rotated text on the right
              Positioned(
                right: -40,
                top: 300,
                child: RotatedBox(
                  quarterTurns: 3, // Rotate -90 degrees
                  child: Text(
                    'CTUT Care+',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.15),
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 24),
          ],
        ),
      ),
    );
  }
}
