import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/services/auth_service.dart';

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
      _HomeDiscoverPage(prefilledSpecialty: widget.prefilledSpecialty),
      const _FavoriteDoctorsPage(),
      const _VaccinationPage(),
      const _MessagesPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _MainBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 4) {
            context.push('/ai-triage');
            return;
          }

          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _MainBottomNav extends StatelessWidget {
  const _MainBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    const selected = Color(0xFF00B7A8);
    const unselected = Color(0xFF8A96A8);

    final items = <IconData>[
      Icons.home_rounded,
      Icons.favorite_rounded,
      Icons.vaccines_rounded,
      Icons.chat_bubble_rounded,
      Icons.auto_awesome_rounded,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = index == currentIndex && index != 4;
          final iconColor = isSelected ? selected : unselected;

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 52,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0x1900B7A8) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(items[index], color: iconColor, size: 24),
            ),
          );
        }),
      ),
    );
  }
}

class _HomeDiscoverPage extends StatefulWidget {
  const _HomeDiscoverPage({this.prefilledSpecialty});

  final String? prefilledSpecialty;

  @override
  State<_HomeDiscoverPage> createState() => _HomeDiscoverPageState();
}

class _HomeDiscoverPageState extends State<_HomeDiscoverPage> {
  late final TextEditingController _searchController;

  final List<_SpecialtyInfo> _specialties = const [
    _SpecialtyInfo(
      name: 'Pulmonology',
      icon: Icons.air_rounded,
      colors: [Color(0xFF4B5BFF), Color(0xFF6B79FF)],
    ),
    _SpecialtyInfo(
      name: 'Cardiology',
      icon: Icons.favorite_rounded,
      colors: [Color(0xFF1AC8C4), Color(0xFF0FB9B5)],
    ),
    _SpecialtyInfo(
      name: 'Dental',
      icon: Icons.medical_services_rounded,
      colors: [Color(0xFFFFAE4A), Color(0xFFFF8D58)],
    ),
    _SpecialtyInfo(
      name: 'Orthopedic',
      icon: Icons.accessibility_new_rounded,
      colors: [Color(0xFFFF6375), Color(0xFFFF4B66)],
    ),
  ];

  final List<_DoctorInfo> _featuredDoctors = const [
    _DoctorInfo(
      name: 'Dr. Fillerup Grab',
      specialty: 'Nha si',
      rating: 4.0,
      reviewText: '3.8k danh gia',
      imageUrl: 'https://images.unsplash.com/photo-1651008376811-b90baee60c1f?auto=format&fit=crop&w=800&q=80',
    ),
    _DoctorInfo(
      name: 'Dr. Blessing',
      specialty: 'Nha si',
      rating: 4.0,
      reviewText: '3.2k danh gia',
      imageUrl: 'https://images.unsplash.com/photo-1594824804732-ca8db7f2b063?auto=format&fit=crop&w=800&q=80',
    ),
  ];

