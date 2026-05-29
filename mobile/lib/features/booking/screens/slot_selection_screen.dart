import 'package:flutter/material.dart';

/*
  SlotSelectionScreen
  - Vai trò: Hiển thị các ca khám có sẵn cho bác sĩ + cơ sở (calendar + timeslots)
  - Gọi backend: `/slots/available` với params `doctorId`, `clinicId`, `fromDate`, `toDate`
  - Lưu ý: trang này parse response từ backend và trả về `slotId`, `date`, `time` cho caller
*/

import '../../../core/api/dio_client.dart';

class SlotSelectionScreen extends StatefulWidget {
  const SlotSelectionScreen({
    super.key,
    required this.doctorId,
    required this.facilityId,
    required this.dioClient,
  });

  final int doctorId;
  final int facilityId;
  final DioClient dioClient;

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  late DateTime _selectedDate;
  _SlotItem? _selectedSlot;
  String _selectedReminder = '30 phút';
  bool _selectingSlot = false;

  bool _loadingSlots = false;
  String? _slotError;
  Map<String, List<_SlotItem>> _slotsByDate = <String, List<_SlotItem>>{};

  static const List<String> _reminders = [
    '10 phút',
    '20 phút',
    '30 phút',
    '40 phút',
    '60 phút',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadSlotsForCurrentMonth();
  }

  List<_SlotItem> get _timeSlots {
    final dateKey = _dateOnly(_selectedDate);
    final slots = _slotsByDate[dateKey] ?? <_SlotItem>[];
    final map = <String, _SlotItem>{};
    for (final s in slots) map[s.time] = s;
    final keys = map.keys.toList()..sort();
    return keys.map((k) => map[k]!).toList();
  }

  Future<void> _loadSlotsForCurrentMonth() async {
    setState(() {
      _loadingSlots = true;
      _slotError = null;
    });

    final fromDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final toDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    try {
      final response = await widget.dioClient.get(
        '/slots/available',
        queryParameters: {
          'doctorId': widget.doctorId,
          'clinicId': widget.facilityId,
          'fromDate': _dateOnly(fromDate),
          'toDate': _dateOnly(toDate),
        },
      );

      debugPrint('[SlotSelection] Raw response type: ${response.data.runtimeType}');
      debugPrint('[SlotSelection] Raw response: ${response.data}');

      final items = _unwrapList(response.data);
      final byDate = <String, List<_SlotItem>>{};

      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;

        final slotIdRaw = item['slot_id'];
        final slotDateRaw = item['slot_date'];
        final startTimeRaw = item['start_time'];
        if (slotIdRaw == null || slotDateRaw == null || startTimeRaw == null) continue;

        final key = _extractDateKey(slotDateRaw.toString());
        final value = _extractTimeHHmm(startTimeRaw.toString());
        final id = int.tryParse(slotIdRaw.toString()) ?? 0;
        if (key == null || value == null || id == 0) continue;

        byDate.putIfAbsent(key, () => <_SlotItem>[]).add(_SlotItem(id, value));
      }

      debugPrint('[SlotSelection] Parsed ${byDate.length} date entries: ${byDate.keys.toList()}');

      setState(() {
        _slotsByDate = byDate;
        if (_selectedSlot != null) {
          final exists = _timeSlots.any((s) => s.id == _selectedSlot!.id);
          if (!exists) _selectedSlot = null;
        }
        // Auto-select first date with slots if current date has none
        final currentKey = _dateOnly(_selectedDate);
        if (!byDate.containsKey(currentKey) && byDate.isNotEmpty) {
          final sortedKeys = byDate.keys.toList()..sort();
          // Find first future date with slots
          final today = _dateOnly(DateTime.now());
          final futureKey = sortedKeys.firstWhere(
            (k) => k.compareTo(today) >= 0,
            orElse: () => sortedKeys.first,
          );
          final parts = futureKey.split('-');
          if (parts.length == 3) {
            _selectedDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
        }
      });
    } catch (e) {
      setState(() {
        _slotError = 'Lỗi tải ca khám: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSlots = false;
        });
      }
    }
  }

  void _selectSlot() {
    if (_selectingSlot) return;

    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giờ khám')),
      );
      return;
    }

    _selectingSlot = true;
    Navigator.of(context).pop(
      {
        'date': _selectedDate,
        'time': _selectedSlot!.time,
        'slotId': _selectedSlot!.id,
        'reminder': _selectedReminder,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
        title: const Text('Đặt lịch hẹn'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selector - Calculator style
            _buildDateSelector(),
            const SizedBox(height: 24),

            // Time slots
            _buildTimeSlots(),
            const SizedBox(height: 24),

            // Reminder
            _buildReminder(),
            const SizedBox(height: 32),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1BC47D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _selectSlot,
                child: const Text(
                  'Xác nhận',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final daysInMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    ).day;

    final firstDayOfMonth =
        DateTime(_selectedDate.year, _selectedDate.month, 1);
    final startingDayWeek = firstDayOfMonth.weekday;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month/Year header with nav arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month - 1,
                    );
                    _selectedSlot = null;
                  });
                  _loadSlotsForCurrentMonth();
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1BC47D),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_selectedDate.month} - ${_selectedDate.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                    );
                    _selectedSlot = null;
                  });
                  _loadSlotsForCurrentMonth();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day of week header
          Row(
            children: const [
              _DayHeader('T2'),
              _DayHeader('T3'),
              _DayHeader('T4'),
              _DayHeader('T5'),
              _DayHeader('T6'),
              _DayHeader('T7'),
              _DayHeader('CN'),
            ],
          ),
          const SizedBox(height: 8),

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 4,
            ),
            itemCount: startingDayWeek + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startingDayWeek) {
                return const SizedBox();
              }

              final day = index - startingDayWeek + 1;
              final date = DateTime(_selectedDate.year, _selectedDate.month, day);
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final hasSlots = _slotsByDate.containsKey(_dateOnly(date));

              return GestureDetector(
                onTap: date.isBefore(now)
                    ? null
                    : () {
                        setState(() {
                          _selectedDate = date;
                          if (_selectedSlot != null) {
                            final exists = _timeSlots.any((s) => s.id == _selectedSlot!.id);
                            if (!exists) _selectedSlot = null;
                          }
                        });
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1BC47D)
                        : date.isBefore(now)
                            ? Colors.grey.shade100
                            : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1BC47D)
                          : hasSlots
                              ? const Color(0xFF1BC47D).withOpacity(0.4)
                              : Colors.transparent,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : date.isBefore(now)
                                  ? Colors.grey.shade400
                                  : Colors.black,
                        ),
                      ),
                      if (hasSlots && !isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1BC47D),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots() {
    if (_loadingSlots) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_slotError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_slotError!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadSlotsForCurrentMonth,
            child: const Text('Tải lại ca khám'),
          ),
        ],
      );
    }

    if (_timeSlots.isEmpty) {
      return const Text(
        'Không có ca khám khả dụng cho ngày đã chọn.',
        style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thời gian khám',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, index) {
            final slot = _timeSlots[index];
            final time = slot.time;
            final isSelected = _selectedSlot?.id == slot.id;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSlot = slot;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1BC47D)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  time,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReminder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nhắc tôi trước',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: _reminders.length,
          itemBuilder: (context, index) {
            final reminder = _reminders[index];
            final isSelected = _selectedReminder == reminder;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedReminder = reminder;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1BC47D)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  reminder,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF667085),
          ),
        ),
      ),
    );
  }
}

