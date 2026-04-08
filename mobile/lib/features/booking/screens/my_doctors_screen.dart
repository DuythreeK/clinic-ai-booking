import 'package:flutter/material.dart';

import 'doctor_hub_models.dart';
import 'doctor_hub_widgets.dart';

class MyDoctorsScreen extends StatefulWidget {
  const MyDoctorsScreen({
    super.key,
    required this.onOpenDoctor,
  });

  final ValueChanged<DoctorProfile> onOpenDoctor;

  @override
  State<MyDoctorsScreen> createState() => _MyDoctorsScreenState();
}

class _MyDoctorsScreenState extends State<MyDoctorsScreen> {
  final DoctorCatalog _catalog = DoctorCatalog.instance;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tất cả';
  String _selectedSort = DoctorSortOptions.options.first;

  static const _categories = ['Tất cả', 'Nha sĩ', 'Tim mạch', 'Thần kinh', 'Chỉnh hình'];

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
        return DoctorScaffold(
          title: 'Bác sĩ của tôi',
          child: ListView(
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
              if (doctors.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Text(
                    'Bạn chưa tim bác sĩ nào. Hãy bấm tim ở trang Bác sĩ nổi bật để lưu lại.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF6E829C)),
                  ),
                ),
              ...doctors.map(
                (doctor) => DoctorCard(
                  doctor: doctor,
                  isFavorite: _catalog.isFavorite(doctor.id),
                  onFavorite: () => _catalog.toggleFavorite(doctor.id),
                  onTap: () => widget.onOpenDoctor(doctor),
                  showBookingHint: false,
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
    var doctors = _catalog.myDoctors.where((doctor) {
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
        doctors.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return doctors;
  }
}
