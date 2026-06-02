import 'package:flutter/material.dart';

import '../../../core/api/dio_client.dart';
import '../../auth/services/auth_service.dart';
import 'doctor_detail_screen.dart';
import 'doctor_hub_models.dart';

/// `DoctorExploreScreen`
/// - Mục đích: màn hình tìm kiếm và lọc bác sĩ.
/// - Luồng: tải `specialties` và `doctors` từ API, sau đó áp filter cục bộ (search + specialty).
/// - Input: `initialSearch`, `initialSpecialty` để khởi tạo filter khi mở màn hình.
class DoctorExploreScreen extends StatefulWidget {
  const DoctorExploreScreen({
    super.key,
    required this.authService,
    this.initialSearch,
    this.initialSpecialty,
  });

  final AuthService authService;
  final String? initialSearch;
  final String? initialSpecialty;

  @override
  State<DoctorExploreScreen> createState() => _DoctorExploreScreenState();
}

/// State của `DoctorExploreScreen`.
/// Chứa state cho danh sách bác sĩ, chuyên khoa, text search và các helper để load/lọc dữ liệu.
class _DoctorExploreScreenState extends State<DoctorExploreScreen> {
  final DioClient _dioClient = DioClient();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<DoctorProfile> _doctors = <DoctorProfile>[];
  List<SpecialtyChoice> _specialties = <SpecialtyChoice>[];
  String _selectedSpecialty = 'Tất cả';

  @override
  void initState() {
    super.initState();
    // Khởi tạo value cho search field nếu có
    _searchCtrl.text = widget.initialSearch ?? '';
    // Gắn listener để tự động áp filters khi người dùng nhập
    _searchCtrl.addListener(_applyFilters);
    // Tải dữ liệu ban đầu (specialties + doctors)
    _loadData();
  }

  @override
  void dispose() {
    // Hủy controller để tránh memory leak
    _searchCtrl.dispose();
    super.dispose();
  }

  /// _loadData
  /// - Gọi API: `/specialties` và `/doctors`.
  /// - Map dữ liệu trả về sang `SpecialtyChoice` và `DoctorProfile`.
  /// - Đặt `_specialties` và `_doctors`, sau đó gọi `_applyFilters()` để render.
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final specialtiesResponse = await _dioClient.get('/specialties');
      final specialties = _unwrapItems(specialtiesResponse.data)
          .whereType<Map<String, dynamic>>()
          .map(SpecialtyChoice.fromApi)
          .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
          .toList();

