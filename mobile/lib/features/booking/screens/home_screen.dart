import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/services/auth_service.dart';
import 'doctor_hub_models.dart';
import 'my_doctors_screen.dart';
import 'app_drawer_overlay.dart';

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
  final DoctorCatalog _catalog = DoctorCatalog.instance;
  late int _currentIndex;

  int get _navIndex => _currentIndex == 2 ? 3 : _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = 0;
    if (_currentIndex != nextIndex) {
      setState(() {
        _currentIndex = nextIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeFeedPage(
        catalog: _catalog,
        onOpenDoctor: _openDoctor,
        authService: widget.authService,
      ),
      MyDoctorsScreen(onOpenDoctor: _openDoctor),
      const _ComingSoonPage(
        icon: Icons.chat_bubble_rounded,
        title: 'Tin nhan',
        subtitle:
            'Thong bao tu van va trao doi voi phong kham se hien thi o day.',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFF),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _MainBottomNav(
        currentIndex: _navIndex,
        onTap: (index) {
          if (index == 2) {
            context.push('/booking');
            return;
          }

          if (index == 4) {
            context.push('/ai-triage');
            return;
          }

          setState(() {
            _currentIndex = index == 3 ? 2 : index;
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
          final isSelected = index == currentIndex && index != 4;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 54,
              height: 44,
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0x162DC7C4) : Colors.transparent,
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

class _HomeFeedPage extends StatefulWidget {
  const _HomeFeedPage({
    required this.catalog,
    required this.onOpenDoctor,
    required this.authService,
  });

  final DoctorCatalog catalog;
  final ValueChanged<DoctorProfile> onOpenDoctor;
  final AuthService authService;

  @override
  State<_HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<_HomeFeedPage> {
  static const _specialties = [
    _SpecialtyItem('Than', Icons.air, [Color(0xFF5661F6), Color(0xFF3F50E6)]),
    _SpecialtyItem(
        'Tim', Icons.favorite_border, [Color(0xFF25D0C8), Color(0xFF1FB8AF)]),
    _SpecialtyItem('Rang', Icons.emoji_emotions_outlined,
        [Color(0xFFFFB357), Color(0xFFFF9A3B)]),
    _SpecialtyItem('Co xuong', Icons.accessibility_new,
        [Color(0xFFFF6A6D), Color(0xFFFF5A60)]),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.catalog,
      builder: (context, _) {
        final featured = widget.catalog.featuredDoctors.take(6).toList();
        final mine = widget.catalog.myDoctors;

        return Container(
          color: const Color(0xFFF4F9FF),
          child: SafeArea(
            child: Column(
              children: [
                _HomeHeader(authService: widget.authService),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    children: [
                      const SizedBox(height: 12),
                      _SearchCard(),
                      const SizedBox(height: 14),
                      _SectionTitle(title: 'Cac chuyen khoa hien co'),
                      const SizedBox(height: 10),
                      Row(
                        children: _specialties
                            .map(
                              (item) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _SpecialtyCard(item: item),
                                ),
                              ),
                            )
                            .toList()
                          ..removeLast(),
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                          title: 'Bac si noi bat', actionLabel: 'Xem >'),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 252,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: featured.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final doctor = featured[index];
                            return _FeaturedDoctorCard(
                              doctor: doctor,
                              isFavorite: widget.catalog.isFavorite(doctor.id),
                              onFavorite: () =>
                                  widget.catalog.toggleFavorite(doctor.id),
                              onTap: () => widget.onOpenDoctor(doctor),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionTitle(
                          title: 'Bac si cua toi', actionLabel: 'Xem >'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: mine.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final doctor = mine[index];
                            return _MiniDoctorChip(
                                doctor: doctor,
                                onTap: () => widget.onOpenDoctor(doctor));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF19C9B7), Color(0xFF2A8BFF)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (_, __, ___) => AppDrawerOverlay(authService: authService),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
            child: const CircleAvatar(
              radius: 26,
              backgroundColor: Color(0xFFDDE8EF),
              child: Icon(Icons.person, color: Color(0xFF9FB1BF), size: 32),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi Nguyen Van AI',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                SizedBox(height: 2),
                Text(
                  'Tim bac si cua ban',
                  style: TextStyle(
                    fontSize: 32,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded,
                  color: Colors.white, size: 28),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFF3D57), shape: BoxShape.circle),
                  child: const Center(
                    child: Text('1',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x140B4764), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Tim kiem.....',
          prefixIcon: Icon(Icons.search, color: Color(0xFF9AA9B8)),
          suffixIcon: Icon(Icons.close, color: Color(0xFF9AA9B8)),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel});

  final String title;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              color: Color(0xFF27364D)),
        ),
        if (actionLabel != null)
          Text(actionLabel!,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF93A0B2),
                  fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SpecialtyItem {
  const _SpecialtyItem(this.label, this.icon, this.colors);

  final String label;
  final IconData icon;
  final List<Color> colors;
}

class _SpecialtyCard extends StatelessWidget {
  const _SpecialtyCard({required this.item});

  final _SpecialtyItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: item.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          Text(item.label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _FeaturedDoctorCard extends StatelessWidget {
  const _FeaturedDoctorCard({
    required this.doctor,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });

  final DoctorProfile doctor;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x120B4764), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14), topRight: Radius.circular(14)),
              child: Image.network(
                doctor.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: const Color(0xFFE7EEF6),
                  child: const Icon(Icons.person,
                      size: 40, color: Color(0xFFA5B2C0)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2A3A51)),
                  ),
                  const SizedBox(height: 2),
                  Text(doctor.specialty,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1FB8AF),
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Color(0xFFFFC94D)),
                      const SizedBox(width: 2),
                      Text('${doctor.rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4B5C74),
                              fontSize: 12)),
                      const Spacer(),
                      InkWell(
                        onTap: onFavorite,
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFavorite
                              ? const Color(0xFFFF4D61)
                              : const Color(0xFF9DAAC0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniDoctorChip extends StatelessWidget {
  const _MiniDoctorChip({required this.doctor, required this.onTap});

  final DoctorProfile doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE1E9F2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(doctor.imageUrl),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 6),
            Text(
              doctor.rating.toStringAsFixed(1),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF556781)),
            ),
          ],
        ),
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
