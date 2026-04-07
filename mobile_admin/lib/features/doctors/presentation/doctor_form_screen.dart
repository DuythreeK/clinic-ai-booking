import 'package:flutter/material.dart';

import '../../../core/network/admin_api_exception.dart';
import '../../../theme/admin_app_theme.dart';
import '../../specialties/domain/admin_specialty.dart';
import '../data/admin_doctors_service.dart';
import '../domain/admin_doctor.dart';

class DoctorFormScreen extends StatefulWidget {
  const DoctorFormScreen({
    super.key,
    required this.specialties,
    this.doctor,
    AdminDoctorsService? service,
  }) : _service = service;

  final List<AdminSpecialty> specialties;
  final AdminDoctor? doctor;
  final AdminDoctorsService? _service;

  bool get isEditing => doctor != null;

  @override
  State<DoctorFormScreen> createState() => _DoctorFormScreenState();
}

class _DoctorFormScreenState extends State<DoctorFormScreen> {
  late final AdminDoctorsService _service;
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _licenseController;
  late final TextEditingController _titleController;

  bool _isActive = true;
  bool _isSaving = false;
  String? _selectedSpecialtyId;
  String? _errorText;
  final Set<String> _selectedFacilities = {'CS Quận 1', 'CS Quận 7'};

  static const _facilityOptions = ['CS Quận 1', 'CS Quận 7', 'CS Bình Thạnh'];

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? AdminDoctorsService();
    final doctor = widget.doctor;
    _fullNameController = TextEditingController(text: doctor?.fullName ?? '');
    _emailController = TextEditingController(text: doctor?.email ?? '');
    _phoneController = TextEditingController(text: doctor?.phone ?? '');
    _passwordController = TextEditingController();
    _licenseController = TextEditingController(
      text: doctor?.licenseNumber ?? '',
    );
    _titleController = TextEditingController(text: doctor?.title ?? 'BS');
    _selectedSpecialtyId = doctor?.specialtyId;
    _isActive = doctor?.isActive ?? true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final license = _licenseController.text.trim();
    final title = _titleController.text.trim().isEmpty
        ? 'BS'
        : _titleController.text.trim();

    if (fullName.isEmpty ||
        phone.isEmpty ||
        license.isEmpty ||
        (_selectedSpecialtyId == null || _selectedSpecialtyId!.isEmpty)) {
      setState(() {
        _errorText = 'Vui lòng nhập đầy đủ các trường bắt buộc.';
      });
      return;
    }

    if (!widget.isEditing && password.trim().length < 6) {
      setState(() {
        _errorText = 'Mật khẩu phải có ít nhất 6 ký tự.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSaving = true;
    });

    final payload = AdminDoctorPayload(
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
      specialtyId: _selectedSpecialtyId!,
      title: title,
      licenseNumber: license,
      bio: '',
      yearsExperience: widget.doctor?.yearsExperience ?? 0,
      consultationFee: widget.doctor?.consultationFee ?? 0,
      isActive: _isActive,
    );

    try {
      if (widget.isEditing) {
        await _service.updateDoctor(widget.doctor!.id, payload);
      } else {
        await _service.createDoctor(payload);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = error is AdminApiException
            ? error.message
            : 'Không thể lưu bác sĩ.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      Text(
                        widget.isEditing ? 'Sửa bác sĩ' : 'Thêm bác sĩ mới',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontSize: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 108,
                          height: 108,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEFF3F8),
                          ),
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            color: AdminAppTheme.textSecondary,
                            size: 34,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: 8,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AdminAppTheme.primary,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FormLabel(label: 'Họ tên'),
                  _FormField(controller: _fullNameController),
                  const SizedBox(height: 12),
                  _FormLabel(label: 'Email'),
                  _FormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _FormLabel(label: 'Số điện thoại'),
                  _FormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _FormLabel(label: 'Số chứng chỉ'),
                  _FormField(controller: _licenseController),
                  const SizedBox(height: 12),
                  _FormLabel(
                    label: widget.isEditing
                        ? 'Mật khẩu mới'
                        : 'Mật khẩu đăng nhập',
                  ),
                  _FormField(
                    controller: _passwordController,
                    obscureText: true,
                    hintText: widget.isEditing
                        ? 'Để trống nếu không đổi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _FormLabel(label: 'Chuyên khoa'),
                  DropdownButtonFormField<String>(
                    value: _selectedSpecialtyId,
                    decoration: _inputDecoration(),
                    items: widget.specialties
                        .map(
                          (specialty) => DropdownMenuItem<String>(
                            value: specialty.id,
                            child: Text(specialty.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSpecialtyId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _FormLabel(label: 'Cơ sở làm việc'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _facilityOptions.map((facility) {
                      final selected = _selectedFacilities.contains(facility);
                      return FilterChip(
                        label: Text(facility),
                        selected: selected,
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedFacilities.add(facility);
                            } else {
                              _selectedFacilities.remove(facility);
                            }
                          });
                        },
                        showCheckmark: false,
                        selectedColor: AdminAppTheme.primary.withOpacity(0.15),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: selected
                              ? Colors.transparent
                              : AdminAppTheme.border,
                        ),
                        labelStyle: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: selected
                                  ? AdminAppTheme.primary
                                  : AdminAppTheme.textSecondary,
                            ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Trạng thái hoạt động',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFF1CCD8B),
                      ),
                    ],
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorText!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFE14D55),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
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
                      child: Text(_isSaving ? 'Đang lưu...' : 'Lưu bác sĩ'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: const Color(0xFFEFF3F8),
                        disabledForegroundColor: const Color(0xFFB7C0D1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('Xóa bác sĩ (Disabled)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: AdminAppTheme.textSecondary),
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

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.hintText,
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
