import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/admin_api_exception.dart';
import '../../../theme/admin_app_theme.dart';
import '../../specialties/data/admin_specialties_service.dart';
import '../../specialties/domain/admin_specialty.dart';
import '../data/admin_doctors_service.dart';
import '../domain/admin_doctor.dart';
import 'doctor_form_screen.dart';
import '../../schedules/presentation/admin_schedules_view.dart';

class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({
    super.key,
    AdminDoctorsService? doctorsService,
    AdminSpecialtiesService? specialtiesService,
  }) : _doctorsService = doctorsService,
       _specialtiesService = specialtiesService;

  final AdminDoctorsService? _doctorsService;
  final AdminSpecialtiesService? _specialtiesService;

  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen> {
  late final AdminDoctorsService _doctorsService;
  late final AdminSpecialtiesService _specialtiesService;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<AdminDoctor> _doctors = const [];
  List<AdminSpecialty> _specialties = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _workingDoctorId;

  @override
  void initState() {
    super.initState();
    _doctorsService = widget._doctorsService ?? AdminDoctorsService();
    _specialtiesService =
        widget._specialtiesService ?? AdminSpecialtiesService();
    _searchController.addListener(_handleSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadDoctors);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _doctorsService.fetchDoctors(search: _searchController.text.trim()),
        _specialtiesService.fetchSpecialties(),
      ]);

      if (!mounted) {
        return;
      }

      final doctorsPage = results[0] as AdminDoctorsPage;
      final specialties = results[1] as List<AdminSpecialty>;

      setState(() {
        _doctors = doctorsPage.items;
        _specialties = specialties.where((item) => item.isActive).toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error is AdminApiException
            ? error.message
            : 'Không thể tải danh sách bác sĩ.';
      });
    }
  }

  Future<void> _loadDoctors() async {
    try {
      final doctorsPage = await _doctorsService.fetchDoctors(
        search: _searchController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _doctors = doctorsPage.items;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error is AdminApiException
            ? error.message
            : 'Không thể tải danh sách bác sĩ.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openDoctorForm({AdminDoctor? doctor}) async {
    if (_specialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có chuyên khoa để gán cho bác sĩ.')),
      );
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            DoctorFormScreen(doctor: doctor, specialties: _specialties),
      ),
    );

    if (saved == true) {
      await _loadData();
    }
  }

  Future<void> _toggleDoctor(AdminDoctor doctor, bool value) async {
    setState(() {
      _workingDoctorId = doctor.id;
    });

    try {
      await _doctorsService.updateDoctor(
        doctor.id,
        AdminDoctorPayload(
          fullName: doctor.fullName,
          phone: doctor.phone,
          email: doctor.email ?? '',
          password: '',
          specialtyId: doctor.specialtyId,
          title: doctor.title,
          licenseNumber: doctor.licenseNumber,
          bio: doctor.bio ?? '',
          yearsExperience: doctor.yearsExperience,
          consultationFee: doctor.consultationFee,
          isActive: value,
        ),
      );
      await _loadDoctors();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _workingDoctorId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _doctors.where((doctor) => doctor.isActive).length;

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: AdminAppTheme.primary,
                unselectedLabelColor: AdminAppTheme.textSecondary,
                indicatorColor: AdminAppTheme.primary,
                tabs: [
                  Tab(text: 'Hồ sơ Bác sĩ'),
                  Tab(text: 'Lịch làm việc'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildDoctorsList(activeCount),
                  const AdminSchedulesView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsList(int activeCount) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: RefreshIndicator(
          color: AdminAppTheme.primary,
          onRefresh: _loadData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bác sĩ',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontSize: 30),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$activeCount bác sĩ đang hoạt động',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          FloatingActionButton.small(
                            onPressed: () => _openDoctorForm(),
                            backgroundColor: AdminAppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm bác sĩ...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _DoctorsErrorState(
                    message: _errorMessage!,
                    onRetry: _loadData,
                  ),
                )
              else if (_doctors.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _DoctorsEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AdminAppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF25344D).withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: _doctors.asMap().entries.map((entry) {
                          final index = entry.key;
                          final doctor = entry.value;
                          final isLast = index == _doctors.length - 1;
                          final isWorking = _workingDoctorId == doctor.id;

                          return Column(
                            children: [
                              _DoctorTile(
                                doctor: doctor,
                                isWorking: isWorking,
                                onEdit: () => _openDoctorForm(doctor: doctor),
                                onOpen: () => _openDoctorForm(doctor: doctor),
                                onToggle: (value) =>
                                    _toggleDoctor(doctor, value),
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  color: AdminAppTheme.border.withOpacity(0.95),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  const _DoctorTile({
    required this.doctor,
    required this.isWorking,
    required this.onEdit,
    required this.onOpen,
    required this.onToggle,
  });

  final AdminDoctor doctor;
  final bool isWorking;
  final VoidCallback onEdit;
  final VoidCallback onOpen;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEFF4FF),
              ),
              alignment: Alignment.center,
              child: Text(
                doctor.initials,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AdminAppTheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${doctor.title}. ${doctor.fullName}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    doctor.specialtyName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF3F6FB),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                splashRadius: 18,
                onPressed: isWorking ? null : onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 17,
                  color: AdminAppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Transform.scale(
              scale: 0.92,
              child: Switch(
                value: doctor.isActive,
                onChanged: isWorking ? null : onToggle,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF1CCD8B),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AdminAppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorsEmptyState extends StatelessWidget {
  const _DoctorsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF0F4FB),
              ),
              child: const Icon(
                Icons.health_and_safety_outlined,
                size: 30,
                color: AdminAppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có bác sĩ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Danh sách bác sĩ sẽ hiển thị tại đây sau khi backend trả dữ liệu.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorsErrorState extends StatelessWidget {
  const _DoctorsErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AdminAppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFEEF0),
                ),
                child: const Icon(
                  Icons.sync_problem_rounded,
                  color: Color(0xFFFF5E63),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Không tải được bác sĩ',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AdminAppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
