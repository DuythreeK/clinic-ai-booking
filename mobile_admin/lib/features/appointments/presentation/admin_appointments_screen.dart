import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/admin_api_config.dart';
import '../../../core/network/admin_api_exception.dart';
import '../../../theme/admin_app_theme.dart';
import '../data/admin_appointments_service.dart';
import '../domain/admin_appointment.dart';
import 'widgets/appointment_action_dialogs.dart';
import '../../patients/presentation/patient_detail_screen.dart';
class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({
    super.key,
    this.initialFilter,
    AdminAppointmentsService? service,
  }) : _service = service;

  final String? initialFilter;
  final AdminAppointmentsService? _service;

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  static const _filters = [
    _AppointmentFilter(key: 'all', label: 'Tất cả'),
    _AppointmentFilter(key: 'pending', label: 'Chờ duyệt'),
    _AppointmentFilter(key: 'confirmed', label: 'Đã xác nhận'),
    _AppointmentFilter(key: 'checked_in', label: 'Check-in'),
    _AppointmentFilter(key: 'in_progress', label: 'Đang khám'),
    _AppointmentFilter(key: 'completed', label: 'Hoàn thành'),
    _AppointmentFilter(key: 'no_show', label: 'Vắng mặt'),
    _AppointmentFilter(key: 'cancelled', label: 'Đã hủy'),
  ];

  late final AdminAppointmentsService _service;
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;
  List<AdminAppointment> _appointments = const [];
  bool _isLoading = true;
  String? _errorMessage;
  late String _selectedFilter;
  String? _workingAppointmentId;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'all';
    _service = widget._service ?? AdminAppointmentsService();
    _searchController.addListener(_handleSearchChanged);
    _loadAppointments();
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
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadAppointments();
    });
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.fetchAppointments(
        status: _selectedFilter == 'all' ? null : _selectedFilter,
        search: _searchController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _appointments = response.items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _appointments = const [];
        _isLoading = false;
        _errorMessage = error is AdminApiException
            ? error.message
            : 'Không thể tải danh sách lịch hẹn.';
      });
    }
  }

  Future<void> _updateAppointmentStatus(
    AdminAppointment appointment,
    String targetStatus, {
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color iconBackgroundColor,
    required String confirmLabel,
    Color? confirmColor,
    bool showPatientDetails = false,
  }) async {
    final approved =
        await showDialog<bool>(
          context: context,
          barrierColor: const Color(0x8A1E2533),
          builder: (context) => UpdateAppointmentStatusDialog(
            appointment: appointment,
            title: title,
            message: message,
            icon: icon,
            iconColor: iconColor,
            iconBackgroundColor: iconBackgroundColor,
            confirmLabel: confirmLabel,
            confirmColor: confirmColor,
            showPatientDetails: showPatientDetails,
          ),
        ) ??
        false;

    if (!approved || !mounted) {
      return;
    }

    setState(() {
      _workingAppointmentId = appointment.id;
    });

    try {
      await _service.updateAppointmentStatus(appointment.id, targetStatus);
      await _loadAppointments();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cập nhật trạng thái thành công.')));
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
          _workingAppointmentId = null;
        });
      }
    }
  }

  void _handleUpdateStatus(AdminAppointment appointment, String targetStatus) {
    String title = '';
    String message = '';
    IconData icon = Icons.info_rounded;
    Color iconColor = AdminAppTheme.primary;
    Color iconBackground = AdminAppTheme.primary.withValues(alpha: 0.1);
    String confirmLabel = 'Xác nhận';
    Color? confirmColor;

    switch (targetStatus) {
      case 'confirmed':
        title = 'Xác nhận lịch hẹn?';
        message =
            'Bạn có chắc muốn xác nhận lịch hẹn của ${appointment.patientName} với bác sĩ ${appointment.doctorName}?';
        icon = Icons.verified_rounded;
        iconColor = const Color(0xFF19BA73);
        iconBackground = const Color(0xFFE9FFF3);
        confirmLabel = 'Xác nhận';
        break;
      case 'checked_in':
        title = 'Bệnh nhân Check-in?';
        message =
            'Ghi nhận ${appointment.patientName} đã có mặt tại phòng chờ?';
        icon = Icons.how_to_reg_rounded;
        iconColor = const Color(0xFF19BA73);
        iconBackground = const Color(0xFFE9FFF3);
        confirmLabel = 'Check-in';
        break;
      case 'no_show':
        title = 'Đánh dấu Vắng mặt?';
        message =
            'Bệnh nhân ${appointment.patientName} không đến khám? Thao tác này sẽ không thể hoàn tác.';
        icon = Icons.person_off_rounded;
        iconColor = const Color(0xFFF9A000);
        iconBackground = const Color(0xFFFFF4DC);
        confirmLabel = 'Xác nhận Vắng mặt';
        confirmColor = const Color(0xFFF9A000);
        break;
      case 'in_progress':
        title = 'Bắt đầu khám?';
        message =
            'Chuyển trạng thái sang Đang khám cho ${appointment.patientName}?';
        icon = Icons.medical_services_rounded;
        iconColor = AdminAppTheme.primary;
        iconBackground = AdminAppTheme.primary.withValues(alpha: 0.1);
        confirmLabel = 'Bắt đầu';
        break;
      case 'completed':
        title = 'Hoàn thành ca khám?';
        message = 'Xác nhận ca khám của ${appointment.patientName} đã hoàn tất?';
        icon = Icons.done_all_rounded;
        iconColor = const Color(0xFF19BA73);
        iconBackground = const Color(0xFFE9FFF3);
        confirmLabel = 'Hoàn thành';
        break;
    }

    _updateAppointmentStatus(
      appointment,
      targetStatus,
      title: title,
      message: message,
      icon: icon,
      iconColor: iconColor,
      iconBackgroundColor: iconBackground,
      confirmLabel: confirmLabel,
      confirmColor: confirmColor,
      showPatientDetails: targetStatus == 'checked_in',
    );
  }

  Future<void> _cancelAppointment(AdminAppointment appointment) async {
    final reason = await showDialog<String>(
      context: context,
      barrierColor: const Color(0x8A1E2533),
      builder: (context) =>
          CancelAppointmentDialog(patientName: appointment.patientName),
    );

    if (reason == null || reason.trim().isEmpty || !mounted) {
      return;
    }

    setState(() {
      _workingAppointmentId = appointment.id;
    });

    try {
      await _service.cancelAppointment(
        appointment.id,
        cancelReason: reason.trim(),
      );
      await _loadAppointments();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã hủy lịch hẹn.')));
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
          _workingAppointmentId = null;
        });
      }
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
            onRefresh: _loadAppointments,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _AppointmentsHeader(),
                        const SizedBox(height: 14),
                        _AppointmentsSearchField(controller: _searchController),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _filters.map((filter) {
                            final selected = filter.key == _selectedFilter;
                            return ChoiceChip(
                              label: Text(filter.label),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedFilter = filter.key;
                                });
                                _loadAppointments();
                              },
                              showCheckmark: false,
                              backgroundColor: Colors.white,
                              selectedColor: AdminAppTheme.primary
                                  .withOpacity(0.14),
                              labelStyle: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: selected
                                        ? AdminAppTheme.primary
                                        : AdminAppTheme.textSecondary,
                                  ),
                              side: BorderSide(
                                color: selected
                                    ? Colors.transparent
                                    : AdminAppTheme.border,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                            );
                          }).toList(),
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
                    child: _AppointmentErrorState(
                      message: _errorMessage!,
                      onRetry: _loadAppointments,
                    ),
                  )
                else if (_appointments.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _AppointmentEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final appointment = _appointments[index];
                        final isWorking =
                            _workingAppointmentId == appointment.id;

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == _appointments.length - 1 ? 0 : 12,
                          ),
                          child: _AppointmentCard(
                            appointment: appointment,
                            isWorking: isWorking,
                            onUpdateStatus: (status) => _handleUpdateStatus(appointment, status),
                            onCancel:
                                appointment.isPending
                                ? () => _cancelAppointment(appointment)
                                : null,
                          ),
                        );
                      }, childCount: _appointments.length),
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

