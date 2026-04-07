import 'package:flutter/material.dart';

import '../../../core/network/admin_api_exception.dart';
import '../../../theme/admin_app_theme.dart';
import '../data/admin_specialties_service.dart';
import '../domain/admin_specialty.dart';
import 'specialty_visuals.dart';

class SpecialtyFormScreen extends StatefulWidget {
  const SpecialtyFormScreen({
    super.key,
    this.specialty,
    this.suggestedSortOrder = 0,
    AdminSpecialtiesService? service,
  }) : _service = service;

  final AdminSpecialty? specialty;
  final int suggestedSortOrder;
  final AdminSpecialtiesService? _service;

  bool get isEditing => specialty != null;

  @override
  State<SpecialtyFormScreen> createState() => _SpecialtyFormScreenState();
}

class _SpecialtyFormScreenState extends State<SpecialtyFormScreen> {
  late final AdminSpecialtiesService _service;
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;

  bool _isActive = true;
  bool _isSaving = false;
  String? _errorText;
  String _selectedIconKey = SpecialtyVisuals.options.first.key;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? AdminSpecialtiesService();
    final specialty = widget.specialty;
    _nameController = TextEditingController(text: specialty?.name ?? '');
    _codeController = TextEditingController(text: specialty?.code ?? '');
    _descriptionController = TextEditingController(
      text: specialty?.description ?? '',
    );
    _isActive = specialty?.isActive ?? true;
    _selectedIconKey = specialty != null
        ? SpecialtyVisuals.fromSpecialty(specialty).key
        : SpecialtyVisuals.options.first.key;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || code.isEmpty) {
      setState(() {
        _errorText = 'Vui lòng nhập tên và mã chuyên khoa.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSaving = true;
    });

    final payload = AdminSpecialtyPayload(
      name: name,
      code: code,
      description: description,
      sortOrder: widget.specialty?.sortOrder ?? widget.suggestedSortOrder,
      isActive: _isActive,
    );

    try {
      if (widget.isEditing) {
        await _service.updateSpecialty(widget.specialty!.id, payload);
      } else {
        await _service.createSpecialty(payload);
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
            : 'Không thể lưu chuyên khoa.';
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
                      Expanded(
                        child: Text(
                          widget.isEditing
                              ? 'Cập nhật chuyên khoa'
                              : 'Thêm chuyên khoa',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _FormLabel(label: 'Tên chuyên khoa'),
                  _FormField(controller: _nameController),
                  const SizedBox(height: 12),
                  _FormLabel(label: 'Mã chuyên khoa'),
                  _FormField(
                    controller: _codeController,
                    hintText: 'VD: TIM_MACH',
                  ),
                  const SizedBox(height: 12),
                  _FormLabel(label: 'Mô tả'),
                  _FormField(
                    controller: _descriptionController,
                    hintText: 'Mô tả ngắn về chuyên khoa này',
                    minLines: 3,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  _FormLabel(label: 'Chọn icon'),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: SpecialtyVisuals.options.map((option) {
                      final selected = option.key == _selectedIconKey;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIconKey = option.key;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: option.backgroundColor,
                            border: Border.all(
                              color: selected
                                  ? AdminAppTheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            option.icon,
                            color: option.iconColor,
                            size: 22,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trạng thái',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hiển thị chuyên khoa cho người dùng',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
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
                      child: Text(
                        _isSaving ? 'Đang lưu...' : 'Lưu chuyên khoa',
                      ),
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
    this.hintText,
    this.minLines,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String? hintText;
  final int? minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
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