  final List<_DoctorInfo> _myDoctors = const [
    _DoctorInfo(
      name: 'Dr. Ali Karim',
      specialty: 'Cardiology',
      rating: 3.7,
      reviewText: '1.1k',
      imageUrl: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&w=400&q=80',
    ),
    _DoctorInfo(
      name: 'Dr. Tran Minh',
      specialty: 'Internal Medicine',
      rating: 2.9,
      reviewText: '920',
      imageUrl: 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.prefilledSpecialty?.trim() ?? '',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _HeaderSection(searchController: _searchController),
          const SizedBox(height: 14),
          _SectionTitle(title: 'Các chuyên khoa hiện có'),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => _SpecialtyTile(data: _specialties[index]),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: _specialties.length,
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle(title: 'Bác sĩ nổi bật', actionText: 'Xem'),
          const SizedBox(height: 10),
          SizedBox(
            height: 246,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => _FeaturedDoctorCard(doctor: _featuredDoctors[index]),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: _featuredDoctors.length,
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle(title: 'Bác sĩ của tôi', actionText: 'Xem'),
          const SizedBox(height: 10),
          ..._myDoctors.map(
            (doctor) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _MyDoctorCard(doctor: doctor),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1BD5C9), Color(0xFF0EA5C6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFE0E7EF),
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi Nguyễn Văn AI',
                      style: TextStyle(color: Color(0xFFF4FCFF), fontSize: 16),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tìm bác sĩ của bạn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: const [
                  Icon(Icons.notifications_none_rounded, color: Colors.white, size: 30),
                  Positioned(
                    right: -1,
                    top: -1,
                    child: CircleAvatar(
                      radius: 7,
                      backgroundColor: Color(0xFFFFC107),
                      child: Text(
                        '1',
                        style: TextStyle(fontSize: 9, color: Colors.black87, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm.....',
              filled: true,
              fillColor: Colors.white.withAlpha(230),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8EA0B6)),
              suffixIcon: const Icon(Icons.close_rounded, color: Color(0xFF8EA0B6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionText});

  final String title;
  final String? actionText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2B3A),
              ),
            ),
          ),
          if (actionText != null)
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionText!,
                style: const TextStyle(
                  color: Color(0xFF7F91A8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpecialtyTile extends StatelessWidget {
  const _SpecialtyTile({required this.data});

  final _SpecialtyInfo data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: data.colors),
      ),
      child: Icon(data.icon, color: Colors.white, size: 34),
    );
  }
}

class _FeaturedDoctorCard extends StatelessWidget {
  const _FeaturedDoctorCard({required this.doctor});

  final _DoctorInfo doctor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 178,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
            ),
            child: SizedBox(
              height: 146,
              width: double.infinity,
              child: Image.network(
                doctor.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE7EEF5),
                  alignment: Alignment.center,
                  child: const Icon(Icons.person_rounded, size: 54, color: Color(0xFF9BAABA)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  doctor.specialty,
                  style: const TextStyle(color: Color(0xFF1FAAA0), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: i < doctor.rating.round() ? const Color(0xFFFFC107) : const Color(0xFFE0E0E0),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      doctor.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF677889)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  doctor.reviewText,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8998A9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyDoctorCard extends StatelessWidget {
  const _MyDoctorCard({required this.doctor});

  final _DoctorInfo doctor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 58,
              height: 58,
              child: Image.network(
                doctor.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE7EEF5),
                  alignment: Alignment.center,
                  child: const Icon(Icons.person_rounded, color: Color(0xFF9BAABA)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  doctor.specialty,
                  style: const TextStyle(color: Color(0xFF1FAAA0), fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 14),
                    const SizedBox(width: 3),
                    Text(
                      doctor.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF728296)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.favorite_outline_rounded, color: Color(0xFF98A8B9)),
        ],
      ),
    );
  }
}

class _FavoriteDoctorsPage extends StatelessWidget {
  const _FavoriteDoctorsPage();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderTab(
      icon: Icons.favorite_rounded,
      title: 'Bác sĩ yêu thích',
      subtitle: 'Danh sách bác sĩ bạn đã lưu sẽ hiển thị tại đây.',
    );
  }
}

class _VaccinationPage extends StatelessWidget {
  const _VaccinationPage();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderTab(
      icon: Icons.vaccines_rounded,
      title: 'Tiêm chủng',
      subtitle: 'Theo dõi lịch và gói tiêm trong tab này.',
    );
  }
}

class _MessagesPage extends StatelessWidget {
  const _MessagesPage();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderTab(
      icon: Icons.chat_bubble_rounded,
      title: 'Tin nhắn',
      subtitle: 'Trao đổi với phòng khám và bác sĩ của bạn.',
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 62, color: const Color(0xFF8FA1B5)),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6E8094), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialtyInfo {
  const _SpecialtyInfo({
    required this.name,
    required this.icon,
    required this.colors,
  });

  final String name;
  final IconData icon;
  final List<Color> colors;
}

class _DoctorInfo {
  const _DoctorInfo({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviewText,
    required this.imageUrl,
  });

  final String name;
  final String specialty;
  final double rating;
  final String reviewText;
  final String imageUrl;
}
