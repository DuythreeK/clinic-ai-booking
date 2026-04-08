import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../vaccination_booking/screens/vaccination_booking_models.dart';
import '../../vaccination_booking/screens/vaccination_booking_widgets.dart';
import '../../vaccination_booking/utils/vietnam_address_catalog.dart';

class MedicalProfileEditorArgs {
  const MedicalProfileEditorArgs({
    this.profile,
    this.canTogglePrimaryOff = true,
  });

  final VaccinationPatientProfile? profile;
  final bool canTogglePrimaryOff;
}

class MedicalProfilesScreen extends StatefulWidget {
  const MedicalProfilesScreen({super.key});

  @override
  State<MedicalProfilesScreen> createState() => _MedicalProfilesScreenState();
}

class _MedicalProfilesScreenState extends State<MedicalProfilesScreen> {
  bool _loading = true;
  String? _error;
  List<VaccinationPatientProfile> _profiles = const [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await VaccinationBookingCatalog.loadPatientProfiles(force: true);
      if (!mounted) return;
      setState(() {
        _profiles = List<VaccinationPatientProfile>.from(
          VaccinationBookingCatalog.patientProfiles,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _subtitle(VaccinationPatientProfile profile) {
    final parts = <String>[];
    if (profile.gender != null && profile.gender!.isNotEmpty) {
      parts.add(profile.gender!);
    }
    if (profile.birthDate != null && profile.birthDate!.isNotEmpty) {
      parts.add(profile.birthDate!);
    }
    if (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty) {
      parts.add(profile.phoneNumber!);
    }
    return parts.join(' • ');
  }

  bool _canTogglePrimaryOff(VaccinationPatientProfile profile) {
    if (!profile.isPrimary) return true;
    return _profiles.any((item) => item.id != profile.id && item.isPrimary);
  }

  Future<void> _openEditor({VaccinationPatientProfile? profile}) async {
    final args = MedicalProfileEditorArgs(
      profile: profile,
      canTogglePrimaryOff: profile == null ? true : _canTogglePrimaryOff(profile),
    );
    final saved = await context.push<bool>(
      '/medical-profiles/editor',
      extra: args,
    );
    if (saved == true) {
      await _loadProfiles();
    }
  }

  Future<void> _deleteProfile(VaccinationPatientProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa hồ sơ'),
          content: Text('Xóa hồ sơ "${profile.fullName}"?'),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final ok = await VaccinationBookingCatalog.deletePatientProfile(
        patientId: profile.id,
      );
      if (!mounted) return;
      if (ok) {
        await _loadProfiles();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa hồ sơ khám.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không xóa được hồ sơ.')),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extractErrorMessage(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
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
    return error.message ?? 'Không xác định được lỗi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaccinationBookingColors.background,
      appBar: AppBar(
        title: const Text('Hồ sơ khám'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm hồ sơ'),
        backgroundColor: VaccinationBookingColors.blue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfiles,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                VaccinationBookingColors.gradientTop,
                VaccinationBookingColors.gradientBottom,
              ],
            ),
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFC6C6)),
                        ),
                        child: Text(
                          'Không tải được hồ sơ: $_error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_profiles.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.folder_shared_outlined,
                                  color: VaccinationBookingColors.blue,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Chưa có hồ sơ khám nào.',
                                style: TextStyle(
                                  color: VaccinationBookingColors.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._profiles.map(
                        (profile) => _ProfileCard(
                          profile: profile,
                          subtitle: _subtitle(profile),
                          onTap: () => _openEditor(profile: profile),
                          onEdit: () => _openEditor(profile: profile),
                          onDelete: () => _deleteProfile(profile),
                        ),
                      ),
                    const SizedBox(height: 88),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.subtitle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final VaccinationPatientProfile profile;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        shadowColor: const Color(0x12094A69),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: VaccinationBookingColors.text,
                        ),
                      ),
                    ),
                    if (profile.isPrimary)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1420C8C2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x5520C8C2)),
                        ),
                        child: const Text(
                          'Chính',
                          style: TextStyle(
                            color: VaccinationBookingColors.mint,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: VaccinationBookingColors.blue,
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: VaccinationBookingColors.subtext),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  [
                    if ((profile.citizenId ?? '').isNotEmpty)
                      'CCCD: ${profile.citizenId}',
                    if ((profile.insuranceNumber ?? '').isNotEmpty)
                      'BHYT: ${profile.insuranceNumber}',
                    if ((profile.email ?? '').isNotEmpty)
                      'Email: ${profile.email}',
                    if ((profile.province ?? '').isNotEmpty) profile.province!,
                    if ((profile.district ?? '').isNotEmpty) profile.district!,
                    if ((profile.ward ?? '').isNotEmpty) profile.ward!,
                  ].join(' • '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: VaccinationBookingColors.subtext,
                    height: 1.45,
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

class MedicalProfileEditorScreen extends StatefulWidget {
  const MedicalProfileEditorScreen({
    super.key,
    required this.args,
  });

  final MedicalProfileEditorArgs args;

  @override
  State<MedicalProfileEditorScreen> createState() => _MedicalProfileEditorScreenState();
}

class _MedicalProfileEditorScreenState extends State<MedicalProfileEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _citizenController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthController = TextEditingController();
  final _occupationController = TextEditingController();
  final _nationalityController = TextEditingController(text: 'Việt Nam');
  final _ethnicityController = TextEditingController(text: 'Kinh');
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _addressController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _relationshipController = TextEditingController(text: 'Bản thân');

  String _gender = 'Nam';
  bool _isPrimary = true;
  bool _submitting = false;

  VaccinationPatientProfile? get _profile => widget.args.profile;

  @override
  void initState() {
    super.initState();
    final profile = _profile;
    if (profile != null) {
      _fullNameController.text = profile.fullName;
      _phoneController.text = profile.phoneNumber ?? '';
      _citizenController.text = profile.citizenId ?? '';
      _insuranceController.text = profile.insuranceNumber ?? '';
      _emailController.text = profile.email ?? '';
      _birthController.text = profile.birthDate ?? '';
      _occupationController.text = profile.occupation ?? '';
      _nationalityController.text = profile.nationality ?? 'Việt Nam';
      _ethnicityController.text = profile.ethnicity ?? 'Kinh';
      _provinceController.text = profile.province ?? '';
      _districtController.text = profile.district ?? '';
      _wardController.text = profile.ward ?? '';
      _addressController.text = profile.addressDetail ?? '';
      _medicalConditionsController.text = profile.medicalConditions ?? '';
      _allergiesController.text = profile.allergies ?? '';
      _emergencyContactController.text = profile.emergencyContact ?? '';
      _relationshipController.text = profile.relationshipToUser ?? 'Bản thân';
      _gender = profile.gender ?? 'Nam';
      _isPrimary = profile.isPrimary;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _citizenController.dispose();
    _insuranceController.dispose();
    _emailController.dispose();
    _birthController.dispose();
    _occupationController.dispose();
    _nationalityController.dispose();
    _ethnicityController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _addressController.dispose();
    _medicalConditionsController.dispose();
    _allergiesController.dispose();
    _emergencyContactController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final addressDetail = [
        _provinceController.text.trim(),
        _districtController.text.trim(),
        _wardController.text.trim(),
      ].where((item) => item.isNotEmpty).join(', ');

      if (_profile == null) {
        await VaccinationBookingCatalog.createPatientProfile(
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          citizenId: _citizenController.text.trim(),
          insuranceNumber: _insuranceController.text.trim(),
          email: _emailController.text.trim(),
          gender: _gender,
          dateOfBirth: _birthController.text.trim(),
          occupation: _occupationController.text.trim(),
          nationality: _nationalityController.text.trim(),
          ethnicity: _ethnicityController.text.trim(),
          medicalConditions: _medicalConditionsController.text.trim(),
          allergies: _allergiesController.text.trim(),
          province: _provinceController.text.trim(),
          district: _districtController.text.trim(),
          ward: _wardController.text.trim(),
          addressDetail: addressDetail,
          emergencyContact: _emergencyContactController.text.trim(),
          relationshipToUser: _relationshipController.text.trim(),
          isPrimary: _isPrimary,
        );
      } else {
        await VaccinationBookingCatalog.updatePatientProfile(
          patientId: _profile!.id,
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          citizenId: _citizenController.text.trim(),
          insuranceNumber: _insuranceController.text.trim(),
          email: _emailController.text.trim(),
          gender: _gender,
          dateOfBirth: _birthController.text.trim(),
          occupation: _occupationController.text.trim(),
          nationality: _nationalityController.text.trim(),
          ethnicity: _ethnicityController.text.trim(),
          medicalConditions: _medicalConditionsController.text.trim(),
          allergies: _allergiesController.text.trim(),
          province: _provinceController.text.trim(),
          district: _districtController.text.trim(),
          ward: _wardController.text.trim(),
          addressDetail: addressDetail,
          emergencyContact: _emergencyContactController.text.trim(),
          relationshipToUser: _relationshipController.text.trim(),
          isPrimary: _isPrimary,
        );
      }

      if (!mounted) return;
      context.pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extractErrorMessage(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
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
    return error.message ?? 'Không xác định được lỗi';
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  void _onPrimaryChanged(bool value) {
    if (!value && !widget.args.canTogglePrimaryOff && (_profile?.isPrimary ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất một hồ sơ chính.')),
      );
      return;
    }
    setState(() => _isPrimary = value);
  }

  @override
  Widget build(BuildContext context) {
    final provinceOptions =
        VietnamAddressCatalog.provinces().map((item) => item.name).toList();
    final districtOptions = _provinceController.text.isEmpty
        ? const <String>[]
        : VietnamAddressCatalog.districtsByProvinceName(_provinceController.text)
            .map((item) => item.name)
            .toList();
    final wardOptions =
        (_provinceController.text.isEmpty || _districtController.text.isEmpty)
            ? const <String>[]
            : VietnamAddressCatalog.wardsBySelection(
                _provinceController.text,
                _districtController.text,
              ).map((item) => item.name).toList();

    final selectedProvince = provinceOptions.contains(_provinceController.text)
        ? _provinceController.text
        : null;
    final selectedDistrict = districtOptions.contains(_districtController.text)
        ? _districtController.text
        : null;
    final selectedWard = wardOptions.contains(_wardController.text)
        ? _wardController.text
        : null;

    return Scaffold(
      backgroundColor: VaccinationBookingColors.background,
      appBar: AppBar(
        title: Text(_profile == null ? 'Thêm hồ sơ khám' : 'Sửa hồ sơ khám'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VaccinationBookingColors.gradientTop,
              VaccinationBookingColors.gradientBottom,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: _decoration('Họ và tên *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập đầy đủ thông tin'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: _decoration('Số điện thoại *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập đầy đủ thông tin'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _citizenController,
                decoration: _decoration('CCCD *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập đầy đủ thông tin'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _insuranceController,
                decoration: _decoration('Mã bảo hiểm y tế *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập đầy đủ thông tin'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: _decoration('Email *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập đầy đủ thông tin';
                  }
                  final email = value.trim();
                  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailPattern.hasMatch(email)) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: _decoration('Giới tính *'),
                items: const ['Nam', 'Nữ', 'Khác']
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _gender = value ?? 'Nam'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthController,
                decoration: _decoration('Ngày sinh *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập đầy đủ thông tin'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _occupationController,
                decoration: _decoration('Nghề nghiệp *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập đầy đủ thông tin'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nationalityController,
                decoration: _decoration('Quốc gia *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập đầy đủ thông tin'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ethnicityController,
                decoration: _decoration('Dân tộc *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập đầy đủ thông tin'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedProvince,
                decoration: _decoration('Tỉnh/Thành phố *'),
                items: provinceOptions
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (value) => setState(() {
                  _provinceController.text = value ?? '';
                  _districtController.text = '';
                  _wardController.text = '';
                }),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng chọn đầy đủ thông tin'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedDistrict,
                decoration: _decoration('Quận/Huyện *'),
                items: districtOptions
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: districtOptions.isEmpty
                    ? null
                    : (value) => setState(() {
                          _districtController.text = value ?? '';
                          _wardController.text = '';
                        }),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng chọn đầy đủ thông tin'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedWard,
                decoration: _decoration('Phường/Xã *'),
                items: wardOptions
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: wardOptions.isEmpty
                    ? null
                    : (value) => setState(() => _wardController.text = value ?? ''),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng chọn đầy đủ thông tin'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: _decoration('Địa chỉ chi tiết'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergencyContactController,
                decoration: _decoration('Liên hệ khẩn cấp'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _relationshipController,
                decoration: _decoration('Quan hệ với người dùng'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _medicalConditionsController,
                decoration: _decoration('Bệnh lý hiện tại'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allergiesController,
                decoration: _decoration('Dị ứng'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isPrimary,
                onChanged: _onPrimaryChanged,
                title: const Text('Hồ sơ chính'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: VaccinationBookingColors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(_submitting ? 'ĐANG LƯU...' : 'Lưu hồ sơ'),
              ),
              if (_profile != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Xóa hồ sơ'),
                                content: const Text(
                                  'Bạn có chắc muốn xóa hồ sơ này?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => context.pop(false),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () => context.pop(true),
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirmed == true && mounted) {
                            try {
                              await VaccinationBookingCatalog.deletePatientProfile(
                                patientId: _profile!.id,
                              );
                              if (!mounted) return;
                              context.pop(true);
                            } on DioException catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_extractErrorMessage(e))),
                              );
                            }
                          }
                        },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Xóa hồ sơ'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
