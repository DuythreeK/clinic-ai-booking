import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/services/auth_service.dart';
import 'doctor_hub_models.dart';
import 'featured_doctors_screen.dart';
import 'my_doctors_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      FeaturedDoctorsScreen(
        initialKeyword: widget.prefilledSpecialty,
        onOpenDoctor: _openDoctor,
      ),
      MyDoctorsScreen(onOpenDoctor: _openDoctor),
      const _ComingSoonPage(
        icon: Icons.calendar_month_rounded,
        title: 'Lich hen',
        subtitle: 'Khu vuc nay se hien thi lich hen va lich tai kham cua ban.',
      ),
      const _ComingSoonPage(
        icon: Icons.chat_bubble_rounded,
        title: 'Tin nhan',
        subtitle: 'Thong bao tu van va trao doi voi phong kham se hien thi o day.',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFF),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: pages),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 16),
                child: InkWell(
                  onTap: () => context.push('/profile'),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x150B4764),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF5D718A),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _MainBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 3) {
            context.push('/vaccination-booking');
            return;
          }

          if (index == 5) {
            context.push('/ai-triage');
            return;
          }

          setState(() {
            _currentIndex = index > 3 ? index - 1 : index;
          });
        },
      ),
    );
  }

  void _openDoctor(DoctorProfile doctor) {
    context.push('/doctor/${doctor.id}');
  }
}

class _MainBottomNav extends StatelessWidget {
  const _MainBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const selected = Color(0xFF2DC7C4);
    const unselected = Color(0xFF94A3B8);
    final items = <IconData>[
      Icons.home_rounded,
      Icons.favorite_rounded,
      Icons.calendar_month_rounded,
      Icons.vaccines_rounded,
      Icons.chat_bubble_rounded,
      Icons.auto_awesome_rounded,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180A4A6A),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final pageIndex = index > 3 ? index - 1 : index;
          final isSelected = index != 3 && index != 5 && pageIndex == currentIndex;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 54,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0x162DC7C4) : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                items[index],
                color: isSelected ? selected : unselected,
                size: 24,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF9FF), Color(0xFFF8FEFF)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x160B4564),
                    blurRadius: 26,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0x152DC7C4),
                    child: Icon(icon, size: 34, color: const Color(0xFF22B8B3)),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF20304A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: Color(0xFF7A8CA5),
                    ),
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



