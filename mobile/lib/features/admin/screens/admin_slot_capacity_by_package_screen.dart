import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/api/dio_client.dart';

class AdminSlotCapacityByPackageScreen extends StatefulWidget {
  const AdminSlotCapacityByPackageScreen({super.key});

  @override
  State<AdminSlotCapacityByPackageScreen> createState() =>
      _AdminSlotCapacityByPackageScreenState();
}

class _AdminSlotCapacityByPackageScreenState
    extends State<AdminSlotCapacityByPackageScreen> {
  final DioClient _dioClient = DioClient();
  final Map<int, TextEditingController> _capacityControllers =
      <int, TextEditingController>{};
  final Set<int> _savingSlotIds = <int>{};

  List<_AdminPackageItem> _packages = const <_AdminPackageItem>[];
  List<_AdminSlotItem> _slots = const <_AdminSlotItem>[];
  DateTime _selectedDate = DateTime.now();
  int? _selectedPackageId;
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
      final response = await _dioClient.get('/services/mobile/vaccination-packages');
      final items = _unwrapList(response.data);
      final packages = items
          .whereType<Map<String, dynamic>>()
          .map(_AdminPackageItem.fromApi)
          .where((item) => item.id > 0 && item.facilityId > 0)
          .toList();

      if (!mounted) return;
      setState(() {
        _packages = packages;
        _selectedPackageId = packages.isNotEmpty ? packages.first.id : null;
      });
      await _loadSlots();
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
        _error = 'Không tải được danh sách gói: $e';
      });
    }
  }

  Future<void> _loadSlots() async {
    final package = _selectedPackage;
    if (package == null) {
      if (!mounted) return;
      setState(() {
        _slots = const <_AdminSlotItem>[];
        _loading = false;
        _error = 'Không có gói để hiển thị.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final date = _toDateString(_selectedDate);
      final detailResponse = await _dioClient.get(
        '/services/${package.id}/mobile-vaccination-detail',
        queryParameters: {'date': date},
      );
      final slotsResponse = await _dioClient.get(
        '/slots',
        queryParameters: {
          'clinicId': package.facilityId.toString(),
          'fromDate': date,
          'toDate': date,
        },
      );

      final slotMap = <int, Map<String, dynamic>>{};
      for (final item in _unwrapList(slotsResponse.data).whereType<Map<String, dynamic>>()) {
        final slotId = _toInt(item['slot_id']);
        if (slotId > 0) {
          slotMap[slotId] = item;
        }
      }

      final detailData = _unwrapData(detailResponse.data);
      final groupedSlots = (detailData is Map<String, dynamic> ? detailData['slots'] : null) as List?;
      final result = <_AdminSlotItem>[];
      if (groupedSlots != null) {
        for (final group in groupedSlots.whereType<Map<String, dynamic>>()) {
          for (final key in const ['morningSlots', 'afternoonSlots']) {
            final entries = group[key];
            if (entries is! List) continue;
            for (final item in entries.whereType<Map<String, dynamic>>()) {
              final slotId = _toInt(item['slotId']);
              if (slotId <= 0) continue;
              final slotRaw = slotMap[slotId];

              final available = slotRaw == null
                  ? _toInt(item['availableCount'])
                  : _toInt(slotRaw['available_count']);
              final booked = slotRaw == null ? 0 : _toInt(slotRaw['booked_count']);
              final total = slotRaw == null
                  ? available + booked
                  : _toInt(slotRaw['total_capacity']);

              result.add(
                _AdminSlotItem(
                  id: slotId,
                  startTime: (item['startTime'] ?? '--:--').toString(),
                  endTime: (item['endTime'] ?? '--:--').toString(),
                  availableCount: available,
                  bookedCount: booked,
                  totalCapacity: total,
                  status: slotRaw == null ? 'AVAILABLE' : (slotRaw['status'] ?? 'AVAILABLE').toString(),
                ),
              );
            }
          }
        }
      }

      result.sort((a, b) {
        final cmp = a.startTime.compareTo(b.startTime);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });

      for (final entry in _capacityControllers.entries.toList()) {
        if (!result.any((slot) => slot.id == entry.key)) {
          entry.value.dispose();
          _capacityControllers.remove(entry.key);
        }
      }
      for (final slot in result) {
        final existing = _capacityControllers[slot.id];
        if (existing == null) {
          _capacityControllers[slot.id] =
              TextEditingController(text: slot.totalCapacity.toString());
        } else if (!_savingSlotIds.contains(slot.id)) {
          existing.text = slot.totalCapacity.toString();
        }
      }

      if (!mounted) return;
      setState(() {
        _slots = result;
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

  _AdminPackageItem? get _selectedPackage {
    if (_selectedPackageId == null) return null;
    for (final item in _packages) {
      if (item.id == _selectedPackageId) return item;
    }
    return null;
  }

  List<dynamic> _unwrapList(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        final items = data['items'];
        if (items is List) return items;
      }
    }
    return const <dynamic>[];
  }

  dynamic _unwrapData(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body['data'] ?? body;
    }
    return body;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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
    setState(() => controller.text = next.toString());
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
          'reason': 'Admin cập nhật theo gói từ UI mobile',
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
      if (mounted) setState(() => _savingSlotIds.remove(slot.id));
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
    final selectedPackage = _selectedPackage;
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
                    isExpanded: true,
                    value: _selectedPackageId,
                    decoration: _inputDeco('Gói khám/tiêm'),
                    items: _packages
                        .map(
                          (item) => DropdownMenuItem<int>(
                            value: item.id,
                            child: Text(item.title, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedPackageId = value);
                      _loadSlots();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD6E4EF)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 18,
                              color: Color(0xFF3E78C8),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _displayDate(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selectedPackage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD6E4EF)),
              ),
              child: Text(
                'Cơ sở: ${selectedPackage.facilityName}',
                style: const TextStyle(
                  color: Color(0xFF4D6178),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(message: _error!, onRetry: _loadSlots)
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: slot.status == 'FULL'
                                                  ? const Color(0xFFFFE6E6)
                                                  : const Color(0xFFE5FFF6),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              slot.status == 'FULL'
                                                  ? 'Đầy'
                                                  : 'Còn chỗ',
                                              style: TextStyle(
                                                color: slot.status == 'FULL'
                                                    ? const Color(0xFFD14D4D)
                                                    : const Color(0xFF0E9E78),
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
                                          _MetricChip(
                                            label: 'Đã đặt',
                                            value: slot.bookedCount.toString(),
                                            color: const Color(0xFF4C6FFF),
                                          ),
                                          const SizedBox(width: 8),
                                          _MetricChip(
                                            label: 'Còn chỗ',
                                            value: slot.availableCount.toString(),
                                            color: const Color(0xFF19BFA5),
                                          ),
                                          const SizedBox(width: 8),
                                          _MetricChip(
                                            label: 'Tổng chỗ',
                                            value: slot.totalCapacity.toString(),
                                            color: const Color(0xFFF1A942),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: isSaving
                                                ? null
                                                : () => _changeCapacityBy(slot, -1),
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 88,
                                            child: TextField(
                                              controller: controller,
                                              enabled: !isSaving,
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              decoration: _inputDeco('Tổng'),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: isSaving
                                                ? null
                                                : () => _changeCapacityBy(slot, 1),
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                          ),
                                          const Spacer(),
                                          ElevatedButton(
                                            onPressed: isSaving
                                                ? null
                                                : () => _saveCapacity(slot),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF2E8CF7),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child:
                                                Text(isSaving ? 'Đang lưu' : 'Lưu'),
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

class _AdminPackageItem {
  const _AdminPackageItem({
    required this.id,
    required this.title,
    required this.facilityId,
    required this.facilityName,
  });

  final int id;
  final String title;
  final int facilityId;
  final String facilityName;

  factory _AdminPackageItem.fromApi(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return _AdminPackageItem(
      id: toInt(json['id']),
      title: (json['title'] ?? '').toString(),
      facilityId: toInt(json['facilityId']),
      facilityName: (json['facilityName'] ?? '').toString(),
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
          const Icon(
            Icons.event_busy_outlined,
            size: 36,
            color: Color(0xFF97A8B8),
          ),
          const SizedBox(height: 8),
          const Text(
            'Không có slot cho gói và ngày đã chọn.',
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
