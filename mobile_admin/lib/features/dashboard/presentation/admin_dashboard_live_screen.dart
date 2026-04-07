import 'package:flutter/material.dart';

import '../../../core/network/admin_api_exception.dart';
import '../../../theme/admin_app_theme.dart';
import '../data/admin_dashboard_service.dart';
import '../domain/admin_dashboard_overview.dart';

class AdminDashboardLiveScreen extends StatefulWidget {
  const AdminDashboardLiveScreen({
    super.key,
    this.greetingName = 'Admin',
    AdminDashboardService? service,
  }) : _service = service;

  final String greetingName;
  final AdminDashboardService? _service;

  @override
  State<AdminDashboardLiveScreen> createState() =>
      _AdminDashboardLiveScreenState();
}

class _AdminDashboardLiveScreenState extends State<AdminDashboardLiveScreen> {
  late final AdminDashboardService _service;

  AdminDashboardOverview? _overview;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? AdminDashboardService();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final overview = await _service.fetchOverview();
      if (!mounted) {
        return;
      }

      setState(() {
        _overview = overview;
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
            : 'Không thể tải dữ liệu dashboard.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            color: AdminAppTheme.primary,
            onRefresh: _loadOverview,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, ${widget.greetingName}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Admin Dashboard',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(fontSize: 34),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoading && overview == null)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_errorMessage != null && overview == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _DashboardErrorState(
                      message: _errorMessage!,
                      onRetry: _loadOverview,
                    ),
                  )
                else if (overview != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      child: Column(
                        children: [
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.06,
                            children: [
                              _MetricCard(
                                icon: Icons.calendar_month_rounded,
                                iconTint: const Color(0xFF4A90FF),
                                iconBackground: const Color(0xFFEAF2FF),
                                value: _formatNumber(
                                  overview.metrics.totalAppointments,
                                ),
                                label: 'Tổng lịch hẹn',
                              ),
                              _MetricCard(
                                icon: Icons.access_time_rounded,
                                iconTint: const Color(0xFFFFB323),
                                iconBackground: const Color(0xFFFFF4DC),
                                value: _formatNumber(
                                  overview.metrics.pendingAppointments,
                                ),
                                label: 'Chờ duyệt',
                              ),
                              _MetricCard(
                                icon: Icons.health_and_safety_rounded,
                                iconTint: const Color(0xFF16C7A1),
                                iconBackground: const Color(0xFFE6FBF6),
                                value: _formatNumber(
                                  overview.metrics.activeDoctors,
                                ),
                                label: 'Bác sĩ',
                              ),
                              _MetricCard(
                                icon: Icons.groups_2_rounded,
                                iconTint: const Color(0xFF4C8CFF),
                                iconBackground: const Color(0xFFEAF2FF),
                                value: _formatNumber(
                                  overview.metrics.totalPatients,
                                ),
                                label: 'Bệnh nhân',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _WeeklyAppointmentsCard(
                            points: overview.weeklyAppointments,
                          ),
                          const SizedBox(height: 16),
                          _RecentActivityCard(items: overview.recentActivities),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: const Color(0xFFE14D55)),
                            ),
                          ],
                        ],
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconTint,
    required this.iconBackground,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconTint;
  final Color iconBackground;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBackground,
            ),
            child: Icon(icon, color: iconTint, size: 18),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 22, height: 1.0),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _WeeklyAppointmentsCard extends StatelessWidget {
  const _WeeklyAppointmentsCard({required this.points});

  final List<AdminWeeklyAppointmentPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<int>(
      1,
      (max, item) => item.count > max ? item.count : max,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lịch hẹn trong tuần',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                'Tuần này',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AdminAppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((point) {
                final height = maxValue == 0
                    ? 12.0
                    : (point.count / maxValue) * 92;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${point.count}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 18,
                        height: height.clamp(12.0, 92.0).toDouble(),
                        decoration: BoxDecoration(
                          color: AdminAppTheme.primary.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        point.label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.items});

  final List<AdminRecentActivity> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoạt động gần đây',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Chưa có hoạt động gần đây',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _ActivityRow(item: items[i]),
              if (i != items.length - 1)
                Divider(
                  height: 1,
                  color: AdminAppTheme.border.withOpacity(0.95),
                ),
            ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final AdminRecentActivity item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFF0F3F8),
            child: Text(
              item.patientInitial,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: const Color(0xFF7A8395)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.patientName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  item.actionLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTimeAgo(item.occurredAt),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Không tải được dashboard',
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

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AdminAppTheme.card,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: AdminAppTheme.border),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF2F4159).withOpacity(0.05),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String _formatNumber(int value) {
  final text = value.toString();
  return text.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

String _formatTimeAgo(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inMinutes < 1) {
    return 'Vừa xong';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} phút trước';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours} giờ trước';
  }
  return '${difference.inDays} ngày trước';
}