List<dynamic> _unwrapList(dynamic data) {
  if (data is List) return data;
  if (data is Map<String, dynamic>) {
    final wrappedData = data['data'];
    if (wrappedData is List) return wrappedData;
    if (wrappedData is Map<String, dynamic>) {
      final nestedItems = wrappedData['items'];
      if (nestedItems is List) return nestedItems;
    }
    final items = data['items'];
    if (items is List) return items;
  }
  return <dynamic>[];
}

String _dateOnly(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _hhmm(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

/// Extract date key "YYYY-MM-DD" from various formats:
/// - ISO: "2026-04-08T00:00:00.000Z"
/// - Date only: "2026-04-08"
String? _extractDateKey(String raw) {
  // Try ISO parse first
  try {
    final dt = DateTime.parse(raw);
    return _dateOnly(dt);
  } catch (_) {}

  // Try raw date string YYYY-MM-DD
  final dateMatch = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(raw);
  if (dateMatch != null) return dateMatch.group(1);

  return null;
}

/// Extract time "HH:mm" from various formats:
/// - ISO: "1970-01-01T08:00:00.000Z"
/// - Time only: "08:00:00" or "08:00"
/// - Prisma MySQL TIME: "08:00:00"
String? _extractTimeHHmm(String raw) {
  // Try ISO parse ("1970-01-01T08:00:00.000Z")
  try {
    final dt = DateTime.parse(raw);
    return _hhmm(dt);
  } catch (_) {}

  // Try time-only format "HH:mm:ss" or "HH:mm"
  final timeMatch = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw);
  if (timeMatch != null) {
    final h = timeMatch.group(1)!.padLeft(2, '0');
    final m = timeMatch.group(2)!;
    return '$h:$m';
  }

  return null;
}

class _SlotItem {
  final int id;
  final String time;

  _SlotItem(this.id, this.time);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SlotItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
