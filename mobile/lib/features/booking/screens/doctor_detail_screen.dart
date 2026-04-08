import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'doctor_hub_models.dart';
import '../../auth/services/auth_service.dart';

class DoctorDetailScreen extends StatelessWidget {
  const DoctorDetailScreen({
    super.key,
    required this.doctor,
    required this.authService,
  });

  final DoctorProfile doctor;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final catalog = DoctorCatalog.instance;
    final reviews = _buildReviews();

    return AnimatedBuilder(
      animation: catalog,
      builder: (context, _) {
        final isFavorite = catalog.isFavorite(doctor.id);
        return Scaffold(
          backgroundColor: const Color(0xFFF2FBFF),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFDFF7FF), Color(0xFFF9FEFF)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      children: [
                        _RoundIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const Expanded(
                          child: Text(
                            'Chi tiáº¿t bÃ¡c sÄ©',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF26364E),
                            ),
                          ),
                        ),
                        _RoundIconButton(
                          icon: Icons.search_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.96),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x140B4766),
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: _DoctorHeroImage(imageUrl: doctor.imageUrl),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  doctor.name,
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF26364E),
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => catalog.toggleFavorite(doctor.id),
                                                child: Icon(
                                                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                  color: Colors.red,
                                                  size: 24,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            doctor.specialty,
                                            style: TextStyle(
                                              color: doctor.highlight,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              ...List.generate(
                                                5,
                                                (index) => Icon(
                                                  Icons.star_rounded,
                                                  size: 17,
                                                  color: index < doctor.rating.round() ? const Color(0xFFFFC531) : const Color(0xFFDDE6F0),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                doctor.rating.toStringAsFixed(1),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF33435D),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                doctor.priceLabel,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF1EBE74),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '(${doctor.patientsLabel})',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF8A9AAF),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: GestureDetector(
                                              onTap: () {
                                                context.push('/booking?doctorId=${doctor.id}');
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 18,
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF26C495),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'Đặt khám',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                _InfoStripe(label: 'Giá»›i tÃ­nh', value: doctor.gender, color: const Color(0xFF35A7FF)),
                                _InfoStripe(label: 'ChuyÃªn mÃ´n', value: doctor.focus, color: const Color(0xFF35A7FF)),
                                _InfoStripe(label: 'Email', value: doctor.email, color: const Color(0xFF35A7FF)),
                                _InfoStripe(label: 'Sá»‘ Ä‘iá»‡n thoáº¡i', value: doctor.phone, color: const Color(0xFF35A7FF)),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${doctor.yearsExperience}+ nÄƒm kinh nghiá»‡m',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF24D38A),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    doctor.about,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: Color(0xFF657892),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _SectionCard(
                                  title: 'CÆ¡ sá»Ÿ khÃ¡m / bá»‡nh viá»‡n',
                                  borderColor: const Color(0xFF2DC7C4),
                                  child: Column(
                                    children: doctor.facilities.map((facility) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              margin: const EdgeInsets.only(top: 5),
                                              decoration: BoxDecoration(
                                                color: doctor.highlight,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    facility.name,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF23344E),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    facility.type,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: doctor.highlight,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    facility.address,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF6D829B),
                                                      height: 1.45,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _SectionCard(
                                  title: 'Chá»©ng chá»‰ & Ä‘Ã o táº¡o',
                                  borderColor: const Color(0xFF2BDC74),
                                  child: Column(
                                    children: doctor.certifications.map((item) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(top: 6),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF2BDC74),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                item,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  height: 1.5,
                                                  color: Color(0xFF3F526A),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openReviewsSheet(context, reviews),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x160B4766),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Xem Ä‘Ã¡nh giÃ¡',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF22344C),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      5,
                                      (index) => Icon(
                                        Icons.star_rounded,
                                        size: 34,
                                        color: index < 4
                                            ? const Color(0xFFFFB800)
                                            : const Color(0xFFD9E3EF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<_DoctorReview> _buildReviews() {
    return const [
      _DoctorReview(
        name: 'Quang Huy',
        avatar: 'QH',
        rating: 4,
        comment:
            'MÃ¬nh khÃ¡m vá»›i bÃ¡c sÄ© tháº¥y khÃ¡ á»•n, tÆ° váº¥n rÃµ rÃ ng vÃ  dá»… hiá»ƒu. BÃ¡c sÄ© thÄƒm khÃ¡m ká»¹, hÆ°á»›ng dáº«n chÄƒm sÃ³c vÃ  dÃ¹ng thuá»‘c chi tiáº¿t.',
      ),
      _DoctorReview(
        name: 'Minh Anh',
        avatar: 'MA',
        rating: 5,
        comment:
            'Ráº¥t hÃ i lÃ²ng! BÃ¡c sÄ© nhiá»‡t tÃ¬nh, nháº¹ nhÃ ng vÃ  láº¯ng nghe ká»¹. Cháº©n Ä‘oÃ¡n rÃµ rÃ ng, giáº£i thÃ­ch nguyÃªn nhÃ¢n vÃ  hÆ°á»›ng Ä‘iá»u trá»‹ dá»… hiá»ƒu. MÃ¬nh cáº£m tháº¥y yÃªn tÃ¢m vÃ  sáº½ giá»›i thiá»‡u cho ngÆ°á»i thÃ¢n.',
      ),
      _DoctorReview(
        name: 'Duc Minh',
        avatar: 'DM',
        rating: 4,
        comment:
            'BÃ¡c sÄ© chuyÃªn mÃ´n tá»‘t, khÃ¡m cáº©n tháº­n vÃ  theo dÃµi ká»¹ tÃ¬nh tráº¡ng. Dáº·n dÃ² Ä‘áº§y Ä‘á»§ sau khi khÃ¡m. Náº¿u cÃ³ thá»ƒ cáº£i thiá»‡n thÃªm pháº§n Ä‘áº·t lá»‹ch nhanh hÆ¡n thÃ¬ sáº½ tá»‘t hÆ¡n ná»¯a.',
      ),
      _DoctorReview(
        name: 'Lan Huong',
        avatar: 'LH',
        rating: 5,
        comment:
            'KhÃ´ng gian khÃ¡m sáº¡ch sáº½, lá»‹ch khÃ¡m Ä‘Ãºng giá». BÃ¡c sÄ© nhÃ¬n tá»•ng quÃ¡t ráº¥t ká»¹ vÃ  Ä‘Æ°a ra hÆ°á»›ng xá»­ lÃ½ há»£p lÃ½.',
      ),
    ];
  }

  void _openReviewsSheet(BuildContext context, List<_DoctorReview> reviews) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.5,
          maxChildSize: 0.94,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 52,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7E0EA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ÄÃ¡nh giÃ¡ cá»§a má»i ngÆ°á»i',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF25354D),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: reviews.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 24),
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          return _ReviewTile(review: review);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF607089), size: 18),
      ),
    );
  }
}

class _InfoStripe extends StatelessWidget {
  const _InfoStripe({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF93A3B7)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2A3A52),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.borderColor,
    required this.child,
  });

  final String title;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFEFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF23344E),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DoctorHeroImage extends StatelessWidget {
  const _DoctorHeroImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: 96,
      height: 112,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 96,
          height: 112,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE9F6FF), Color(0xFFE4F8EF)],
            ),
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 42,
            color: Color(0xFF7991AA),
          ),
        );
      },
    );
  }
}

class _DoctorReview {
  const _DoctorReview({
    required this.name,
    required this.avatar,
    required this.rating,
    required this.comment,
  });

  final String name;
  final String avatar;
  final int rating;
  final String comment;
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final _DoctorReview review;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFFFE8E0),
          child: Text(
            review.avatar,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFFB45A46),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2F48),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star_rounded,
                    size: 20,
                    color: index < review.rating
                        ? const Color(0xFFFFB800)
                        : const Color(0xFFD8E2ED),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                review.comment,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF30435E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

