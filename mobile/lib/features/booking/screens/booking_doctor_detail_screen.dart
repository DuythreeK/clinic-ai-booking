import 'package:flutter/material.dart';

import '../models/booking_doctor_item.dart';

class BookingDoctorDetailScreen extends StatelessWidget {
  const BookingDoctorDetailScreen({super.key, required this.doctor});

  final BookingDoctorItem doctor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE2F5FF), Colors.transparent],
              stops: [0.0, 1.0],
            ),
          ),
          child: AppBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  child: const Icon(Icons.chevron_left, color: Colors.black54),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            title: const Text(
              'Chi tiết bác sĩ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Color(0xFF9098B1), size: 28),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FBFF), Color(0xFFE9F9F4)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F5FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty)
                              ? Image.network(
                                  doctor.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return const Icon(
                                      Icons.person,
                                      color: Color(0xFF9098B1),
                                      size: 50,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Color(0xFF9098B1),
                                  size: 50,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    doctor.full_name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF222222),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.favorite, color: Colors.red, size: 22),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              doctor.specialtyName ?? 'Chuyên khoa',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF14CBA8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                                    const Icon(Icons.star_border, color: Colors.grey, size: 16),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '4.0',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.attach_money, color: Color(0xFF14CBA8), size: 16),
                                    Text(
                                      '${_formatMoney(doctor.consultationFee ?? 0)}/10p',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '(2821 quan tâm)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Personal Details Mock
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2FA4FF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Chuyên khoa: ${doctor.specialtyName ?? "Chưa cập nhật"}', style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.8)),
                            const Text('Bác sĩ chuyên khoa I', style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.8)),
                          ],
                        ),
                      ),
                      // Book Button
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop(true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          margin: const EdgeInsets.only(top: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3A8DFF), Color(0xFF14CBA8)], // Blue to teal gradient
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF14CBA8).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Đặt khám',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Experience
                  const Text(
                    'Hơn 10 năm kinh nghiệm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF14CBA8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bác sĩ có chuyên môn cao và tận tâm với bệnh nhân.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF36D8B7),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Education Details Mock
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFF14CBA8), // Green border
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đại học Y Dược\nChứng chỉ hành nghề khám chữa bệnh\nĐào tạo chuyên môn liên tục (CME)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Reviews Block
                  Center(
                    child: Container(
                      width: 250,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF14CBA8).withOpacity(0.25), // Glowing green shadow
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Xem đánh giá',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.star, color: Color(0xFFFFC107), size: 28),
                              SizedBox(width: 8),
                              Icon(Icons.star, color: Color(0xFFFFC107), size: 28),
                              SizedBox(width: 8),
                              Icon(Icons.star, color: Color(0xFFFFC107), size: 28),
                              SizedBox(width: 8),
                              Icon(Icons.star, color: Color(0xFFFFC107), size: 28),
                              SizedBox(width: 8),
                              Icon(Icons.star, color: Color(0xFFE0E0E0), size: 28),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount == 0) return '0d';
    final intValue = amount.round();
    final text = intValue.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final idx = text.length - i;
      buffer.write(text[i]);
      if (idx > 1 && idx % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()}d';
  }
}
