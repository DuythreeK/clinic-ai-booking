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
  final SpecialtyCatalog _specialtyCatalog = SpecialtyCatalog.instance;
  late int _currentIndex;
  int get _navIndex => _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0; // Mặc định vào Tab Trang chủ
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
        specialtyCatalog: _specialtyCatalog,
        onOpenDoctor: _openDoctor,
        authService: widget.authService,
      ),
      MyDoctorsScreen(onOpenDoctor: _openDoctor),
      const _ComingSoonPage(
        icon: Icons.calendar_month_rounded,
        title: 'Lịch hẹn',
        subtitle: 'Khu vực này sẽ hiển thị lịch hẹn và lịch tái khám của bạn.',
      ),
      const _ComingSoonPage(
        icon: Icons.chat_bubble_rounded,
        title: 'Tin nhan',
        subtitle: 'Thong bao tu van va trao doi voi phong kham se hien thi o day.',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFF),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _MainBottomNav(
        currentIndex: _navIndex,
        onTap: (index) {
          if (index == 2) {
            context.push('/booking'); // Gọi sang luồng đặt lịch
            return; // Dừng lại, không chạy setState bên dưới
          }

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
      Icons.vaccines_outlined,
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
          final isSelected =
              index != 3 && index != 5 && pageIndex == currentIndex;
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
              child: Center(
                child: Transform.rotate(
                  angle: index == 3 ? -0.75 : 0,
                  child: Icon(
                    items[index],
                    color: isSelected ? selected : unselected,
                    size: index == 3 ? 23 : 24,
                  ),
                ),
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
    required this.specialtyCatalog,
    required this.onOpenDoctor,
    required this.authService,
  });

  final DoctorCatalog catalog;
  final SpecialtyCatalog specialtyCatalog;
  final ValueChanged<DoctorProfile> onOpenDoctor;
  final AuthService authService;

  @override
  State<_HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<_HomeFeedPage> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.catalog, widget.specialtyCatalog]),
      builder: (context, _) {
        final featured = widget.catalog.featuredDoctors.take(6).toList();
        final mine = widget.catalog.myDoctors;
        final specialties = widget.specialtyCatalog.specialties.take(4).toList();
        final loading = widget.catalog.isLoading && featured.isEmpty && mine.isEmpty;
        final specialtyLoading =
            widget.specialtyCatalog.isLoading && specialties.isEmpty;

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
                      _SectionTitle(
                        title: 'Các chuyên khoa hiện có',
                        actionLabel: 'Xem thêm',
                        onActionTap: () => context.push('/doctors/explore'),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 96,
                        child: specialtyLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: specialties
                                      .map(
                                        (item) => Padding(
                                          padding: const EdgeInsets.only(right: 10),
                                          child: _SpecialtyCard(
                                            item: item,
                                            onTap: () {
                                              context.push(
                                                '/doctors/explore?specialty=${Uri.encodeComponent(item.name)}',
                                              );
                                            },
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        title: 'Bác sĩ nổi bật',
                        actionLabel: 'Xem thêm',
                        onActionTap: () => context.push('/featured-doctors'),
                      ),
                      const SizedBox(height: 10),
                      if (loading)
                        const SizedBox(
                          height: 252,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
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
                                    widget.catalog.toggleFavorite(doctor),
                                onTap: () => widget.onOpenDoctor(doctor),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 18),
                      _SectionTitle(
                        title: 'Bác sĩ của tôi',
                        actionLabel: 'Xem thêm',
                        onActionTap: () => context.push('/my-doctors'),
                      ),
                      const SizedBox(height: 8),
                      if (loading)
                        const SizedBox(
                          height: 64,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (mine.isEmpty)
                        Container(
                          height: 64,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFD9EAF6)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.favorite_border_rounded, color: Color(0xFF94A3B8)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Chưa có bác sĩ đã tim',
                                  style: TextStyle(
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
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
  const _SectionTitle({required this.title, this.actionLabel, this.onActionTap});

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

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
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF93A0B2),
                  fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _SpecialtyCard extends StatelessWidget {
  const _SpecialtyCard({required this.item, required this.onTap});

  final SpecialtyChoice item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForSpecialty(item.name);
    final icon = _iconForSpecialty(item.name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForSpecialty(String specialty) {
  switch (specialty.toLowerCase()) {
    case 'tim mạch':
      return Icons.favorite_rounded;
    case 'nha sĩ':
      return Icons.medical_services_rounded;
    case 'nhi khoa':
      return Icons.child_care_rounded;
    case 'da liễu':
      return Icons.spa_rounded;
    case 'tiêm chủng':
      return Icons.vaccines_rounded;
    default:
      return Icons.local_hospital_rounded;
  }
}

List<Color> _colorsForSpecialty(String specialty) {
  switch (specialty.toLowerCase()) {
    case 'tim mạch':
      return const [Color(0xFF25D0C8), Color(0xFF1FB8AF)];
    case 'nha sĩ':
      return const [Color(0xFFFFB357), Color(0xFFFF9A3B)];
    case 'nhi khoa':
      return const [Color(0xFF5661F6), Color(0xFF3F50E6)];
    case 'da liễu':
      return const [Color(0xFFFF6A6D), Color(0xFFFF5A60)];
    case 'tiêm chủng':
      return const [Color(0xFF20C8C2), Color(0xFF2A8BFF)];
    default:
      return const [Color(0xFF6B7CFF), Color(0xFF4F8DFD)];
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










