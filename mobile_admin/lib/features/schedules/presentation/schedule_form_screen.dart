import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/admin_api_exception.dart';
import '../../../theme/admin_app_theme.dart';
import '../../doctors/data/admin_doctors_service.dart';
import '../../doctors/domain/admin_doctor.dart';
import '../../rooms/data/admin_rooms_service.dart';
import '../../rooms/domain/admin_room.dart';
import '../data/admin_schedules_service.dart';
import '../domain/admin_schedule.dart';

class ScheduleFormScreen extends StatefulWidget {
  const ScheduleFormScreen({super.key, this.schedule});

  final AdminSchedule? schedule;

  bool get isEditing => schedule != null;

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final AdminSchedulesService _service = AdminSchedulesService();
  final AdminDoctorsService _doctorsService = AdminDoctorsService();
  final AdminRoomsService _roomsService = AdminRoomsService();

  late final TextEditingController _maxSlotsController;
  late final TextEditingController _slotDurationController;

  bool _isAvailable = true;
  bool _isSaving = false;
  String? _errorText;

  List<AdminDoctor> _doctors = [];
  List<AdminRoom> _rooms = [];
  String? _selectedDoctorId;
  String? _selectedRoomId;
  DateTime? _workDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isLoadingDeps = true;

  @override
  void initState() {
    super.initState();
    final schedule = widget.schedule;
    _maxSlotsController = TextEditingController(
      text: schedule?.maxSlots.toString() ?? '20',
    );
    _slotDurationController = TextEditingController(
      text: schedule?.slotDurationMin.toString() ?? '30',
    );

    _isAvailable = schedule?.isAvailable ?? true;
    _selectedDoctorId = schedule?.doctorId;
    _selectedRoomId = schedule?.roomId;
    _workDate = schedule?.workDate ?? DateTime.now();
    _startTime = schedule != null
        ? TimeOfDay.fromDateTime(schedule.startTime)
        : const TimeOfDay(hour: 8, minute: 0);
    _endTime = schedule != null
        ? TimeOfDay.fromDateTime(schedule.endTime)
        : const TimeOfDay(hour: 12, minute: 0);

    _loadDependencies();
  }

  Future<void> _loadDependencies() async {
    try {
      final docsRes = await _doctorsService.fetchDoctors(limit: 100);
      final roomsRes = await _roomsService.fetchRooms();

      if (mounted) {
        setState(() {
          _doctors = docsRes.items;
          _rooms = roomsRes;
          _isLoadingDeps = false;

          if (_selectedDoctorId != null && !_doctors.any((d) => d.id == _selectedDoctorId)) {
            _selectedDoctorId = null;
          }
          if (_selectedRoomId != null && !_rooms.any((r) => r.id == _selectedRoomId)) {
            _selectedRoomId = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDeps = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _maxSlotsController.dispose();
    _slotDurationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _workDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _workDate = picked);
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final initial = isStart ? _startTime! : _endTime!;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedDoctorId == null) {
      setState(() => _errorText = 'Vui lòng chọn bác sĩ.');
      return;
    }

    final maxSlots = int.tryParse(_maxSlotsController.text.trim()) ?? 20;
    final duration = int.tryParse(_slotDurationController.text.trim()) ?? 30;

    setState(() {
      _errorText = null;
      _isSaving = true;
    });

    final now = DateTime.now();
    // Combine workDate + _startTime to form full DateTime objects
    final startDt = DateTime(
      _workDate!.year,
      _workDate!.month,
      _workDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    final endDt = DateTime(
      _workDate!.year,
      _workDate!.month,
      _workDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    final payload = AdminSchedulePayload(
      doctorId: _selectedDoctorId!,
      roomId: _selectedRoomId, // nullable
      workDate: _workDate!,
      startTime: startDt,
      endTime: endDt,
      maxSlots: maxSlots,
      slotDurationMin: duration,
      isAvailable: _isAvailable,
    );

    try {
      if (widget.isEditing) {
        await _service.updateSchedule(widget.schedule!.id, payload);
      } else {
        await _service.createSchedule(payload);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error is AdminApiException
            ? error.message
            : 'Không thể lưu ca trực.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
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
                      Expanded(
                        child: Text(
                          widget.isEditing
                              ? 'Cập nhật Ca trực'
                              : 'Thêm Ca trực',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_isLoadingDeps)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    _FormLabel(label: 'Bác sĩ trực'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: _doctors.any((d) => d.id == _selectedDoctorId) ? _selectedDoctorId : null,
                          hint: const Text('Chọn bác sĩ'),
                          items: _doctors
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d.id,
                                  child: Text('${d.title}. ${d.fullName}'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedDoctorId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _FormLabel(label: 'Phòng khám'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: _rooms.any((r) => r.id == _selectedRoomId) ? _selectedRoomId : null,
                          hint: const Text('Phòng làm việc'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Chưa phân phòng'),
                            ),
                            ..._rooms.map(
                              (r) => DropdownMenuItem(
                                value: r.id,
                                child: Text('${r.name} (${r.code})'),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedRoomId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FormLabel(label: 'Ngày làm việc'),
                              InkWell(
                                onTap: _selectDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(dateFormat.format(_workDate!)),
                                      const Icon(Icons.date_range, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FormLabel(label: 'Giờ bắt đầu'),
                              InkWell(
                                onTap: () => _selectTime(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_startTime!.format(context)),
                                      const Icon(Icons.access_time, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FormLabel(label: 'Giờ kết thúc'),
                              InkWell(
                                onTap: () => _selectTime(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_endTime!.format(context)),
                                      const Icon(Icons.access_time, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FormLabel(label: 'Min / C.Khám'),
                              TextField(
                                controller: _slotDurationController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.all(16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FormLabel(label: 'Tổng Slots (ca)'),
                              TextField(
                                controller: _maxSlotsController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.all(16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trạng thái mở khóa',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cho phép bệnh nhân đặt slot trong ca trực này',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isAvailable,
                          onChanged: (val) =>
                              setState(() => _isAvailable = val),
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF1CCD8B),
                        ),
                      ],
                    ),

                    if (_errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorText!,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: const Color(0xFFE14D55)),
                      ),
                    ],
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AdminAppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: Text(_isSaving ? 'Đang lưu...' : 'Lưu ca trực'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 13),
      ),
    );
  }
}
