import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'profile_models.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final ProfileCatalog _catalog = ProfileCatalog.instance;

  @override
  void initState() {
    super.initState();
    _catalog.loadRemote();
  }

  (String, String) _splitfull_name(String? full_name) {
    final normalized = full_name?.trim() ?? '';
    if (normalized.isEmpty) {
      return ('Chưa cập nhật', 'Chưa cập nhật');
    }
    final parts = normalized.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return ('', parts.first);
    }
    final lastName = parts.last;
    final firstName = parts.take(parts.length - 1).join(' ');
    return (firstName, lastName);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _catalog,
      builder: (context, _) {
        final profile = _catalog.profile;
        final loading = _catalog.isLoading && profile == null;
        final error = _catalog.error;

        return Scaffold(
          backgroundColor: const Color(0xFFF7FBFF),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF20C8C2), Color(0xFFF7FBFF)],
                stops: [0, 0.06],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: Row(
                      children: [
                        _CircleButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => context.pop(),
                        ),
                        const Expanded(
                          child: Text(
                            'Thông tin cá nhân',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF203248),
                            ),
                          ),
                        ),
                        _CircleButton(
                          icon: Icons.edit_outlined,
                          onTap: () => context.push('/profile/edit'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : error != null && profile == null
                            ? _ErrorState(
                                message: 'Không tải được thông tin hồ sơ.',
                                onRetry: () => _catalog.loadRemote(force: true),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _SectionLabel('Hồ sơ'),
                                    const SizedBox(height: 10),
                                    _InfoCard(
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _InfoCell(
                                                  label: 'Mã hồ sơ',
                                                  value: profile?.ecoreId ?? 'Chưa cập nhật',
                                                ),
                                              ),
                                              const SizedBox(width: 18),
                                              Expanded(
                                                child: _InfoCell(
                                                  label: 'Username',
                                                  value: profile?.username ?? 'Chưa cập nhật',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 18),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _InfoCell(
                                                  label: 'Họ',
                                                  value: _splitfull_name(profile?.full_name).$1,
                                                ),
                                              ),
                                              const SizedBox(width: 18),
                                              Expanded(
                                                child: _InfoCell(
                                                  label: 'Tên',
                                                  value: _splitfull_name(profile?.full_name).$2,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 18),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _InfoCell(
                                                  label: 'Ngày sinh',
                                                  value: _formatDate(profile?.dateOfBirth),
                                                ),
                                              ),
                                              const SizedBox(width: 18),
                                              Expanded(
                                                child: _InfoCell(
                                                  label: 'Giới tính',
                                                  value: profile?.gender ?? 'Chưa cập nhật',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 18),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _InfoCell(
                                                  label: 'Nghề nghiệp',
                                                  value: profile?.occupation ?? 'Chưa cập nhật',
                                                ),
                                              ),
                                              const SizedBox(width: 18),
                                              Expanded(
                                                child: _InfoCell(
                                                  label: 'Quốc tịch',
                                                  value: profile?.nationality ?? 'Chưa cập nhật',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 18),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _InfoCell(
                                                  label: 'Dân tộc',
                                                  value: profile?.ethnicity ?? 'Chưa cập nhật',
                                                ),
                                              ),
                                              const SizedBox(width: 18),
                                              Expanded(
                                                child: _InfoCell(
                                                  label: 'CCCD',
                                                  value: profile?.citizenId ?? 'Chưa cập nhật',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    const _SectionLabel('Thông tin liên hệ'),
                                    const SizedBox(height: 10),
                                    _InfoCard(
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _InfoCell(
                                                  label: 'Số điện thoại',
                                                  value: profile?.phone ?? 'Chưa cập nhật',
                                                ),
                                              ),
                                              const SizedBox(width: 18),
                                              Expanded(
                                                child: _InfoCell(
                                                  label: 'Email',
                                                  value: profile?.email ?? 'Chưa cập nhật',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 18),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _InfoCell(
                                                  label: 'Tỉnh/Thành phố',
                                                  value: profile?.city ?? 'Chưa cập nhật',
                                                ),
                                              ),
                                              const SizedBox(width: 18),
                                              Expanded(
                                                child: _InfoCell(
                                                  label: 'Quận/Huyện',
                                                  value: profile?.district ?? 'Chưa cập nhật',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 18),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _InfoCell(
                                                  label: 'Phường/Xã',
                                                  value: profile?.ward ?? 'Chưa cập nhật',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 18),
                                          _InfoCell(
                                            label: 'Địa chỉ chi tiết',
                                            centered: true,
                                            value: profile?.address ?? 'Chưa cập nhật',
                                          ),
                                          const SizedBox(height: 18),
                                          _InfoCell(
                                            label: 'Liên hệ khẩn cấp',
                                            centered: true,
                                            value: profile?.emergencyContact ?? 'Chưa cập nhật',
                                          ),
                                          const SizedBox(height: 18),
                                          _InfoCell(
                                            label: 'Quan hệ với người dùng',
                                            centered: true,
                                            value: profile?.relationshipToUser ?? 'Chưa cập nhật',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'Chưa cập nhật';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return '$day/$month/${parsed.year}';
  }
}

class EditPersonalInfoScreen extends StatefulWidget {
  const EditPersonalInfoScreen({super.key});

  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  final ProfileCatalog _catalog = ProfileCatalog.instance;
  final _formKey = GlobalKey<FormState>();

  final _full_nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  final _occupationController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _ethnicityController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _relationshipController = TextEditingController();

  String? _gender;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _catalog.loadRemote().then((_) {
      if (mounted) {
        _syncFromCatalog();
      }
    });
  }

  @override
  void dispose() {
    _full_nameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _occupationController.dispose();
    _nationalityController.dispose();
    _ethnicityController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _addressController.dispose();
    _emergencyController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  void _syncFromCatalog() {
    final profile = _catalog.profile;
    if (profile == null || _initialized) {
      return;
    }

    _full_nameController.text = profile.full_name;
    _phoneController.text = profile.phone;
    _dateController.text = profile.dateOfBirth ?? '';
    _occupationController.text = profile.occupation ?? '';
    _nationalityController.text = profile.nationality ?? '';
    _ethnicityController.text = profile.ethnicity ?? '';
    _cityController.text = profile.city ?? '';
    _districtController.text = profile.district ?? '';
    _wardController.text = profile.ward ?? '';
    _addressController.text = profile.address ?? '';
    _emergencyController.text = profile.emergencyContact ?? '';
    _relationshipController.text = profile.relationshipToUser ?? '';
    _gender = profile.gender;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    if (_catalog.profile != null) {
      _syncFromCatalog();
    }

    final loading = _catalog.isLoading && _catalog.profile == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF20C8C2), Color(0xFFF7FBFF)],
            stops: [0, 0.06],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    _CircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Chỉnh sửa thông tin cá nhân',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF203248),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionLabel('Hồ sơ'),
                              const SizedBox(height: 10),
                              _EditCard(
                                children: [
                                  _ReadOnlyField(
                                    label: 'Mã hồ sơ',
                                    value: _catalog.profile?.ecoreId ?? 'Chưa cập nhật',
                                  ),
                                  _ReadOnlyField(
                                    label: 'Username',
                                    value: _catalog.profile?.username ?? 'Chưa cập nhật',
                                  ),
                                  _RequiredField(
                                    label: 'Họ và tên',
                                    controller: _full_nameController,
                                    validator: _requiredValidator,
                                  ),
                                  _RequiredField(
                                    label: 'Ngày sinh',
                                    controller: _dateController,
                                    readOnly: true,
                                    onTap: _pickDate,
                                    suffixIcon: Icons.calendar_today_outlined,
                                    validator: _requiredValidator,
                                  ),
                                  _DropdownField(
                                    label: 'Giới tính',
                                    value: _gender,
                                    items: const ['Nam', 'Nữ', 'Khác'],
                                    onChanged: (value) => setState(() => _gender = value),
                                    validator: _requiredValidator,
                                  ),
                                  _RequiredField(
                                    label: 'Nghề nghiệp',
                                    controller: _occupationController,
                                    validator: _requiredValidator,
                                  ),
                                  _OptionalField(
                                    label: 'Quốc tịch',
                                    controller: _nationalityController,
                                  ),
                                  _OptionalField(
                                    label: 'Dân tộc',
                                    controller: _ethnicityController,
                                  ),
                                  _ReadOnlyField(
                                    label: 'CCCD',
                                    value: _catalog.profile?.citizenId ?? 'Chưa cập nhật',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const _SectionLabel('Thông tin liên hệ'),
                              const SizedBox(height: 10),
                              _EditCard(
                                children: [
                                  _RequiredField(
                                    label: 'Số điện thoại',
                                    controller: _phoneController,
                                    validator: _requiredValidator,
                                  ),
                                  _ReadOnlyField(
                                    label: 'Email',
                                    value: _catalog.profile?.email ?? 'Chưa cập nhật',
                                  ),
                                  _RequiredField(
                                    label: 'Tỉnh/Thành phố',
                                    controller: _cityController,
                                    validator: _requiredValidator,
                                  ),
                                  _RequiredField(
                                    label: 'Quận/Huyện',
                                    controller: _districtController,
                                    validator: _requiredValidator,
                                  ),
                                  _RequiredField(
                                    label: 'Phường/Xã',
                                    controller: _wardController,
                                    validator: _requiredValidator,
                                  ),
                                  _RequiredField(
                                    label: 'Địa chỉ chi tiết',
                                    controller: _addressController,
                                    validator: _requiredValidator,
                                    maxLines: 2,
                                  ),
                                  _OptionalField(
                                    label: 'Liên hệ khẩn cấp',
                                    controller: _emergencyController,
                                  ),
                                  _OptionalField(
                                    label: 'Quan hệ với người dùng',
                                    controller: _relationshipController,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF21C7B9), Color(0xFF359CFF)],
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x22309BFF),
                                      blurRadius: 14,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: _catalog.isSaving ? null : _saveProfile,
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _catalog.isSaving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Lưu thay đổi',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Trường này là bắt buộc';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final current = DateTime.tryParse(_dateController.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = _formatIsoDate(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ các trường bắt buộc.')),
      );
      return;
    }

    final payload = <String, dynamic>{
      'full_name': _full_nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'dateOfBirth': _dateController.text.trim(),
      'gender': _gender,
      'occupation': _occupationController.text.trim(),
      'nationality': _nationalityController.text.trim(),
      'ethnicity': _ethnicityController.text.trim(),
      'city': _cityController.text.trim(),
      'district': _districtController.text.trim(),
      'ward': _wardController.text.trim(),
      'address': _addressController.text.trim(),
      'emergencyContact': _emergencyController.text.trim(),
      'relationshipToUser': _relationshipController.text.trim(),
    };

    payload.removeWhere((_, value) => value == null || value.toString().trim().isEmpty);

    try {
      await _catalog.saveRemote(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thông tin cá nhân.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu hồ sơ: $e')),
      );
    }
  }

  String _formatIsoDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12094A69),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF5B6E85)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF7A8CA5),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _EditCard extends StatelessWidget {
  const _EditCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10084B6B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10084B6B),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0x1420C8C2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF20BEB7)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF24364E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Color(0xFF7D90A7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF97A8BC)),
          ],
        ),
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.label,
    required this.value,
    this.centered = false,
  });

  final String label;
  final String value;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(fontSize: 11, color: Color(0xFFABB6C7)),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF273750),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: value,
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF99A8BB)),
          disabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE4EBF3)),
          ),
        ),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF283A53)),
      ),
    );
  }
}

class _OptionalField extends StatelessWidget {
  const _OptionalField({
    required this.label,
    this.controller,
    this.value,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? value;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? value : null,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF99A8BB)),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE4EBF3)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF2BC6BE)),
          ),
        ),
        style: TextStyle(
          fontSize: 15,
          fontWeight: readOnly ? FontWeight.w600 : FontWeight.w700,
          color: readOnly ? const Color(0xFF7B8DA6) : const Color(0xFF283A53),
        ),
      ),
    );
  }
}

class _RequiredField extends StatelessWidget {
  const _RequiredField({
    required this.label,
    required this.controller,
    required this.validator,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? suffixIcon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        validator: validator,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: '$label *',
          suffixIcon: suffixIcon == null ? null : Icon(suffixIcon, size: 18),
          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF99A8BB)),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE4EBF3)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF2BC6BE)),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF283A53)),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.validator,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: '$label *',
          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF99A8BB)),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE4EBF3)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF2BC6BE)),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF34455E)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
