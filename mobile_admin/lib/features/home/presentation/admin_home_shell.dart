import 'package:flutter/material.dart';

import '../../../shared/widgets/admin_bottom_navigation_bar.dart';
import '../../../theme/admin_app_theme.dart';
import '../../appointments/presentation/admin_appointments_screen.dart';
import '../../dashboard/presentation/admin_dashboard_screen.dart';

class AdminHomeShell extends StatefulWidget {
  const AdminHomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AdminHomeShell> createState() => _AdminHomeShellState();
}

class _AdminHomeShellState extends State<AdminHomeShell> {
  late int _selectedIndex;

  static const _navItems = [
    AdminBottomNavigationItem(
      icon: Icons.dashboard_outlined,
      label: 'Dashboard',
    ),
    AdminBottomNavigationItem(
      icon: Icons.calendar_today_outlined,
      label: 'Appointments',
    ),
    AdminBottomNavigationItem(
      icon: Icons.health_and_safety_outlined,
      label: 'Doctors',
    ),
    AdminBottomNavigationItem(
      icon: Icons.person_outline_rounded,
      label: 'Patients',
    ),
    AdminBottomNavigationItem(icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const AdminDashboardScreen(),
      const AdminAppointmentsScreen(),
      const _FeaturePlaceholderScreen(
        icon: Icons.health_and_safety_outlined,
        title: 'Doctors',
        subtitle: 'Khu vực quản lý bác sĩ sẽ được nối tiếp ở bước sau.',
      ),
      const _FeaturePlaceholderScreen(
        icon: Icons.person_outline_rounded,
        title: 'Patients',
        subtitle: 'Khu vực quản lý bệnh nhân đang chờ bạn mở rộng thêm.',
      ),
      const _FeaturePlaceholderScreen(
        icon: Icons.settings_outlined,
        title: 'Settings',
        subtitle: 'Cấu hình ứng dụng admin sẽ hiển thị ở đây.',
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: AdminBottomNavigationBar(
        items: _navItems,
        selectedIndex: _selectedIndex,
        onChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class _FeaturePlaceholderScreen extends StatelessWidget {
  const _FeaturePlaceholderScreen({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AdminAppTheme.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AdminAppTheme.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEFF4FF),
                    ),
                    child: Icon(icon, color: AdminAppTheme.primary, size: 28),
                  ),
                  const SizedBox(height: 18),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
