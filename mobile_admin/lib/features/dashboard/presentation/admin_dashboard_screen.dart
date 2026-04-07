import 'package:flutter/material.dart';

import '../../../theme/admin_app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const List<_DashboardMetric> _metrics = [
    _DashboardMetric(
      icon: Icons.calendar_month_rounded,
      iconTint: Color(0xFF4A90FF),
      iconBackground: Color(0xFFEAF2FF),
      value: '1,248',
      label: 'Tổng lịch hẹn',
    ),
    _DashboardMetric(
      icon: Icons.access_time_rounded,
      iconTint: Color(0xFFFFB323),
      iconBackground: Color(0xFFFFF4DC),
      value: '32',
      label: 'Chờ duyệt',
    ),
    _DashboardMetric(
      icon: Icons.health_and_safety_rounded,
      iconTint: Color(0xFF16C7A1),
      iconBackground: Color(0xFFE6FBF6),
      value: '48',
      label: 'Bác sĩ',
    ),
    _DashboardMetric(
      icon: Icons.groups_2_rounded,
      iconTint: Color(0xFF4C8CFF),
      iconBackground: Color(0xFFEAF2FF),
      value: '3,621',
      label: 'Bệnh nhân',
    ),
  ];

  static const List<_ActivityItem> _activities = [
    _ActivityItem(
      initial: 'N',
      name: 'Nguyễn Văn A',
      action: 'Đặt lịch khám',
      time: '5 phút trước',
    ),
    _ActivityItem(
      initial: 'T',
      name: 'Trần Thị B',
      action: 'Hủy lịch hẹn',
      time: '12 phút trước',
    ),
    _ActivityItem(
      initial: 'L',
      name: 'Lê Văn C',
      action: 'Hoàn thành khám',
      time: '30 phút trước',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, Admin',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Admin Dashboard',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontSize: 34),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _metrics.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.06,
                  ),
                  itemBuilder: (context, index) {
                    return _MetricCard(metric: _metrics[index]);
                  },
                ),
                const SizedBox(height: 16),
                const _WeeklyAppointmentsCard(),
                const SizedBox(height: 16),
                _RecentActivityCard(items: _activities),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _DashboardMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: metric.iconBackground,
            ),
            child: Icon(metric.icon, color: metric.iconTint, size: 18),
          ),
          const Spacer(),
          Text(
            metric.value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 22, height: 1.0),
          ),
          const SizedBox(height: 6),
          Text(
            metric.label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _WeeklyAppointmentsCard extends StatelessWidget {
  const _WeeklyAppointmentsCard();

  static const List<String> _days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lịch hẹn trong tuần',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 18),
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
          AspectRatio(
            aspectRatio: 1.85,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFDFEFF), Color(0xFFF8FAFD)],
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
                      child: CustomPaint(
                        painter: _ChartGridPainter(),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _days
                          .map(
                            (day) => Text(
                              day,
                              style: Theme.of(
                                context,
                              ).textTheme.labelMedium?.copyWith(fontSize: 11),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.items});

  final List<_ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoạt động gần đây',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < items.length; i++) ...[
            _ActivityRow(item: items[i]),
            if (i != items.length - 1)
              Divider(height: 1, color: AdminAppTheme.border.withOpacity(0.95)),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final _ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF0F3F8),
              border: Border.all(color: AdminAppTheme.border),
            ),
            alignment: Alignment.center,
            child: Text(
              item.initial,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF7A8395),
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
                  item.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  item.action,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(item.time, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _ChartGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFEAEFF6)
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final glowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x0D3D7DFF), Color(0x003D7DFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);

    final linePaint = Paint()
      ..color = const Color(0x553D7DFF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.53,
        size.width * 0.28,
        size.height * 0.58,
      )
      ..quadraticBezierTo(
        size.width * 0.44,
        size.height * 0.64,
        size.width * 0.58,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.32,
        size.width * 0.86,
        size.height * 0.38,
      )
      ..quadraticBezierTo(
        size.width * 0.95,
        size.height * 0.42,
        size.width,
        size.height * 0.3,
      );

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashboardMetric {
  const _DashboardMetric({
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
}

class _ActivityItem {
  const _ActivityItem({
    required this.initial,
    required this.name,
    required this.action,
    required this.time,
  });

  final String initial;
  final String name;
  final String action;
  final String time;
}