      final doctorsResponse = await _dioClient.get(
        '/doctors',
        queryParameters: const {
          'page': 1,
          'limit': 100,
        },
      );
      final doctors = _unwrapItems(doctorsResponse.data)
          .whereType<Map<String, dynamic>>()
          .map(DoctorProfile.fromApi)
          .where((doctor) => doctor.id.isNotEmpty && doctor.name.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _specialties = specialties;
        _doctors = doctors;
        if (widget.initialSpecialty != null &&
            widget.initialSpecialty!.trim().isNotEmpty) {
          _selectedSpecialty = widget.initialSpecialty!;
        }
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được danh sách bác sĩ hoặc chuyên khoa.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// _unwrapItems
  /// - Helper để unpack payload API vào List
  /// - Hỗ trợ response dạng `{ data: [...] }`, `{ data: { items: [...] } }`, `{ items: [...] }` hoặc trực tiếp `[...]`.
  List<dynamic> _unwrapItems(dynamic data) {
    if (data is Map<String, dynamic>) {
      final wrapped = data['data'];
      if (wrapped is List) return wrapped;
      if (wrapped is Map<String, dynamic>) {
        final items = wrapped['items'];
        if (items is List) return items;
      }
      final items = data['items'];
      if (items is List) return items;
    }
    if (data is List) return data;
    return <dynamic>[];
  }

  /// _applyFilters
  /// - Trigger rebuild khi filter thay đổi. Logic lọc thật sự nằm ở getter `_filteredDoctors`.
  void _applyFilters() {
    if (!mounted) return;
    setState(() {});
  }

  /// `_filteredDoctors` getter
  /// - Áp dụng các filter cục bộ:
  ///    * `search` so sánh partial trên `name`, `specialty`, `focus`, tên cơ sở
  ///    * `specialty` so sánh exact (case-insensitive) với chip được chọn
  /// - Trả về danh sách đã sort theo `bookingToday` giảm dần
  List<DoctorProfile> get _filteredDoctors {
    final query = _searchCtrl.text.trim().toLowerCase();
    final specialty = _selectedSpecialty.trim().toLowerCase();

    final items = _doctors.where((doctor) {
      final matchSpecialty =
          specialty == 'tất cả' || doctor.specialty.toLowerCase() == specialty;
      final facilityName = doctor.facilities.isNotEmpty ? doctor.facilities.first.name : '';
      final matchSearch = query.isEmpty ||
          doctor.name.toLowerCase().contains(query) ||
          doctor.specialty.toLowerCase().contains(query) ||
          doctor.focus.toLowerCase().contains(query) ||
          facilityName.toLowerCase().contains(query);
      return matchSpecialty && matchSearch;
    }).toList();

    items.sort((a, b) => b.bookingToday.compareTo(a.bookingToday));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    // Build chịu trách nhiệm hiển thị các trạng thái: loading / error / empty / results
    final doctors = _filteredDoctors;
    final specialtyChips = <SpecialtyChoice>[
      const SpecialtyChoice(id: 'all', name: 'Tất cả'),
      ..._specialties,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  _RoundButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tìm kiếm và lọc bác sĩ',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF24354D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Tìm bác sĩ, chuyên khoa, cơ sở...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9AA9B8)),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF9AA9B8)),
                          onPressed: () {
                            _searchCtrl.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  hintStyle: const TextStyle(color: Color(0xFF99A8BC)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => _applyFilters(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final item = specialtyChips[index];
                  final isSelected = _selectedSpecialty == item.name ||
                      (_selectedSpecialty.isEmpty && item.name == 'Tất cả');
                  return ChoiceChip(
                    label: Text(item.name),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedSpecialty = item.name;
                      });
                      _applyFilters();
                    },
                    selectedColor: const Color(0xFFDBF6F5),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF1B7D78) : const Color(0xFF5B6D82),
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: specialtyChips.length,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && doctors.isEmpty
                      ? _ExploreErrorState(
                          message: _error!,
                          onRetry: _loadData,
                        )
                      : doctors.isEmpty
                          ? const _ExploreEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: doctors.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final doctor = doctors[index];
                                return _DoctorResultCard(
                                  doctor: doctor,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => DoctorDetailScreen(
                                          doctor: doctor,
                                          authService: widget.authService,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorResultCard extends StatelessWidget {
  const _DoctorResultCard({
    required this.doctor,
    required this.onTap,
  });

  final DoctorProfile doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final facility = doctor.facilities.isNotEmpty ? doctor.facilities.first : null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  doctor.imageUrl,
                  width: 82,
                  height: 82,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 82,
                    height: 82,
                    color: const Color(0xFFE6EEF6),
                    child: const Icon(Icons.person_rounded, color: Color(0xFFA8B6C5)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF24354D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      doctor.specialty,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17B6AE),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      facility == null ? 'Chưa có cơ sở' : facility.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6D7D90),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB74D), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          doctor.rating > 0 ? doctor.rating.toStringAsFixed(1) : '0.0',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF24354D),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${doctor.reviewCount} đánh giá)',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF7A8CA4)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          doctor.priceLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1AAE69),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF19C9B7), Color(0xFF2A8BFF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Xem chi tiết',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
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
      ),
    );
  }
}

/// `_DoctorResultCard`
/// - Hiển thị tóm tắt thông tin bác sĩ trong danh sách kết quả.
/// - Input: `doctor` (model) và `onTap` callback để mở chi tiết.

class _ExploreEmptyState extends StatelessWidget {
  const _ExploreEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Không có bác sĩ phù hợp với bộ lọc hiện tại.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF6D7D90),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

/// `_ExploreEmptyState`
/// - Component hiển thị khi không có bác sĩ phù hợp.

class _ExploreErrorState extends StatelessWidget {
  const _ExploreErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFFB04A4A),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

/// `_ExploreErrorState`
/// - Hiển thị thông báo lỗi và nút `Thử lại`.

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF24354D), size: 22),
        ),
      ),
    );
  }
}

/// `_RoundButton`
/// - Button tròn dùng ở header, nhận `icon` và `onTap`.
