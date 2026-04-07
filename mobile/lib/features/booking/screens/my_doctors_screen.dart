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
  String _selectedCategory = 'Tat ca';
  String _selectedSort = DoctorSortOptions.options.first;

  static const _categories = ['Tat ca', 'Nha si', 'Tim mach', 'Than kinh', 'Chinh hinh'];

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
          title: 'Bac si cua toi',
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
                    'Ban chua tim bac si nao. Hay bam tim o trang Bac si noi bat de luu lai.',
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
      final matchCategory = _selectedCategory == 'Tat ca' || doctor.specialty == _selectedCategory;
      final matchKeyword = keyword.isEmpty ||
          doctor.name.toLowerCase().contains(keyword) ||
          doctor.specialty.toLowerCase().contains(keyword) ||
          doctor.focus.toLowerCase().contains(keyword);
      return matchCategory && matchKeyword;
    }).toList();

    switch (_selectedSort) {
      case 'Danh gia cao nhat':
        doctors.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Kham nhanh nhat':
        doctors.sort((a, b) => a.nextAvailable.compareTo(b.nextAvailable));
        break;
      case 'Gia kham tang dan':
        doctors.sort((a, b) => a.priceValue.compareTo(b.priceValue));
        break;
      case 'Gia kham giam dan':
        doctors.sort((a, b) => b.priceValue.compareTo(a.priceValue));
        break;
      default:
        doctors.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return doctors;
  }
}
