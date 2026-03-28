import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    Key? key,
    required this.authService,
  }) : super(key: key);

  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await widget.authService.logout();
      if (mounted) {
        context.go('/login');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinic AI Booking')),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const SearchDoctorPage(),
          const AppointmentsPage(),
          ProfilePage(
            isLoggingOut: _isLoggingOut,
            onLogout: _logout,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class SearchDoctorPage extends StatelessWidget {
  const SearchDoctorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final specialties = <String>[
      'General Medicine',
      'Cardiology',
      'Dermatology',
      'Pediatrics',
      'Mental Health',
      'Neurology',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF00695C), Color(0xFF26A69A)],
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find Your Doctor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Search by specialty, availability, and clinic location.',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search doctors or specialties',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: specialties
              .map(
                (specialty) => Chip(
                  label: Text(specialty),
                  avatar: const Icon(Icons.local_hospital_rounded, size: 18),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        const _DoctorCard(
          name: 'Dr. An Nguyen',
          specialty: 'Cardiology',
          rating: '4.9',
          location: 'Central Clinic',
        ),
        const SizedBox(height: 12),
        const _DoctorCard(
          name: 'Dr. Linh Tran',
          specialty: 'Dermatology',
          rating: '4.8',
          location: 'West Medical Center',
        ),
      ],
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.location,
  });

  final String name;
  final String specialty;
  final String rating;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  child: Icon(Icons.person_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(specialty),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 18),
                    const SizedBox(width: 2),
                    Text(rating),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.place_rounded, size: 18),
                const SizedBox(width: 4),
                Text(location),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _AppointmentCard(
          doctor: 'Dr. An Nguyen',
          specialty: 'Cardiology',
          schedule: 'Mon, Mar 31 · 09:30 AM',
          status: 'Confirmed',
        ),
        SizedBox(height: 12),
        _AppointmentCard(
          doctor: 'Dr. Linh Tran',
          specialty: 'Dermatology',
          schedule: 'Thu, Apr 03 · 02:00 PM',
          status: 'Pending',
        ),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.doctor,
    required this.specialty,
    required this.schedule,
    required this.status,
  });

  final String doctor;
  final String specialty;
  final String schedule;
  final String status;

  @override
  Widget build(BuildContext context) {
    final isConfirmed = status == 'Confirmed';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    doctor,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: isConfirmed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isConfirmed ? const Color(0xFF2E7D32) : const Color(0xFFF57F17),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(specialty),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 18),
                const SizedBox(width: 6),
                Text(schedule),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Reschedule'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    Key? key,
    required this.onLogout,
    required this.isLoggingOut,
  }) : super(key: key);

  final Future<void> Function() onLogout;
  final bool isLoggingOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(radius: 28, child: Icon(Icons.person_rounded, size: 30)),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Manage your profile and settings'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.badge_outlined),
          title: const Text('Personal Information'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.notifications_none_rounded),
          title: const Text('Notification Preferences'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.security_rounded),
          title: const Text('Privacy & Security'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {},
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: isLoggingOut ? null : onLogout,
          icon: isLoggingOut
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.logout_rounded),
          label: Text(isLoggingOut ? 'Signing out...' : 'Sign out'),
        ),
      ],
    );
  }
}
