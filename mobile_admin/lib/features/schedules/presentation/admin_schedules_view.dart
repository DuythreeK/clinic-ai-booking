import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/admin_api_exception.dart';
import '../../../theme/admin_app_theme.dart';
import '../data/admin_schedules_service.dart';
import '../domain/admin_schedule.dart';
import 'schedule_form_screen.dart';

class AdminSchedulesView extends StatefulWidget {
  const AdminSchedulesView({super.key});

  @override
  State<AdminSchedulesView> createState() => _AdminSchedulesViewState();
}

class _AdminSchedulesViewState extends State<AdminSchedulesView> {
  late final AdminSchedulesService _service;

  List<AdminSchedule> _schedules = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = AdminSchedulesService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _service.fetchSchedules();
      if (!mounted) return;
      setState(() {
        _schedules = items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error is AdminApiException
            ? error.message
            : 'Không thể tải danh sách lịch làm việc.';
      });
    }
  }

  Future<void> _openForm({AdminSchedule? schedule}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ScheduleFormScreen(schedule: schedule)),
    );
    if (saved == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
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
                          'Lịch làm việc',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 30),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_schedules.length} ca trực trên hệ thống',
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(_errorMessage!)),
              ),
            )
          else if (_schedules.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text("Chưa có lịch làm việc nào")),
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
                  ),
                  child: Column(
                    children: _schedules.asMap().entries.map((entry) {
                      final schedule = entry.value;
                      final isLast = entry.key == _schedules.length - 1;

                      final dateFormat = DateFormat('dd/MM/yyyy');
                      final timeFormat = DateFormat('HH:mm');

                      return Column(
                        children: [
                          InkWell(
                            onTap: () => _openForm(schedule: schedule),
                            borderRadius: BorderRadius.circular(24),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFF0F4FB),
                                    ),
                                    child: const Icon(
                                      Icons.event_available,
                                      color: AdminAppTheme.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${schedule.doctorTitle ?? "BS"}. ${schedule.doctorName}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(fontSize: 15),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Ngày: ${dateFormat.format(schedule.workDate)}  •  C: ${timeFormat.format(schedule.startTime)} - ${timeFormat.format(schedule.endTime)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color:
                                                    AdminAppTheme.textSecondary,
                                                fontSize: 13,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${schedule.roomName ?? "Đang chờ phân phòng"}  •  ${schedule.bookedSlots}/${schedule.maxSlots} Slots',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontSize: 13,
                                                color: AdminAppTheme.primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!schedule.isAvailable)
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
                                        'Hủy/Khóa',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: const Color(0xFFE39B17),
                                            ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AdminAppTheme.textSecondary,
                                  ),
                                ],
                              ),
                            ),
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
    );
  }
}
