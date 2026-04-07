import 'package:flutter/material.dart';

import '../../../core/network/admin_api_exception.dart';
import '../../../theme/admin_app_theme.dart';
import '../../doctors/data/admin_doctors_service.dart';
import '../../doctors/domain/admin_doctor.dart';
import '../data/admin_specialties_service.dart';
import '../domain/admin_specialty.dart';
import 'specialty_form_screen.dart';
import 'specialty_visuals.dart';

class AdminSpecialtiesScreen extends StatefulWidget {
  const AdminSpecialtiesScreen({
    super.key,
    AdminSpecialtiesService? specialtiesService,
    AdminDoctorsService? doctorsService,
  }) : _specialtiesService = specialtiesService,
       _doctorsService = doctorsService;

  final AdminSpecialtiesService? _specialtiesService;
  final AdminDoctorsService? _doctorsService;

  @override
  State<AdminSpecialtiesScreen> createState() => _AdminSpecialtiesScreenState();
}

class _AdminSpecialtiesScreenState extends State<AdminSpecialtiesScreen> {
  late final AdminSpecialtiesService _specialtiesService;
  late final AdminDoctorsService _doctorsService;

  List<AdminSpecialty> _specialties = const [];
  Map<String, int> _doctorCounts = const {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _specialtiesService =
        widget._specialtiesService ?? AdminSpecialtiesService();
    _doctorsService = widget._doctorsService ?? AdminDoctorsService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _specialtiesService.fetchSpecialties(),
        _doctorsService.fetchDoctors(limit: 100),
      ]);

      if (!mounted) {
        return;
      }

      final specialties = results[0] as List<AdminSpecialty>;
      final doctors = (results[1] as AdminDoctorsPage).items;

      setState(() {
        _specialties = specialties;
        _doctorCounts = _buildDoctorCounts(doctors);
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
            : 'Không thể tải danh sách chuyên khoa.';
      });
    }
  }

  Map<String, int> _buildDoctorCounts(List<AdminDoctor> doctors) {
    final counts = <String, int>{};
    for (final doctor in doctors) {
      counts.update(
        doctor.specialtyId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return counts;
  }

  Future<void> _openForm({AdminSpecialty? specialty}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SpecialtyFormScreen(
          specialty: specialty,
          suggestedSortOrder: specialty?.sortOrder ?? _specialties.length,
        ),
      ),
    );

    if (saved == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chuyên khoa',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(fontSize: 30),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_specialties.length} chuyên khoa',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        FloatingActionButton.small(
                          onPressed: () => _openForm(),
                          backgroundColor: AdminAppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          child: const Icon(Icons.add),
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
                    child: _SpecialtiesErrorState(
                      message: _errorMessage!,
                      onRetry: _loadData,
                    ),
                  )
                else if (_specialties.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _SpecialtiesEmptyState(),
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
                          children: _specialties.asMap().entries.map((entry) {
                            final index = entry.key;
                            final specialty = entry.value;
                            final isLast = index == _specialties.length - 1;

                            return Column(
                              children: [
                                _SpecialtyTile(
                                  specialty: specialty,
                                  doctorCount: _doctorCounts[specialty.id] ?? 0,
                                  onTap: () => _openForm(specialty: specialty),
                                ),
                                if (!isLast)
                                  Divider(
                                    height: 1,
                                    color: AdminAppTheme.border.withOpacity(
                                      0.95,
                                    ),
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
      ),
    );
  }
}

class _SpecialtyTile extends StatelessWidget {
  const _SpecialtyTile({
    required this.specialty,
    required this.doctorCount,
    required this.onTap,
  });

  final AdminSpecialty specialty;
  final int doctorCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = SpecialtyVisuals.fromSpecialty(specialty);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: visual.backgroundColor,
              ),
              child: Icon(visual.icon, size: 18, color: visual.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          specialty.name,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontSize: 16),
                        ),
                      ),
                      if (!specialty.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1D6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Ẩn',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: const Color(0xFFE39B17)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$doctorCount bác sĩ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
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

class _SpecialtiesEmptyState extends StatelessWidget {
  const _SpecialtiesEmptyState();

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
                Icons.local_hospital_outlined,
                size: 30,
                color: AdminAppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có chuyên khoa',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn nút cộng để tạo chuyên khoa đầu tiên cho hệ thống.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialtiesErrorState extends StatelessWidget {
  const _SpecialtiesErrorState({required this.message, required this.onRetry});

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
                'Không tải được chuyên khoa',
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
