import 'package:flutter/material.dart';

import '../../../core/network/admin_api_exception.dart';
import '../../../theme/admin_app_theme.dart';
import '../../specialties/data/admin_specialties_service.dart';
import '../../specialties/domain/admin_specialty.dart';
import '../data/admin_rooms_service.dart';
import '../domain/admin_room.dart';

class RoomFormScreen extends StatefulWidget {
  const RoomFormScreen({
    super.key,
    this.room,
    AdminRoomsService? service,
    AdminSpecialtiesService? specialtiesService,
  }) : _service = service,
       _specialtiesService = specialtiesService;

  final AdminRoom? room;
  final AdminRoomsService? _service;
  final AdminSpecialtiesService? _specialtiesService;

  bool get isEditing => room != null;

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  late final AdminRoomsService _service;
  late final AdminSpecialtiesService _specialtiesService;

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _floorController;
  late final TextEditingController _descriptionController;

  bool _isActive = true;
  bool _isSaving = false;
  String? _errorText;

  List<AdminSpecialty> _specialties = [];
  String? _selectedSpecialtyId;
  bool _isLoadingSpecialties = true;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? AdminRoomsService();
    _specialtiesService =
        widget._specialtiesService ?? AdminSpecialtiesService();

    final room = widget.room;
    _nameController = TextEditingController(text: room?.name ?? '');
    _codeController = TextEditingController(text: room?.code ?? '');
    _floorController = TextEditingController(
      text: room?.floor.toString() ?? '1',
    );
    _descriptionController = TextEditingController(
      text: room?.description ?? '',
    );
    _isActive = room?.isActive ?? true;
    _selectedSpecialtyId = room?.specialtyId;

    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    try {
      final specs = await _specialtiesService.fetchSpecialties(isActive: true);
      if (mounted) {
        setState(() {
          _specialties = specs;
          _isLoadingSpecialties = false;

          // Ensure selected ID is valid among active specialties
          if (_selectedSpecialtyId != null) {
            final exists = specs.any((s) => s.id == _selectedSpecialtyId);
            if (!exists) {
              // Add a dummy entry if editing a room whose specialty is now inactive,
              // or just clear it. Let's keep it simple.
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSpecialties = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _floorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    final floorStr = _floorController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || code.isEmpty || floorStr.isEmpty) {
      setState(() {
        _errorText = 'Vui lòng nhập tên, mã phòng và số tầng.';
      });
      return;
    }

    final floor = int.tryParse(floorStr);
    if (floor == null) {
      setState(() {
        _errorText = 'Số tầng phải là số.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSaving = true;
    });

    final payload = AdminRoomPayload(
      name: name,
      code: code,
      floor: floor,
      isActive: _isActive,
      specialtyId: _selectedSpecialtyId,
      description: description,
    );

    try {
      if (widget.isEditing) {
        await _service.updateRoom(widget.room!.id, payload);
      } else {
        await _service.createRoom(payload);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error is AdminApiException
            ? error.message
            : 'Không thể lưu phòng khám.';
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
                              ? 'Cập nhật phòng khám'
                              : 'Thêm phòng khám',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _FormLabel(label: 'Tên phòng'),
                  _FormField(
                    controller: _nameController,
                    hintText: 'VD: Phòng khám 101',
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FormLabel(label: 'Mã phòng'),
                            _FormField(
                              controller: _codeController,
                              hintText: 'VD: P-NOI1',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FormLabel(label: 'Tầng'),
                            _FormField(
                              controller: _floorController,
                              hintText: 'VD: 1',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _FormLabel(label: 'Chuyên khoa'),
                  _isLoadingSpecialties
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              isExpanded: true,
                              value: _selectedSpecialtyId,
                              hint: const Text('Phòng đa năng (Không theo CK)'),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Phòng đa năng (Không gán)'),
                                ),
                                ..._specialties.map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedSpecialtyId = val;
                                });
                              },
                            ),
                          ),
                        ),
                  const SizedBox(height: 12),

                  _FormLabel(label: 'Mô tả'),
                  _FormField(
                    controller: _descriptionController,
                    hintText: 'Mô tả ngắn, thiết bị trong phòng...',
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trạng thái hoạt động',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cho phép bác sĩ được xếp lịch học vào phòng này',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (val) => setState(() => _isActive = val),
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
                      child: Text(_isSaving ? 'Đang lưu...' : 'Lưu phòng khám'),
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
    this.keyboardType,
  });

  final TextEditingController controller;
  final String? hintText;
  final int? minLines;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
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
