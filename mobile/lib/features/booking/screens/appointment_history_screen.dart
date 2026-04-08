import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/dio_client.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({
    super.key,
    required this.dioClient,
  });

  final DioClient dioClient;

  @override
  State<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _appointments = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await widget.dioClient.get('/appointments');
      if (mounted) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          setState(() {
            _appointments = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _appointments = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load appointments.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return '0đ';
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount);
  }

  Widget _buildDateBox(String dateStr, bool isUpcoming) {
    // Expected dateStr format: YYYY-MM-DD
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {
      date = DateTime.now();
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = 'Tháng ${date.month}';
    final year = date.year.toString();

    final boxColor = isUpcoming ? const Color(0xFF14CBA8) : const Color(0xFF868686);
    final badgeColor = isUpcoming ? const Color(0xFFE2F7F2) : Colors.transparent;
    final badgeTextColor = isUpcoming ? const Color(0xFF14CBA8) : Colors.transparent;
    final badgeText = isUpcoming ? 'NEW' : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                day,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                month,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                year,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (isUpcoming) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildStatusBadge(bool isUpcoming) {
    final bgColor = isUpcoming ? const Color(0xFF14CBA8) : const Color(0xFF868686);
    final text = isUpcoming ? 'Chuẩn bị khám' : 'Kết thúc';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPricePill(double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF0FC), // light purple/blue
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatCurrency(amount),
        style: const TextStyle(
          color: Color(0xFF6B72D6), // purple text
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> apt) {
    final statusStr = apt['status']?.toString() ?? 'pending';
    final isUpcoming = statusStr == 'pending' || statusStr == 'confirmed';
    
    final dateStr = apt['appointmentDate']?.toString() ?? '';
    
    // Title is symptoms note, fallback to service name
    String title = 'Khám bệnh';
    if (apt['symptomsNote'] != null && apt['symptomsNote'].toString().isNotEmpty) {
      title = apt['symptomsNote'].toString();
    } else if (apt['service'] != null && apt['service']['name'] != null) {
      title = apt['service']['name'].toString();
    }

    final amount = double.tryParse(apt['totalAmount']?.toString() ?? '0') ?? 0;

    String doctorName = 'Chưa phân bổ';
    String specialtyName = '';
    String? doctorImageUrl;

    if (apt['doctor'] != null) {
      doctorName = apt['doctor']['name'] ?? doctorName;
      specialtyName = apt['doctor']['specialty'] ?? '';
      doctorImageUrl = apt['doctor']['imageUrl'];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateBox(dateStr, isUpcoming),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF202020),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new_rounded,
                      color: Color(0xFFF1B01D), // orange-ish icon
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFFE2F5FF),
                      backgroundImage: doctorImageUrl != null ? NetworkImage(doctorImageUrl) : null,
                      child: doctorImageUrl == null 
                        ? const Icon(Icons.person, size: 16, color: Color(0xFF14CBA8))
                        : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$doctorName${specialtyName.isNotEmpty ? ' - $specialtyName' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF14CBA8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildPricePill(amount),
                    const SizedBox(width: 12),
                    _buildStatusBadge(isUpcoming),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE2F5FF), Color(0xFFE2F8EE)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 20),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF9098B1),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Lịch hẹn',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_error!, style: const TextStyle(color: Colors.red)),
                                ElevatedButton(
                                  onPressed: _fetchAppointments,
                                  child: const Text('Thử lại'),
                                )
                              ],
                            ),
                          )
                        : _appointments.isEmpty
                            ? const Center(child: Text('Chưa có lịch sử khám nào.'))
                            : RefreshIndicator(
                                onRefresh: _fetchAppointments,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _appointments.length,
                                  itemBuilder: (context, index) {
                                    return _buildAppointmentCard(_appointments[index]);
                                  },
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
