import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/api/dio_client.dart';
import '../../facilities/models/booking_facility_item.dart';
import '../../facilities/services/facility_service.dart';

class AdminSlotCapacityScreen extends StatefulWidget {
  const AdminSlotCapacityScreen({super.key});

  @override
  State<AdminSlotCapacityScreen> createState() => _AdminSlotCapacityScreenState();
}

class _AdminSlotCapacityScreenState extends State<AdminSlotCapacityScreen> {
  final DioClient _dioClient = DioClient();
  late final FacilityService _facilityService = FacilityService(dioClient: _dioClient);

  final Map<int, TextEditingController> _capacityControllers = <int, TextEditingController>{};
  final Set<int> _savingSlotIds = <int>{};

  List<BookingFacilityItem> _facilities = const <BookingFacilityItem>[];
  List<_AdminSlotItem> _slots = const <_AdminSlotItem>[];
  DateTime _selectedDate = DateTime.now();
  int? _selectedFacilityId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    for (final controller in _capacityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final facilities = await _facilityService.getFacilities();
      _facilities = facilities;
      _selectedFacilityId = facilities.isNotEmpty ? facilities.first.id : null;
      await _loadSlots();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được dữ liệu cơ sở: $e';
      });
    }
  }

  Future<void> _loadSlots() async {
    if (_selectedFacilityId == null) {
      if (!mounted) return;
      setState(() {
        _slots = const <_AdminSlotItem>[];
        _loading = false;
        _error = 'Không có cơ sở để hiển thị.';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final date = _toDateString(_selectedDate);
      final response = await _dioClient.get(
        '/slots',
        queryParameters: {
          'clinicId': _selectedFacilityId.toString(),
          'fromDate': date,
          'toDate': date,
        },
      );

      final raw = _unwrapList(response.data);
      final slots = raw
          .whereType<Map<String, dynamic>>()
          .map(_AdminSlotItem.fromApi)
          .where((item) => item.id > 0)
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      for (final entry in _capacityControllers.entries.toList()) {
        if (!slots.any((slot) => slot.id == entry.key)) {
          entry.value.dispose();
          _capacityControllers.remove(entry.key);
        }
      }
      for (final slot in slots) {
        final existing = _capacityControllers[slot.id];
        if (existing == null) {
          _capacityControllers[slot.id] = TextEditingController(text: slot.totalCapacity.toString());
        } else if (!_savingSlotIds.contains(slot.id)) {
          existing.text = slot.totalCapacity.toString();
        }
      }

      if (!mounted) return;
      setState(() {
        _slots = slots;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _extractErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được danh sách slot: $e';
      });
    }
  }

  List<dynamic> _unwrapList(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic> && data['items'] is List) {
        return data['items'] as List;
      }
    }
    return const <dynamic>[];
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
      if (message is List && message.isNotEmpty) {
        return message.map((item) => item.toString()).join(', ');
      }
    }
    return error.message ?? 'Lỗi không xác định';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    await _loadSlots();
  }

  Future<void> _changeCapacityBy(_AdminSlotItem slot, int delta) async {
    final controller = _capacityControllers[slot.id];
    if (controller == null) return;
    final current = int.tryParse(controller.text.trim()) ?? slot.totalCapacity;
    final next = current + delta;
    if (next < slot.bookedCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể thấp hơn số đã đặt (${slot.bookedCount}).')),
      );
      return;
    }
    setState(() {
      controller.text = next.toString();
    });
  }

  Future<void> _saveCapacity(_AdminSlotItem slot) async {
    final controller = _capacityControllers[slot.id];
    if (controller == null) return;
    final newCapacity = int.tryParse(controller.text.trim());
    if (newCapacity == null || newCapacity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tổng chỗ phải là số nguyên >= 0.')),
      );
      return;
    }
    if (newCapacity < slot.bookedCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tổng chỗ không thể thấp hơn số đã đặt (${slot.bookedCount}).')),
      );
      return;
    }

    setState(() => _savingSlotIds.add(slot.id));
    try {
      await _dioClient.patch(
        '/slots/${slot.id}/capacity',
        data: {
          'newCapacity': newCapacity,
          'reason': 'Admin cập nhật nhanh từ UI mobile',
        },
      );
      if (!mounted) return;
      await _loadSlots();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật chỗ thành công.')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extractErrorMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _savingSlotIds.remove(slot.id));
      }
    }
  }

  String _toDateString(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _displayDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FC),
      appBar: AppBar(
        title: const Text('Điều chỉnh chỗ cho lịch tiêm (Admin)'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedFacilityId,
                    decoration: _inputDeco('Cơ sở'),
                    items: _facilities
                        .map(
                          (item) => DropdownMenuItem<int>(
                            value: item.id,
                            child: Text(item.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      setState(() => _selectedFacilityId = value);
                      _loadSlots();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD6E4EF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF3E78C8)),
                        const SizedBox(width: 8),
                        Text(
                          _displayDate(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(
                        message: _error!,
                        onRetry: _loadSlots,
                      )
                    : _slots.isEmpty
                        ? _EmptyView(onRefresh: _loadSlots)
                        : RefreshIndicator(
                            onRefresh: _loadSlots,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: _slots.length,
                              itemBuilder: (context, index) {
                                final slot = _slots[index];
                                final controller = _capacityControllers[slot.id]!;
                                final isSaving = _savingSlotIds.contains(slot.id);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x10084A69),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
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
                                              '${slot.startTime} - ${slot.endTime}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF23395B),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: slot.status == 'FULL'
                                                  ? const Color(0xFFFFE6E6)
                                                  : const Color(0xFFE5FFF6),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              slot.status == 'FULL' ? 'Đầy' : 'Còn chỗ',
                                              style: TextStyle(
                                                color: slot.status == 'FULL' ? const Color(0xFFD14D4D) : const Color(0xFF0E9E78),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          _MetricChip(label: 'Đã đặt', value: slot.bookedCount.toString(), color: const Color(0xFF4C6FFF)),
                                          const SizedBox(width: 8),
                                          _MetricChip(label: 'Còn chỗ', value: slot.availableCount.toString(), color: const Color(0xFF19BFA5)),
                                          const SizedBox(width: 8),
                                          _MetricChip(label: 'Tổng chỗ', value: slot.totalCapacity.toString(), color: const Color(0xFFF1A942)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: isSaving ? null : () => _changeCapacityBy(slot, -1),
                                            icon: const Icon(Icons.remove_circle_outline),
                                          ),
                                          SizedBox(
                                            width: 88,
                                            child: TextField(
                                              controller: controller,
                                              enabled: !isSaving,
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              decoration: _inputDeco('Tổng'),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: isSaving ? null : () => _changeCapacityBy(slot, 1),
                                            icon: const Icon(Icons.add_circle_outline),
                                          ),
                                          const Spacer(),
                                          ElevatedButton(
                                            onPressed: isSaving ? null : () => _saveCapacity(slot),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF2E8CF7),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(isSaving ? 'Đang lưu' : 'Lưu'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}

class _AdminSlotItem {
  const _AdminSlotItem({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.availableCount,
    required this.bookedCount,
    required this.totalCapacity,
    required this.status,
  });

  final int id;
  final String startTime;
  final String endTime;
  final int availableCount;
  final int bookedCount;
  final int totalCapacity;
  final String status;

  factory _AdminSlotItem.fromApi(Map<String, dynamic> json) {
    final availableCount = _toInt(json['available_count']);
    final bookedCount = _toInt(json['booked_count']);
    final totalCapacity = _toInt(json['total_capacity']) > 0
        ? _toInt(json['total_capacity'])
        : availableCount + bookedCount;

    return _AdminSlotItem(
      id: _toInt(json['slot_id']),
      startTime: _timeLabel(json['start_time']),
      endTime: _timeLabel(json['end_time']),
      availableCount: availableCount,
      bookedCount: bookedCount,
      totalCapacity: totalCapacity,
      status: (json['status'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _timeLabel(dynamic raw) {
    final value = (raw ?? '').toString();
    if (value.isEmpty) return '--:--';

    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      final hh = parsed.hour.toString().padLeft(2, '0');
      final mm = parsed.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(value);
    if (match != null) {
      final hh = match.group(1)!.padLeft(2, '0');
      final mm = match.group(2)!;
      return '$hh:$mm';
    }

    return value;
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                onRetry();
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.onRefresh,
  });

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy_outlined, size: 36, color: Color(0xFF97A8B8)),
          const SizedBox(height: 8),
          const Text(
            'Không có slot cho ngày/cơ sở đã chọn.',
            style: TextStyle(color: Color(0xFF4D6178)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              onRefresh();
            },
            child: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }
}
