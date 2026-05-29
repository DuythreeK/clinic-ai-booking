import 'package:flutter/material.dart';

/*
  DoctorSearchScreen
  - Vai trò: UI tìm kiếm và lọc bác sĩ theo tên/chuyên khoa
  - Các lớp chính: DoctorSearchScreen, DoctorSearchDetailScreen
  - Gọi backend: endpoint danh sách bác sĩ (phục vụ search/filter), detail khi mở chi tiết
  - Lưu ý: component này chỉ đảm trách hiển thị và local filtering; network call được thực hiện bởi catalog/service tương ứng (nếu có)
*/

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({Key? key}) : super(key: key);

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSpecialty;
  bool _isLoading = false;
  final List<String> _specialties = [
    'Tất cả',
    'Nội khoa',
    'Ngoại khoa',
    'Răng hàm mặt',
    'Mắt',
    'Tai mũi họng',
    'Phụ khoa',
    'Nhi khoa',
    'Thần kinh',
    'Tâm thần',
  ];

  final List<Map<String, dynamic>> _doctors = [
    {
      'id': 1,
      'name': 'Tiến sĩ Nguyễn Văn A',
      'specialty': 'Nội khoa',
      'clinic': 'Bệnh viện Trung ương',
      'rating': 4.8,
      'reviews': 156,
      'experience': '15 năm',
      'available': true,
    },
    {
      'id': 2,
      'name': 'Tiến sĩ Trần Thị B',
      'specialty': 'Ngoại khoa',
      'clinic': 'Bệnh viện Quốc tế',
      'rating': 4.6,
      'reviews': 98,
      'experience': '12 năm',
      'available': true,
    },
    {
      'id': 3,
      'name': 'Tiến sĩ Lê Văn C',
      'specialty': 'Nội khoa',
      'clinic': 'Bệnh viện Trung ương',
      'rating': 4.9,
      'reviews': 234,
      'experience': '18 năm',
      'available': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm bác sĩ'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm bác sĩ, chuyên khoa...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // Specialty filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _specialties.map((specialty) {
                      final isSelected = _selectedSpecialty == specialty ||
                          (_selectedSpecialty == null && specialty == 'Tất cả');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(specialty),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSpecialty = selected ? specialty : null;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Doctors List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _doctors.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final doctor = _doctors[index];
                      return _buildDoctorCard(doctor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DoctorSearchDetailScreen(doctor: doctor),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor name and availability badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          doctor['specialty'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: doctor['available']
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      doctor['available'] ? 'Có lịch' : 'Hết lịch',
                      style: TextStyle(
                        fontSize: 12,
                        color: doctor['available']
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Clinic info
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      doctor['clinic'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Rating and experience
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${doctor['rating']} (${doctor['reviews']} đánh giá)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.work, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        doctor['experience'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Doctor Detail Screen
class DoctorSearchDetailScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const DoctorSearchDetailScreen({
    Key? key,
    required this.doctor,
  }) : super(key: key);

  @override
  State<DoctorSearchDetailScreen> createState() => _DoctorSearchDetailScreenState();
}

class _DoctorSearchDetailScreenState extends State<DoctorSearchDetailScreen> {
  DateTime? _selectedDate;
  String? _selectedTime;

  final List<String> _availableTimes = [
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '14:00 PM',
    '15:00 PM',
    '16:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bác sĩ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 50),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.doctor['name'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.doctor['specialty'],
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${widget.doctor['rating']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  Icons.star,
                                  size: 14,
                                  color: i < 5 ? Colors.amber : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              widget.doctor['reviews'].toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Đánh giá',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              widget.doctor['experience'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Kinh nghiệm',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // About
            const Text(
              'Về bác sĩ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bác sĩ có chuyên môn cao và kinh nghiệm dày dạn trong điều trị các bệnh thuộc chuyên khoa. Luôn lắng nghe và quan tâm đến từng bệnh nhân.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            // Date Selection
            const Text(
              'Chọn ngày',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = _selectedDate == date;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Card(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                      margin: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 80,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getDayName(date.weekday),
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${date.day}/${date.month}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Time Selection
            const Text(
              'Chọn giờ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTimes.map((time) {
                final isSelected = _selectedTime == time;
                return OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedTime = time;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            // Book Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedDate != null && _selectedTime != null
                    ? _bookAppointment
                    : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Đặt lịch hẹn'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
    return days[weekday - 1];
  }

  void _bookAppointment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lịch hẹn đã được đặt thành công')),
    );
    Navigator.of(context).pop();
  }
}
