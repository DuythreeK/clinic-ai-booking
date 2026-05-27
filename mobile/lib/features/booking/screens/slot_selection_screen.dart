import 'package:flutter/material.dart';

import '../../../core/api/dio_client.dart';
import 'dart:async';
class SlotSelectionScreen extends StatefulWidget {
  const SlotSelectionScreen({
    super.key,
    required this.doctor_id,
    required this.facility_id,
    required this.dioClient,
  });

  final int doctor_id;
  final int facility_id;
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
  Map<int, int> _tempLockedSlots = {}; // slot_id -> giây còn lại
  Timer? _lockTimer;
  Timer? _refreshTimer;



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
    /*
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_loadingSlots) {
        _loadSlotsForCurrentMonth();
      }
    });
     */
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _lockTimer?.cancel(); // Hủy timer khi thoát màn hình để tránh lỗi leak memory
    super.dispose();
  }

  // --- DÁN HÀM NÀY VÀO SAU INITSTATE HOẶC TRƯỚC BUILD ---
  void _startTempLock(int slot_id) {
    setState(() {
      _tempLockedSlots[slot_id] = 300; // 5 phút = 300 giây
    });

    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        // Giảm 1 giây cho tất cả các slot đang khóa
        _tempLockedSlots.updateAll((id, sec) => sec - 1);
        // Xóa slot khỏi Map nếu hết thời gian
        _tempLockedSlots.removeWhere((id, sec) => sec <= 0);
        // Nếu không còn slot nào bị khóa thì tắt luôn timer
        if (_tempLockedSlots.isEmpty) timer.cancel();
      });
    });
  }
  // ---------------------------------------------------


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
          'doctor_id': widget.doctor_id,
          'clinicId': widget.facility_id,
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
        debugPrint('Slot ID: ${item['slot_id']} - is_active: ${item['is_active']}');
        final slot_idRaw = item['slot_id'];
        final slot_dateRaw = item['slot_date'];
        final start_timeRaw = item['start_time'];
        final statusRaw = item['status'] ?? 'available';

        final appointmentData = item['appointment'];
        bool hasBooking = false;
        if (appointmentData != null) {
          if (appointmentData is List) {
            hasBooking = appointmentData.isNotEmpty;
          } else {
            // Nếu là 1 object đơn lẻ gửi về, coi như đã có lịch
            hasBooking = true;
          }
        }
        if (slot_idRaw == null || slot_dateRaw == null || start_timeRaw == null) continue;

        final key = _extractDateKey(slot_dateRaw.toString());
        final value = _extractTimeHHmm(start_timeRaw.toString());
        final id = int.tryParse(slot_idRaw.toString()) ?? 0;
        if (key == null || value == null || id == 0) continue;
        final dynamic activeValue = item['is_active'];
        final bool is_activeRaw = (activeValue == 1 || activeValue == true);
        byDate.putIfAbsent(key, () => <_SlotItem>[]).add(
          _SlotItem(id, value, statusRaw.toString(), hasBooking, is_activeRaw),
        );
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
    // 1. Chặn bấm liên tục khi đang xử lý
    if (_selectingSlot) return;

    // 2. GIỮ NGUYÊN: Kiểm tra nếu chưa chọn slot thì báo lỗi và dừng lại
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn giờ khám'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 3. Nếu đã chọn slot hợp lệ, tiến hành khóa vàng và chuyển màn hình
    final slot_id = _selectedSlot!.id;

    // Kích hoạt bộ đếm ngược 5 phút ngay trên UI máy này
    _startTempLock(slot_id);

    setState(() {
      _selectingSlot = true;
    });

    // 4. Trả dữ liệu về màn hình Flow (Xác nhận đặt lịch)
    // Các key: 'date', 'time', 'slot_id' phải khớp 100% với bên BookingFlowScreen nhận
    Navigator.of(context).pop(
      {
        'date': _selectedDate,
        'time': _selectedSlot!.time,
        'slot_id': slot_id,
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
              final daySlots = _slotsByDate[_dateOnly(date)] ?? <_SlotItem>[];
              final hasAvailableSlots = daySlots.any(
                (slot) => !slot.hasAppointment && slot.status.toUpperCase() == 'AVAILABLE' && slot.is_active,
              );
              final hasBookedSlots = daySlots.any(
                (slot) => slot.hasAppointment || slot.status.toUpperCase() == 'FULL',
              );

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
                          : hasBookedSlots
                              ? Colors.red.shade300
                              : hasAvailableSlots
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
                      if ((hasBookedSlots || hasAvailableSlots) && !isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: hasBookedSlots ? Colors.red : const Color(0xFF1BC47D),
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
            final int? remainingSec = _tempLockedSlots[slot.id];
            final bool isBooked = slot.hasAppointment || slot.status.toUpperCase() == 'FULL' || slot.status.toUpperCase() == 'BUSY';
            final bool isTemporarilyLocked = remainingSec != null && remainingSec > 0;
            final bool isInactive = slot.is_active == false;

            Color bgColor;
            bool isClickable;
            String statusLabel;

            if (isBooked) {
              bgColor = Colors.red.shade400;
              isClickable = false;
              statusLabel = 'Đã đặt';
            } else if (isTemporarilyLocked || isInactive) {
              bgColor = Colors.orange.shade400;
              isClickable = false;
              if (isTemporarilyLocked) {
                final m = (remainingSec / 60).floor();
                final s = remainingSec % 60;
                statusLabel = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
              } else {
                statusLabel = 'Đang giữ...';
              }
            } else {
              bgColor = isSelected ? const Color(0xFF1BC47D) : Colors.grey.shade100;
              isClickable = true;
              statusLabel = '';
            }

            return GestureDetector(
              onTap: isClickable
                  ? () {
                      setState(() {
                        _selectedSlot = slot;
                      });
                    }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      time,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (isSelected || !isClickable) ? Colors.white : Colors.black,
                      ),
                    ),
                    if (statusLabel.isNotEmpty)
                      Text(
                        statusLabel,
                        style: const TextStyle(fontSize: 8, color: Colors.white),
                      ),
                  ],
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
  final String status;
  final bool hasAppointment;
  final bool is_active;
  _SlotItem(this.id, this.time, this.status, this.hasAppointment, this.is_active);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SlotItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
