import 'package:flutter/material.dart';

/*
  FeaturedDoctorsScreen
  - Vai trò: Hiển thị danh sách "bác sĩ nổi bật" với bộ lọc, sắp xếp và tìm kiếm
  - Gọi backend: endpoint featured doctors (mobile) hoặc dùng local catalog cache
  - Lưu ý: chịu trách nhiệm UI/UX (search, tabs, sort) và delegate hành vi mở chi tiết
*/

import 'doctor_hub_models.dart';
import 'doctor_hub_widgets.dart';

class FeaturedDoctorsScreen extends StatefulWidget {
  const FeaturedDoctorsScreen({
    super.key,
    required this.onOpenDoctor,
    this.initialKeyword,
  });

  final ValueChanged<DoctorProfile> onOpenDoctor;
  final String? initialKeyword;

  @override
  State<FeaturedDoctorsScreen> createState() => _FeaturedDoctorsScreenState();
}

class _FeaturedDoctorsScreenState extends State<FeaturedDoctorsScreen> {
  final DoctorCatalog _catalog = DoctorCatalog.instance;
  late final TextEditingController _searchController;
  String _selectedCategory = 'Tất cả';
  String _selectedSort = DoctorSortOptions.options.first;

  static const _categories = ['Tất cả', 'Nha sĩ', 'Tim mạch', 'Thần kinh', 'Chỉnh hình'];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialKeyword ?? '');
    _catalog.loadRemote();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _catalog,
      builder: (context, _) {
        final doctors = _filteredDoctors();
        final loading = _catalog.isLoading && doctors.isEmpty;
        final error = _catalog.featuredError;
        return DoctorScaffold(
          title: 'Bác sĩ nổi bật',
          onBack: () => Navigator.of(context).maybePop(),
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    const SizedBox(height: 8),
                    DoctorSearchBar(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    DoctorCategoryTabs(
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      onSelect: (value) => setState(() => _selectedCategory = value),
                    ),
                    const SizedBox(height: 14),
                    DoctorSortOptions(
                      selectedSort: _selectedSort,
                      onSelect: (value) => setState(() => _selectedSort = value),
                    ),
                    const SizedBox(height: 10),
                    if (error != null && doctors.isEmpty)
                      StatusCard(
                        title: error,
                        subtitle: 'Kiểm tra backend, seed dữ liệu hoặc kết nối API.',
                        onRetry: () => _catalog.loadRemote(force: true),
                      )
                    else if (doctors.isEmpty)
                      const StatusCard(
                        title: 'Chưa có bác sĩ nổi bật',
                        subtitle: 'Backend hiện chưa trả dữ liệu phù hợp cho bộ lọc này.',
                      )
                    else
                      ...doctors.map(
                        (doctor) => DoctorCard(
                          doctor: doctor,
                          isFavorite: _catalog.isFavorite(doctor.id),
                          onFavorite: () => _catalog.toggleFavorite(doctor),
                          onTap: () => widget.onOpenDoctor(doctor),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  List<DoctorProfile> _filteredDoctors() {
    final keyword = _searchController.text.trim().toLowerCase();
    var doctors = _catalog.featuredDoctors.where((doctor) {
      final matchCategory = _selectedCategory == 'Tất cả' || doctor.specialty == _selectedCategory;
      final matchKeyword = keyword.isEmpty ||
          doctor.name.toLowerCase().contains(keyword) ||
          doctor.specialty.toLowerCase().contains(keyword) ||
          doctor.focus.toLowerCase().contains(keyword);
      return matchCategory && matchKeyword;
    }).toList();

    switch (_selectedSort) {
      case 'Đánh giá cao nhất':
        doctors.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Khám nhanh nhất':
        doctors.sort((a, b) => a.nextAvailable.compareTo(b.nextAvailable));
        break;
      case 'Giá khám tăng dần':
        doctors.sort((a, b) => a.priceValue.compareTo(b.priceValue));
        break;
      case 'Giá khám giảm dần':
        doctors.sort((a, b) => b.priceValue.compareTo(a.priceValue));
        break;
      default:
        doctors.sort((a, b) => b.bookingToday.compareTo(a.bookingToday));
    }

    return doctors;
  }
}



