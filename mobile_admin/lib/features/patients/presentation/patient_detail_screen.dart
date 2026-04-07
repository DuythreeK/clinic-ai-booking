import 'package:flutter/material.dart';

import '../../../core/network/admin_api_exception.dart';
import '../../../theme/admin_app_theme.dart';
import '../data/admin_patients_service.dart';
import '../domain/admin_patient.dart';

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({
    super.key,
    required this.patientId,
    AdminPatientsService? service,
  }) : _service = service;

  final String patientId;
  final AdminPatientsService? _service;

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late final AdminPatientsService _service;
  AdminPatientProfile? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? AdminPatientsService();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _service.fetchPatientProfile(widget.patientId);
      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error is AdminApiException
            ? error.message
            : 'Không thể tải hồ sơ bệnh nhân.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _PatientDetailErrorState(
                    message: _errorMessage!,
                    onRetry: _loadProfile,
                  )
                : _PatientDetailBody(profile: _profile!),
          ),
        ),
      ),
    );
  }
}

class _PatientDetailBody extends StatelessWidget {
  const _PatientDetailBody({required this.profile});

  final AdminPatientProfile profile;

  @override
  Widget build(BuildContext context) {
    final patient = profile.patient;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AdminAppTheme.primary,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'Hồ sơ bệnh nhân',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 28),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AdminAppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25344D).withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEFF4FF),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    patient.initials,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AdminAppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.fullName,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      if ((patient.email ?? '').isNotEmpty)
                        Text(
                          patient.email!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      if (patient.phone.isNotEmpty)
                        Text(
                          patient.phone,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3DA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Chỉ xem (Read-only)',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: const Color(0xFFE39B17)),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Hồ sơ sức khỏe',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AdminAppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _HealthCard(
            icon: Icons.warning_amber_rounded,
            iconBackground: const Color(0xFFFFEEF0),
            iconColor: const Color(0xFFFF676D),
            title: 'Dị ứng',
            child: patient.allergyItems.isEmpty
                ? const _EmptyValue(label: 'Chưa có thông tin dị ứng')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: patient.allergyItems
                        .map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEEF0),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              item,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: const Color(0xFFFF676D)),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 12),
          _HealthCard(
            icon: Icons.vaccines_outlined,
            iconBackground: const Color(0xFFEFF4FF),
            iconColor: AdminAppTheme.primary,
            title: 'Thuốc đang sử dụng',
            child: profile.medications.isEmpty
                ? const _EmptyValue(label: 'Chưa có dữ liệu thuốc đang dùng')
                : Column(
                    children: profile.medications
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F8FC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AdminAppTheme.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    item.dosage,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 12),
          _HealthCard(
            icon: Icons.description_outlined,
            iconBackground: const Color(0xFFE8FBF3),
            iconColor: const Color(0xFF13B97A),
            title: 'Tiền sử bệnh',
            child: profile.history.isEmpty
                ? const _EmptyValue(label: 'Chưa có tiền sử bệnh được ghi nhận')
                : Column(
                    children: profile.history
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F8FC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AdminAppTheme.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF13B97A),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AdminAppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBackground,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EmptyValue extends StatelessWidget {
  const _EmptyValue({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.bodyMedium);
  }
}

class _PatientDetailErrorState extends StatelessWidget {
  const _PatientDetailErrorState({
    required this.message,
    required this.onRetry,
  });

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
                'Không tải được hồ sơ bệnh nhân',
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
