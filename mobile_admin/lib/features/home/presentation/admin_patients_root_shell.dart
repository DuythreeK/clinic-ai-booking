import 'package:flutter/material.dart';

import '../../../shared/widgets/admin_bottom_navigation_bar.dart';
import '../../appointments/presentation/admin_appointments_screen.dart';
import '../../auth/domain/admin_session_user.dart';
import '../../dashboard/presentation/admin_dashboard_live_screen.dart';
import '../../doctors/presentation/admin_doctors_screen.dart';
import '../../patients/presentation/admin_patients_screen.dart';
import '../../settings/presentation/admin_settings_screen.dart';
import '../../specialties/presentation/admin_specialties_screen.dart';
import '../../rooms/presentation/admin_rooms_screen.dart';

class AdminPatientsRootShell extends StatefulWidget {
  const AdminPatientsRootShell({
    super.key,
    required this.currentUser,
    this.onLogout,
    this.initialIndex = 0,
  });

  final AdminSessionUser currentUser;
  final Future<void> Function()? onLogout;
  final int initialIndex;

  @override
  State<AdminPatientsRootShell> createState() => _AdminPatientsRootShellState();
}

class _AdminPatientsRootShellState extends State<AdminPatientsRootShell> {
  late int _selectedIndex;

  static const _navItems = [
    AdminBottomNavigationItem(
      icon: Icons.dashboard_outlined,
      label: 'Tổng quan',
    ),
    AdminBottomNavigationItem(
      icon: Icons.calendar_today_outlined,
      label: 'Lịch hẹn',
    ),
    AdminBottomNavigationItem(
      icon: Icons.health_and_safety_outlined,
      label: 'Bác sĩ',
    ),
    AdminBottomNavigationItem(
      icon: Icons.person_outline_rounded,
      label: 'Bệnh nhân',
    ),
    AdminBottomNavigationItem(
      icon: Icons.local_hospital_outlined,
      label: 'Chuyên khoa',
    ),
    AdminBottomNavigationItem(
      icon: Icons.meeting_room_outlined,
      label: 'Phòng khám',
    ),
    AdminBottomNavigationItem(icon: Icons.settings_outlined, label: 'Cài đặt'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminDashboardLiveScreen(greetingName: widget.currentUser.fullName),
      const AdminAppointmentsScreen(),
      const AdminDoctorsScreen(),
      const AdminPatientsScreen(),
      const AdminSpecialtiesScreen(),
      const AdminRoomsScreen(),
      AdminSettingsScreen(
        currentUser: widget.currentUser,
        onLogout: widget.onLogout,
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
