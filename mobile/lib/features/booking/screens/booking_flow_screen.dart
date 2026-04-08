import 'package:flutter/material.dart';

import '../../../core/api/dio_client.dart';
import '../../auth/services/auth_service.dart';
import '../../facilities/models/booking_facility_item.dart';
import '../../facilities/services/facility_service.dart';
import '../models/booking_doctor_item.dart';
import 'doctor_selection_screen.dart';
import 'facility_selection_screen.dart';
import 'slot_selection_screen.dart';

class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({
    super.key,
    required this.authService,
    this.initialDoctorId,
  });

  final AuthService authService;
  final int? initialDoctorId;

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  late final _BookingFlowApi _api;
  bool _isOpeningStepRoute = false;

  // Wizard selections
  BookingFacilityItem? _selectedFacility;
  BookingDoctorItem? _selectedDoctor;
  DateTime? _selectedDate;
  String? _selectedTime;
  int? _selectedSlotId;

  // Form state
  final TextEditingController _noteCtrl = TextEditingController();
  String _paymentMethod = 'cash';

  // Data
  List<BookingServiceItem> _services = <BookingServiceItem>[];
  List<BookingPatientItem> _patients = <BookingPatientItem>[];
  BookingPatientItem? _selectedPatient;
  BookingServiceItem? _selectedService;

  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = _BookingFlowApi(dioClient: widget.authService.dioClient);
    _bootstrap();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final patients = await _api.getPatientProfiles();
      setState(() {
        _patients = patients;
        if (patients.isNotEmpty) {
          _selectedPatient = patients.firstWhere(
            (p) => p.isPrimary,
            orElse: () => patients.first,
          );
        }
      });

      if (widget.initialDoctorId != null) {
        await _autoselectDoctor(widget.initialDoctorId!);
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải dữ liệu: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }

    if (mounted && _selectedFacility == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedFacility == null) {
          _showFacilitySelection();
        }
      });
    }
  }

  Future<void> _showFacilitySelection() async {
    if (_isOpeningStepRoute) return;

    final previousFacility = _selectedFacility;
    final previousDoctor = _selectedDoctor;
    final previousDate = _selectedDate;
    final previousTime = _selectedTime;

    _isOpeningStepRoute = true;
    BookingFacilityItem? facility;
    try {
      facility = await Navigator.push<BookingFacilityItem>(
        context,
        MaterialPageRoute<BookingFacilityItem>(
          builder: (context) => FacilitySelectionScreen(
            dioClient: widget.authService.dioClient,
          ),
        ),
      );
    } finally {
      _isOpeningStepRoute = false;
    }

    if (!mounted) return;
    if (facility == null) {
      // User bấm back → thoát khỏi BookingFlowScreen, quay về Home
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    final selectedFacility = facility;

    setState(() {
      _selectedFacility = selectedFacility;

      // Reset downstream selections when facility changed.
      if (previousFacility?.id != selectedFacility.id) {
        _selectedDoctor = null;
        _selectedDate = null;
        _selectedTime = null;
        _selectedSlotId = null;
        _services = <BookingServiceItem>[];
        _selectedService = null;
      }
    });

    if (previousFacility?.id == selectedFacility.id &&
        previousDoctor != null &&
        previousDate != null &&
        previousTime != null) {
      // Preserve previous complete selection when facility is unchanged.
      setState(() {
        _selectedDoctor = previousDoctor;
        _selectedDate = previousDate;
        _selectedTime = previousTime;
      });
    } else if (_selectedDoctor == null) {
      // Tự động chuyển sang chọn bác sĩ khi facility mới được chọn
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isOpeningStepRoute && _selectedFacility != null) {
          _showDoctorSelection();
        }
      });
    }
  }

  Future<void> _showDoctorSelection() async {
    if (_isOpeningStepRoute) return;

    final facility = _selectedFacility;
    if (facility == null) return;

    final previousDoctor = _selectedDoctor;
    final previousDate = _selectedDate;
    final previousTime = _selectedTime;

    _isOpeningStepRoute = true;
    Map<String, dynamic>? doctorData;
    try {
      doctorData = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute<Map<String, dynamic>>(
          builder: (context) => DoctorSelectionScreen(
            facility: facility,
            dioClient: widget.authService.dioClient,
          ),
        ),
      );
    } finally {
      _isOpeningStepRoute = false;
    }

    if (!mounted) return;
    if (doctorData == null) {
      // User bấm back → giữ nguyên facility đã chọn, quay lại BookingFlowScreen
      return;
    }

    final selectedDoctor = BookingDoctorItem(
      id: (doctorData['id'] as num?)?.toInt() ?? 0,
      fullName: doctorData['fullName']?.toString() ?? '',
      avatarUrl: doctorData['avatarUrl']?.toString(),
      specialtyName: doctorData['specialtyName']?.toString(),
      facilityId: (doctorData['facilityId'] as num?)?.toInt(),
      consultationFee: (doctorData['consultationFee'] as num?)?.toDouble(),
    );

    setState(() {
      _selectedDoctor = selectedDoctor;

      // Reset slot when doctor changed.
      if (previousDoctor?.id != selectedDoctor.id) {
        _selectedDate = null;
        _selectedTime = null;
        _selectedSlotId = null;
      }
    });

    if (previousDoctor?.id == selectedDoctor.id &&
        previousDate != null &&
        previousTime != null) {
      setState(() {
        _selectedDate = previousDate;
        _selectedTime = previousTime;
      });
    } else {
      // Tự động mở chọn ca khám sau khi chọn bác sĩ
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isOpeningStepRoute) {
          _showSlotSelection();
        }
      });
    }
  }

  Future<void> _showSlotSelection() async {
    if (_isOpeningStepRoute) return;

    final doctor = _selectedDoctor;
    if (doctor?.id == null) return;

    _isOpeningStepRoute = true;
    Map<String, dynamic>? result;
    try {
      result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute<Map<String, dynamic>>(
          builder: (context) => SlotSelectionScreen(
            doctorId: doctor!.id,
            facilityId: _selectedFacility!.id,
            dioClient: widget.authService.dioClient,
          ),
        ),
      );
    } finally {
      _isOpeningStepRoute = false;
    }

    if (!mounted) return;
    if (result == null) {
      // User bấm back → giữ nguyên doctor đã chọn, quay lại BookingFlowScreen
      return;
    }
    final selectedResult = result;

    setState(() {
      _selectedDate = selectedResult['date'] as DateTime;
      _selectedTime = selectedResult['time'] as String;
      _selectedSlotId = selectedResult['slotId'] as int;
    });

    // Load services
    await _loadServices();
  }

  Future<void> _loadServices() async {
    final facility = _selectedFacility;
    if (facility == null) return;

    try {
      final services = await _api.getServicesByFacility(facility.id);
      setState(() {
        _services = services;
        _selectedService = services.isNotEmpty ? services.first : null;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải dịch vụ: $e';
      });
    }
  }

  Future<void> _autoselectDoctor(int doctorId) async {
    try {
      final doctors = await _api.getDoctors();
      final found = doctors.where((e) => e.id == doctorId).toList();
      if (found.isEmpty) return;

      final doctor = found.first;
      final facilityId = doctor.facilityId;
      if (facilityId == null) return;

      try {
        final facilityService =
            FacilityService(dioClient: widget.authService.dioClient);
        final facilities = await facilityService.getFacilities();
        final facility = facilities
            .where((f) => f.id == facilityId)
            .cast<BookingFacilityItem?>()
            .firstOrNull;

        if (facility != null) {
          setState(() {
            _selectedFacility = facility;
            _selectedDoctor = doctor;
          });
          await _loadServices();
        }
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _submitBooking() async {
    final patient = _selectedPatient;
    final facility = _selectedFacility;
    final doctor = _selectedDoctor;
    final date = _selectedDate;
    final time = _selectedTime;
    final slotId = _selectedSlotId;
    final service = _selectedService;

    if (patient == null ||
        facility == null ||
        doctor == null ||
        date == null ||
        time == null ||
        slotId == null) {
      setState(() {
        _error = 'Vui lòng hoàn thành tất cả các bước.';
      });
      return;
    }

    if (service == null) {
      setState(() {
        _error = 'Không tìm thấy dịch vụ tại cơ sở này.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1].split(' ')[0]);
      final slotDate = DateTime(date.year, date.month, date.day, hour, minute);

      final appointment = await _api.createAppointment(
        patientId: patient.id,
        facilityId: facility.id,
        doctorId: doctor.id,
        serviceId: service.id,
        slotId: slotId,
        appointmentDate: slotDate,
        note: _noteCtrl.text.trim(),
      );

      final appointmentId = appointment.id;
      if (appointmentId == null) {
        throw Exception('Không lấy được mã lịch hẹn từ hệ thống');
      }

      final payment = await _api.createPayment(
        appointmentId: appointmentId,
        paymentMethod: _paymentMethod,
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Đặt lịch thành công'),
            content: Text(
              'Mã lịch hẹn: #${appointmentId}\n'
              'Trạng thái: ${payment.status ?? 'pending'}\n'
              '${payment.paymentUrl != null ? 'Link thanh toán: ${payment.paymentUrl}' : ''}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Lỗi: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _changeFacility() {
    _showFacilitySelection();
  }

  void _changeDoctor() {
    if (_selectedFacility == null) {
      _showFacilitySelection();
      return;
    }
    _showDoctorSelection();
  }

  void _changeSlot() {
    if (_selectedDoctor == null) {
      _showDoctorSelection();
      return;
    }
    _showSlotSelection();
  }

  Widget _buildFinalConfirmationUI(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
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
                      onTap: () {
                        setState(() {
                          _selectedSlotId = null;
                          _selectedDate = null;
                          _selectedTime = null;
                        });
                      },
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
                      'Đặt lịch hẹn',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor Info Card
                      Container(
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 80,
                                height: 80,
                                color: const Color(0xFFE2F5FF),
                                child: _selectedDoctor?.fullName != null
                                  ? const Icon(Icons.person, size: 40, color: Color(0xFF14CBA8))
                                  : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedDoctor?.fullName ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF333333),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.favorite, color: Colors.red, size: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedDoctor?.specialtyName ?? 'Chuyên khoa',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF14CBA8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    runSpacing: 4,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                                          const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                                          const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                                          const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                                          const Icon(Icons.star_half, color: Color(0xFFFFC107), size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            '4.0',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.attach_money, color: Color(0xFF14CBA8), size: 16),
                                          Text(
                                            '${_money(_selectedDoctor?.consultationFee ?? _selectedService?.price ?? 0)}/10p',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ca khám: ${_selectedTime} - ${_selectedDate?.day}/${_selectedDate?.month}/${_selectedDate?.year}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Patient Info
                      const Text(
                        'Thông tin bệnh nhân',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A)),
                      ),
                      const SizedBox(height: 12),
                      _buildMockInput(text: _selectedPatient?.fullName ?? 'Bệnh nhân chưa xác định'),
                      const SizedBox(height: 16),
                      const Text(
                        'Mô tả triệu chứng(*)',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _noteCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Lại bị đau răng nhưng dai dẳng hơn, vừa đau vừa thốn, đau ở dưới hàm bên phải, ăn thường ợ chua, hôi miệng',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.black54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Payment Methods from existing logic
                      const Text(
                        'Phương thức thanh toán',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['cash', 'vnpay', 'momo', 'bank_transfer']
                            .map((method) => ChoiceChip(
                                  selected: _paymentMethod == method,
                                  label: Text(method),
                                  onSelected: (_) {
                                    setState(() {
                                      _paymentMethod = method;
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedDoctor != null || _selectedService != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FAFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD4EEF8)),
                          ),
                          child: Text(
                            'Tổng thanh toán: ${_money(_selectedDoctor?.consultationFee ?? _selectedService?.price ?? 0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF134F68),
                            ),
                          ),
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14CBA8),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _submitting ? null : _submitBooking,
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Xác nhận đặt lịch',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockInput({required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_selectedFacility != null && _selectedDoctor != null && _selectedDate != null && _selectedTime != null && _selectedSlotId != null) {
      return _buildFinalConfirmationUI(context);
    }

    return Scaffold(
      appBar: AppBar(
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
            if (_selectedFacility == null) ...[
              _buildStartSection(),
              const SizedBox(height: 16),
            ],

            // Summary
            if (_selectedFacility != null) _buildSummary(),

            const SizedBox(height: 24),

            // Edit and step sections
            if (_selectedFacility != null) ...[
              _buildEditSection(
                'Cơ sở y tế',
                _selectedFacility!.name,
                _changeFacility,
              ),
              const SizedBox(height: 12),
            ],

            if (_selectedFacility != null && _selectedDoctor == null) ...[
              _buildStepActionSection(
                title: 'Bước 2: Chọn bác sĩ',
                subtitle: 'Chọn bác sĩ thuộc cơ sở đã chọn',
                buttonText: 'Chọn bác sĩ',
                onPressed: _showDoctorSelection,
              ),
              const SizedBox(height: 12),
            ],

            if (_selectedDoctor != null) ...[
              _buildEditSection(
                'Bác sĩ',
                _selectedDoctor!.fullName,
                _changeDoctor,
              ),
              const SizedBox(height: 12),
            ],

            if (_selectedDoctor != null && (_selectedDate == null || _selectedTime == null)) ...[
              _buildStepActionSection(
                title: 'Bước 3: Chọn ca khám',
                subtitle: 'Chọn ngày và giờ khám khả dụng',
                buttonText: 'Chọn ca khám',
                onPressed: _showSlotSelection,
              ),
              const SizedBox(height: 12),
            ],

            if (_selectedDate != null && _selectedTime != null) ...[
              _buildEditSection(
                'Thời gian',
                '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} - $_selectedTime',
                _changeSlot,
              ),
              const SizedBox(height: 12),
            ],

            // Form
            if (_selectedFacility != null && _selectedDoctor != null)
              _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tóm tắt lịch hẹn',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _summaryRow('Cơ sở:', _selectedFacility?.name ?? ''),
          if (_selectedDoctor != null)
            _summaryRow('Bác sĩ:', _selectedDoctor!.fullName),
          if (_selectedDate != null && _selectedTime != null)
            _summaryRow(
              'Thời gian:',
              '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} - $_selectedTime',
            ),
        ],
      ),
    );
  }

  Widget _buildStartSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bắt đầu đặt lịch',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn cơ sở y tế trước, sau đó chọn bác sĩ và ca khám.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showFacilitySelection,
              child: const Text('Chọn cơ sở y tế'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1BC47D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection(String label, String value, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.edit, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStepActionSection({
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
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
          const Text(
            'Thông tin khám',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<BookingPatientItem>(
            value: _selectedPatient,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Người khám',
              border: OutlineInputBorder(),
            ),
            items: _patients
                .map(
                  (e) => DropdownMenuItem<BookingPatientItem>(
                    value: e,
                    child: Text(
                      '${e.fullName}${e.isPrimary ? ' (Mặc định)' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedPatient = value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<BookingServiceItem>(
            value: _selectedService,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Dịch vụ',
              border: OutlineInputBorder(),
            ),
            items: _services
                .map(
                  (e) => DropdownMenuItem<BookingServiceItem>(
                    value: e,
                    child: Text(
                      e.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedService = value;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ghi chú triệu chứng...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Phương thức thanh toán',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['cash', 'vnpay', 'momo', 'bank_transfer']
                .map((method) => ChoiceChip(
                      selected: _paymentMethod == method,
                      label: Text(method),
                      onSelected: (_) {
                        setState(() {
                          _paymentMethod = method;
                        });
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          if (_selectedService != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD4EEF8)),
              ),
              child: Text(
                'Tổng thanh toán: ${_money(_selectedDoctor?.consultationFee ?? _selectedService!.price)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF134F68),
                ),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
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
              onPressed: _submitting ? null : _submitBooking,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Xác nhận đặt lịch',
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
    );
  }

  String _money(double amount) {
    final intValue = amount.round();
    final text = intValue.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final idx = text.length - i;
      buffer.write(text[i]);
      if (idx > 1 && idx % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()} VND';
  }
}

class _BookingFlowApi {
  _BookingFlowApi({required this.dioClient});

  final DioClient dioClient;

  Future<List<BookingDoctorItem>> getDoctors(
      {int? facilityId, String? search}) async {
    final response = await dioClient.get(
      '/doctors',
      queryParameters: {
        'page': 1,
        'limit': 100,
        if (facilityId != null) 'facilityId': facilityId,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final items = _unwrapItems(response.data);
    return items
        .map((item) {
          final specialty = item['specialty'];
          final facility = item['facility'];
          return BookingDoctorItem(
            id: _toInt(item['id']) ?? 0,
            fullName: (item['fullName'] ?? '').toString(),
            avatarUrl: item['avatarUrl']?.toString(),
            specialtyName: specialty is Map<String, dynamic>
                ? specialty['name']?.toString()
                : null,
            facilityId: facility is Map<String, dynamic>
                ? _toInt(facility['id'])
                : null,
            consultationFee: _toDouble(item['consultationFee']),
          );
        })
        .where((e) => e.id > 0 && e.fullName.isNotEmpty)
        .toList();
  }

  Future<List<BookingServiceItem>> getServicesByFacility(int facilityId) async {
    final response = await dioClient.get(
      '/services',
      queryParameters: {
        'page': 1,
        'limit': 50,
        'facilityId': facilityId,
      },
    );

    final items = _unwrapItems(response.data);
    return items
        .map((item) {
          return BookingServiceItem(
            id: _toInt(item['id']) ?? 0,
            facilityId: _toInt(item['facilityId']) ?? facilityId,
            name: (item['name'] ?? '').toString(),
            price: _toDouble(item['price']) ?? 0,
          );
        })
        .where((e) => e.id > 0 && e.name.isNotEmpty)
        .toList();
  }

  Future<List<BookingPatientItem>> getPatientProfiles() async {
    final response = await dioClient.get('/patient-profiles');
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      return <BookingPatientItem>[];
    }

    final data = body['data'];
    if (data is! List) {
      return <BookingPatientItem>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map((item) {
          return BookingPatientItem(
            id: _toInt(item['id']) ?? 0,
            fullName: (item['fullName'] ?? '').toString(),
            isPrimary: item['isPrimary'] == true,
          );
        })
        .where((e) => e.id > 0)
        .toList();
  }

  Future<_CreateAppointmentResult> createAppointment({
    required int patientId,
    required int facilityId,
    required int doctorId,
    required int serviceId,
    required int slotId,
    required DateTime appointmentDate,
    String? note,
  }) async {
    final response = await dioClient.post(
      '/appointments',
      data: {
        'patientId': patientId.toString(),
        'facilityId': facilityId.toString(),
        'serviceId': serviceId.toString(),
        'slotId': slotId.toString(),
        'appointmentType': 'consultation',
        'appointmentDate': _dateOnly(appointmentDate),
        'appointmentTime': _hhmm(appointmentDate),
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      return const _CreateAppointmentResult();
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return const _CreateAppointmentResult();
    }

    return _CreateAppointmentResult(
      id: _toInt(data['id']),
      status: data['status']?.toString(),
    );
  }

  Future<_CreatePaymentResult> createPayment({
    required int appointmentId,
    required String paymentMethod,
  }) async {
    final response = await dioClient.post(
      '/payments',
      data: {
        'appointmentId': appointmentId.toString(),
        'paymentMethod': paymentMethod,
      },
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      return const _CreatePaymentResult();
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return const _CreatePaymentResult();
    }

    return _CreatePaymentResult(
      status: data['status']?.toString(),
      paymentUrl: data['paymentUrl']?.toString(),
    );
  }
}

class BookingServiceItem {
  final int id;
  final int facilityId;
  final String name;
  final double price;

  BookingServiceItem({
    required this.id,
    required this.facilityId,
    required this.name,
    required this.price,
  });
}

class BookingPatientItem {
  final int id;
  final String fullName;
  final bool isPrimary;

  BookingPatientItem({
    required this.id,
    required this.fullName,
    required this.isPrimary,
  });
}

class _CreateAppointmentResult {
  final int? id;
  final String? status;

  const _CreateAppointmentResult({this.id, this.status});
}

class _CreatePaymentResult {
  final String? status;
  final String? paymentUrl;

  const _CreatePaymentResult({this.status, this.paymentUrl});
}

List<dynamic> _unwrapItems(dynamic data) {
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
  if (data is List) return data;
  return <dynamic>[];
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

double? _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String _dateOnly(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

String _hhmm(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