class _AppointmentsHeader extends StatelessWidget {
  const _AppointmentsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            splashRadius: 18,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: 22,
              color: AdminAppTheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lịch hẹn',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 2),
              Text(
                'Quản lý đơn đặt lịch khám',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppointmentsSearchField extends StatelessWidget {
  const _AppointmentsSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Tìm kiếm lịch hẹn...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: const Icon(
          Icons.tune_rounded,
          color: AdminAppTheme.textSecondary,
        ),
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
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.isWorking,
    required this.onUpdateStatus,
    required this.onCancel,
  });

  final AdminAppointment appointment;
  final bool isWorking;
  final void Function(String status)? onUpdateStatus;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusVisual(appointment.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AdminAppTheme.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25344D).withOpacity(0.05),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          appointment.patientName,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontSize: 16),
                        ),
                        if (appointment.isPending && appointment.patientPhone.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AdminAppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_rounded, size: 12, color: AdminAppTheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  appointment.patientPhone,
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AdminAppTheme.primary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${appointment.doctorDisplayName} · ${appointment.specialtyName}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusStyle.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  appointment.statusLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: statusStyle.foreground,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: AdminAppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  appointment.dateTimeLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
          if (appointment.isPending || appointment.isConfirmed || appointment.isCheckedIn || appointment.isInProgress || appointment.isCompleted) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (appointment.isPending) ...[
                  Expanded(
                    child: _ActionButton(
                      label: isWorking ? 'Xin chờ...' : 'Xác nhận',
                      backgroundColor: const Color(0xFF11C17B),
                      icon: Icons.check_rounded,
                      onPressed: isWorking ? null : () => onUpdateStatus?.call('confirmed'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: isWorking ? 'Xin chờ...' : 'Hủy',
                      backgroundColor: const Color(0xFFFF5E63),
                      icon: Icons.close_rounded,
                      onPressed: isWorking ? null : onCancel,
                    ),
                  ),
                ],
                if (appointment.isConfirmed) ...[
                  Expanded(
                    child: _ActionButton(
                      label: isWorking ? 'Xin chờ...' : 'Check-in',
                      backgroundColor: const Color(0xFF11C17B),
                      icon: Icons.how_to_reg_rounded,
                      onPressed: isWorking ? null : () => onUpdateStatus?.call('checked_in'),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ActionButton(
                      label: isWorking ? 'Xin chờ...' : 'Vắng',
                      backgroundColor: const Color(0xFFF9A000),
                      icon: Icons.person_off_rounded,
                      onPressed: isWorking ? null : () => onUpdateStatus?.call('no_show'),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ],
                if (appointment.isCheckedIn)
                  Expanded(
                    child: _ActionButton(
                      label: isWorking ? 'Xin chờ...' : 'Khám',
                      backgroundColor: const Color(0xFF4C8CFF),
                      icon: Icons.medical_services_rounded,
                      onPressed: isWorking ? null : () => onUpdateStatus?.call('in_progress'),
                    ),
                  ),
                if (appointment.isInProgress)
                  Expanded(
                    child: _ActionButton(
                      label: isWorking ? 'Xin chờ...' : 'Hoàn thành',
                      backgroundColor: const Color(0xFF16A96C),
                      icon: Icons.done_all_rounded,
                      onPressed: isWorking ? null : () => onUpdateStatus?.call('completed'),
                    ),
                  ),
                if (appointment.isCompleted)
                  Expanded(
                    child: _ActionButton(
                      label: isWorking ? 'Xin chờ...' : 'Xem hồ sơ',
                      backgroundColor: const Color(0xFF4280FF),
                      icon: Icons.assignment_ind_rounded,
                      onPressed: isWorking ? null : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PatientDetailScreen(
                              patientId: appointment.patientId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  _AppointmentStatusVisual _statusVisual(String status) {
    switch (status) {
      case 'pending':
        return const _AppointmentStatusVisual(
          background: Color(0xFFFFF3DE),
          foreground: Color(0xFFEA9A18),
        );
      case 'confirmed':
        return const _AppointmentStatusVisual(
          background: Color(0xFFE7FBF2),
          foreground: Color(0xFF16A96C),
        );
      case 'completed':
        return const _AppointmentStatusVisual(
          background: Color(0xFFE7F0FF),
          foreground: Color(0xFF4280FF),
        );
      case 'checked_in':
        return const _AppointmentStatusVisual(
          background: Color(0xFFE0F7FA),
          foreground: Color(0xFF00ACC1),
        );
      case 'in_progress':
        return const _AppointmentStatusVisual(
          background: Color(0xFFF3E5F5),
          foreground: Color(0xFF8E24AA),
        );
      case 'no_show':
        return const _AppointmentStatusVisual(
          background: Color(0xFFFFF3E0),
          foreground: Color(0xFFFB8C00),
        );
      case 'cancelled':
        return const _AppointmentStatusVisual(
          background: Color(0xFFFFE8EA),
          foreground: Color(0xFFFF5E63),
        );
      default:
        return const _AppointmentStatusVisual(
          background: Color(0xFFF1F4F9),
          foreground: AdminAppTheme.textSecondary,
        );
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.backgroundColor,
    required this.icon,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
  });

  final String label;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: backgroundColor.withOpacity(0.45),
        disabledForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: padding,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        iconColor: Colors.white,
      ),
    );
  }
}

class _AppointmentEmptyState extends StatelessWidget {
  const _AppointmentEmptyState();

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
                Icons.calendar_today_outlined,
                size: 28,
                color: AdminAppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có lịch hẹn',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Hiện tại chưa có lịch hẹn nào. Lịch hẹn mới sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentErrorState extends StatelessWidget {
  const _AppointmentErrorState({required this.message, required this.onRetry});

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
                'Không tải được lịch hẹn',
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

class _AppointmentFilter {
  const _AppointmentFilter({required this.key, required this.label});

  final String key;
  final String label;
}

class _AppointmentStatusVisual {
  const _AppointmentStatusVisual({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
