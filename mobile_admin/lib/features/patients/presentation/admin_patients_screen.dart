import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/admin_api_exception.dart';
import '../../../theme/admin_app_theme.dart';
import '../data/admin_patients_service.dart';
import '../domain/admin_patient.dart';
import 'patient_detail_screen.dart';

class AdminPatientsScreen extends StatefulWidget {
  const AdminPatientsScreen({super.key, AdminPatientsService? service})
    : _service = service;

  final AdminPatientsService? _service;

  @override
  State<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends State<AdminPatientsScreen> {
  late final AdminPatientsService _service;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<AdminPatient> _patients = const [];
  int _total = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? AdminPatientsService();
    _searchController.addListener(_handleSearchChanged);
    _loadPatients();
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
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadPatients);
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final page = await _service.fetchPatients(
        search: _searchController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _patients = page.items;
        _total = page.total;
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
            : 'Không thể tải danh sách bệnh nhân.';
      });
    }
  }

  Future<void> _openPatient(AdminPatient patient) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientDetailScreen(patientId: patient.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _searchController.text.trim().isEmpty
        ? '$_total bệnh nhân đã đăng ký'
        : 'Quản lý thông tin bệnh nhân';

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            color: AdminAppTheme.primary,
            onRefresh: _loadPatients,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bệnh nhân',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 30),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm bệnh nhân...',
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
                    child: _PatientsErrorState(
                      message: _errorMessage!,
                      onRetry: _loadPatients,
                    ),
                  )
                else if (_patients.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _PatientsEmptyState(
                      hasKeyword: _searchController.text.trim().isNotEmpty,
                    ),
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
                          children: _patients.asMap().entries.map((entry) {
                            final index = entry.key;
                            final patient = entry.value;
                            final isLast = index == _patients.length - 1;

                            return Column(
                              children: [
                                _PatientTile(
                                  patient: patient,
                                  onTap: () => _openPatient(patient),
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

class _PatientTile extends StatelessWidget {
  const _PatientTile({required this.patient, required this.onTap});

  final AdminPatient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEFF4FF),
              ),
              alignment: Alignment.center,
              child: Text(
                patient.initials,
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
                    patient.fullName,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    (patient.email ?? '').isNotEmpty
                        ? patient.email!
                        : patient.phone,
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

class _PatientsEmptyState extends StatelessWidget {
  const _PatientsEmptyState({required this.hasKeyword});

  final bool hasKeyword;

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
                Icons.groups_2_outlined,
                size: 30,
                color: AdminAppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasKeyword ? 'Không tìm thấy bệnh nhân' : 'Chưa có bệnh nhân',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              hasKeyword
                  ? 'Thử tìm kiếm với từ khóa khác hoặc kiểm tra lại bộ lọc.'
                  : 'Danh sách bệnh nhân sẽ hiển thị tại đây khi backend trả dữ liệu.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientsErrorState extends StatelessWidget {
  const _PatientsErrorState({required this.message, required this.onRetry});

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
              Text(
                'Không tải được bệnh nhân',
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
