import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/api/dio_client.dart';
import '../models/booking_doctor_item.dart';
import '../../facilities/models/booking_facility_item.dart';

import 'booking_doctor_detail_screen.dart';

class DoctorSelectionScreen extends StatefulWidget {
  const DoctorSelectionScreen({
    super.key,
    required this.facility,
    required this.dioClient,
  });

  final BookingFacilityItem facility;
  final DioClient dioClient;

  @override
  State<DoctorSelectionScreen> createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _selectingDoctor = false;

  bool _loading = true;
  String? _error;
  List<BookingDoctorItem> _doctors = <BookingDoctorItem>[];
  List<BookingDoctorItem> _filteredDoctors = <BookingDoctorItem>[];

  // UI States
  String _selectedCategory = 'Tất cả';
  final List<String> _categories = ['Tất cả', 'Nha sĩ', 'Tim mạch', 'Chỉnh hình'];

  String _selectedSort1 = 'Tất cả BS';
  final List<String> _sort1Options = ['Tất cả BS', 'Đánh giá cao nhất', 'Khám nhiều nhất'];

  String _selectedSort2 = 'Tất cả BS';
  final List<String> _sort2Options = ['Tất cả BS', 'Giá khám tăng dần', 'Giá khám giảm dần'];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _searchCtrl.addListener(_filterDoctors);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await widget.dioClient.get(
        '/doctors',
        queryParameters: {
          'facilityId': widget.facility.id,
          'page': 1,
          'limit': 100,
        },
      );

      final items = _unwrapItems(response.data);
      final doctors = items
          .map((item) {
            final specialty = item['specialty'];
            return BookingDoctorItem(
              id: _toInt(item['id']) ?? 0,
              fullName: (item['fullName'] ?? '').toString(),
              avatarUrl: item['avatarUrl']?.toString(),
              specialtyName: specialty is Map<String, dynamic>
                  ? specialty['name']?.toString()
                  : null,
              facilityId: widget.facility.id,
              consultationFee: _toDouble(item['consultationFee']),
            );
          })
          .where((e) => e.id > 0 && e.fullName.isNotEmpty)
          .toList();

      setState(() {
        _doctors = doctors;
      });
      _filterDoctors();
    } on DioException catch (e) {
      setState(() {
        _error = 'Lỗi: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải danh sách bác sĩ: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _filterDoctors() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      var filtered = List<BookingDoctorItem>.from(_doctors);

      // Category filter
      if (_selectedCategory != 'Tất cả') {
        filtered = filtered.where((d) => 
          (d.specialtyName ?? '').toLowerCase() == _selectedCategory.toLowerCase()
        ).toList();
      }

      // Search filter
      if (query.isNotEmpty) {
        filtered = filtered.where((d) =>
            d.fullName.toLowerCase().contains(query) ||
            (d.specialtyName?.toLowerCase().contains(query) ?? false)).toList();
      }

      // Sort
      if (_selectedSort2 == 'Giá khám tăng dần') {
        filtered.sort((a, b) => (a.consultationFee ?? 0).compareTo(b.consultationFee ?? 0));
      } else if (_selectedSort2 == 'Giá khám giảm dần') {
        filtered.sort((a, b) => (b.consultationFee ?? 0).compareTo(a.consultationFee ?? 0));
      }

      _filteredDoctors = filtered;
    });
  }

  void _selectDoctor(BookingDoctorItem doctor) {
    if (_selectingDoctor) return;
    _selectingDoctor = true;
    Navigator.of(context).pop({
      'id': doctor.id,
      'fullName': doctor.fullName,
      'avatarUrl': doctor.avatarUrl,
      'specialtyName': doctor.specialtyName,
      'facilityId': doctor.facilityId,
      'consultationFee': doctor.consultationFee,
    });
  }

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
                  Navigator.of(context).maybePop();
                },
              ),
            ),
            title: const Text(
              'Bác sĩ nổi bật',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            centerTitle: false,
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
            colors: [Color(0xFFF7FBFF), Color(0xFFF0F8F6)],
            stops: [0.0, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm.....',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                            onPressed: () {
                              _searchCtrl.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                        _filterDoctors();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF14CBA8) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF14CBA8) : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF14CBA8),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Sort Row 1
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _sort1Options.map((option) {
                  final isSelected = _selectedSort1 == option;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedSort1 = option);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? const Color(0xFF7B61FF) : Colors.grey.shade400,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            option,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.black87 : Colors.grey.shade600,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Sort Row 2
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: _sort2Options.map((option) {
                  final isSelected = _selectedSort2 == option;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedSort2 = option);
                      _filterDoctors();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, top: 4, bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? const Color(0xFF7B61FF) : Colors.grey.shade400,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            option,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.black87 : Colors.grey.shade600,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Content List
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDoctors,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_filteredDoctors.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy bác sĩ phù hợp', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredDoctors.length,
      itemBuilder: (context, index) {
        final doctor = _filteredDoctors[index];
        return _DoctorCard(
          doctor: doctor,
          onTap: () => _selectDoctor(doctor),
          onTapDetail: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDoctorDetailScreen(doctor: doctor),
              ),
            );
            // If the detail screen pops with true, auto-select this doctor
            if (result == true) {
              _selectDoctor(doctor);
            }
          },
        );
      },
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({
    required this.doctor,
    required this.onTap,
    required this.onTapDetail,
  });

  final BookingDoctorItem doctor;
  final VoidCallback onTap;
  final VoidCallback onTapDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapDetail,
          borderRadius: BorderRadius.circular(16),
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Block
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5FA),
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
                                size: 40,
                              );
                            },
                          )
                        : const Icon(Icons.person, color: Color(0xFF9098B1), size: 40),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Doctor Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              doctor.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.favorite, color: Colors.red, size: 20),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.specialtyName ?? 'Chuyên khoa',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF14CBA8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action Bottom
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3A8DFF), Color(0xFF14CBA8)], // Approximate blue to teal
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Đặt ngay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// Utils exactly as before
List<dynamic> _unwrapItems(dynamic data) {
  if (data is Map<String, dynamic>) {
    final wrappedData = data['data'];
    if (wrappedData is List) return wrappedData;
    if (wrappedData is Map<String, dynamic>) {
      final nestedItems = wrappedData['items'];
      if (nestedItems is List) return nestedItems;
    }

    final items = data['items'];
    if (items is List) return items;
  }
  if (data is List) return data;
  return <dynamic>[];
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

double? _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
