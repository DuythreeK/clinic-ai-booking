import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/app_route_observer.dart';
import 'vaccination_booking_models.dart';
import 'vaccination_booking_widgets.dart';
import '../utils/vietnam_address_catalog.dart';

class VaccinationBookingScreen extends StatefulWidget {
  const VaccinationBookingScreen({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<VaccinationBookingScreen> createState() => _VaccinationBookingScreenState();
}

class _VaccinationBookingScreenState extends State<VaccinationBookingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'Tất cả';

  @override
  void initState() {
    super.initState();
    VaccinationBookingCatalog.loadRemote().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final packages = VaccinationBookingCatalog.packages.where((item) {
      final keyword = _searchController.text.trim().toLowerCase();
      if (keyword.isEmpty) return true;
      return item.title.toLowerCase().contains(keyword) ||
          item.facilityName.toLowerCase().contains(keyword);
    }).toList();

    return VaccinationPageScaffold(
      title: 'Đặt lịch tiêm chủng',
      onBack: widget.embedded
          ? null
          : () {
              if (context.canPop()) context.pop();
            },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          VaccinationSearchBar(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            trailing: FilterButton(
              onTap: () => context.push('/vaccination-booking/filter'),
            ),
          ),
          const SizedBox(height: 14),
          SwitchChips(
            values: const ['Tất cả', 'Cơ sở y tế'],
            selected: _selectedTab,
            onSelect: (value) {
              setState(() => _selectedTab = value);
              if (value == 'Cơ sở y tế') {
                context.push('/vaccination-booking/facilities');
              }
            },
          ),
          const SizedBox(height: 16),
          ...packages.map((item) {
            final facility = VaccinationBookingCatalog.facilityById(item.facilityId);
            return _VaccinationPackageCard(
              item: item,
              facility: facility,
              onTap: () => context.push(
                '/vaccination-booking/visit-info',
                extra: VaccinationBookingCatalog.draftFromPackage(item),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class VaccinationFacilityScreen extends StatefulWidget {
  const VaccinationFacilityScreen({super.key});

  @override
  State<VaccinationFacilityScreen> createState() => _VaccinationFacilityScreenState();
}

class _VaccinationFacilityScreenState extends State<VaccinationFacilityScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    VaccinationBookingCatalog.loadRemote().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facilities = VaccinationBookingCatalog.facilities.where((item) {
      final keyword = _searchController.text.trim().toLowerCase();
      if (keyword.isEmpty) return true;
      return item.name.toLowerCase().contains(keyword) ||
          item.address.toLowerCase().contains(keyword);
    }).toList();

    return VaccinationPageScaffold(
      title: 'Đặt lịch tiêm chủng',
      onBack: () => context.pop(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          VaccinationSearchBar(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            trailing: FilterButton(
              onTap: () => context.push('/vaccination-booking/filter'),
            ),
          ),
          const SizedBox(height: 14),
          SwitchChips(
            values: const ['Tất cả', 'Cơ sở y tế'],
            selected: 'Cơ sở y tế',
            onSelect: (value) {
              if (value == 'Tất cả') {
                context.pop();
              }
            },
          ),
          const SizedBox(height: 16),
          ...facilities.map(
            (facility) => _FacilityCard(
              facility: facility,
              onTap: () => context.push(
                '/vaccination-booking/visit-info',
                extra: VaccinationBookingCatalog.draftFromFacility(facility),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VaccinationVisitInfoScreen extends StatefulWidget {
  const VaccinationVisitInfoScreen({
    super.key,
    required this.draft,
  });

  final VaccinationBookingDraft draft;

  @override
  State<VaccinationVisitInfoScreen> createState() => _VaccinationVisitInfoScreenState();
}

class _VaccinationVisitInfoScreenState extends State<VaccinationVisitInfoScreen> {
  VaccinationBookingDetail? _detail;
  String? _selectedDate;
  int? _selectedSlotId;
  String? _selectedSlotLabel;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    VaccinationBookingCatalog.loadRemote();
    _loadDetail();
  }

  int? _resolveServiceId() {
    if (widget.draft.serviceId != null) return widget.draft.serviceId;
    final candidates = VaccinationBookingCatalog.packages
        .where((item) => item.facilityId == widget.draft.facilityId)
        .toList();
    if (candidates.isEmpty) {
      return VaccinationBookingCatalog.packages.isEmpty ? null : int.tryParse(VaccinationBookingCatalog.packages.first.id);
    }

    final matchedByTitle = candidates.where((item) => item.title == widget.draft.serviceName).toList();
    final package = matchedByTitle.isNotEmpty ? matchedByTitle.first : candidates.first;
    return int.tryParse(package.id);
  }

  Future<void> _loadDetail() async {
    final serviceId = _resolveServiceId();
    if (serviceId == null) {
      setState(() {
        _loading = false;
        _error = 'Không xác định được gói tiêm chủng.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final detail = await VaccinationBookingCatalog.loadDetail(serviceId: serviceId.toString());
    if (!mounted) return;

    if (detail == null || detail.slots.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Chưa có lịch hẹn khả dụng cho gói này.';
      });
      return;
    }

    final firstGroup = detail.slots.first;
    final firstSlot = firstGroup.morningSlots.isNotEmpty
        ? firstGroup.morningSlots.first
        : firstGroup.afternoonSlots.isNotEmpty
            ? firstGroup.afternoonSlots.first
            : null;

    setState(() {
      _detail = detail;
      _selectedDate = firstGroup.date;
      _selectedSlotId = firstSlot?.slotId;
      _selectedSlotLabel = firstSlot == null ? null : '${firstSlot.startTime ?? ''} - ${firstSlot.endTime ?? ''}'.trim();
      _loading = false;
    });
  }

  VaccinationSlotGroup? _selectedGroup() {
    final detail = _detail;
    final selectedDate = _selectedDate;
    if (detail == null || selectedDate == null) return null;
    for (final group in detail.slots) {
      if (group.date == selectedDate) return group;
    }
    return detail.slots.isNotEmpty ? detail.slots.first : null;
  }

  void _selectGroup(VaccinationSlotGroup group) {
    final slot = group.morningSlots.isNotEmpty
        ? group.morningSlots.first
        : group.afternoonSlots.isNotEmpty
            ? group.afternoonSlots.first
            : null;
    setState(() {
      _selectedDate = group.date;
      _selectedSlotId = slot?.slotId;
      _selectedSlotLabel = slot == null ? null : '${slot.startTime ?? ''} - ${slot.endTime ?? ''}'.trim();
    });
  }

  void _selectSlot(VaccinationSlotItem item) {
    setState(() {
      _selectedSlotId = item.slotId;
      _selectedSlotLabel = '${item.startTime ?? ''} - ${item.endTime ?? ''}'.trim();
    });
  }

  String _displayDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final weekday = ['CN', 'Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7'][parsed.weekday % 7];
    return '$day/$month\n$weekday';
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final facility = detail?.facility ?? VaccinationBookingCatalog.facilityById(widget.draft.facilityId);
    final selectedGroup = _selectedGroup();
    final safeDetail = detail;

    return VaccinationPageScaffold(
      title: 'Chọn thông tin khám',
      onBack: () => context.pop(),
      bottom: _loading || _error != null || detail == null
          ? null
          : PrimaryActionBar(
              label: 'TIẾP TỤC',
              onTap: () {
                if (_selectedSlotId == null || selectedGroup == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng chọn ngày và giờ khám.')),
                  );
                  return;
                }

                context.push(
                  '/vaccination-booking/profile',
                  extra: widget.draft.copyWith(
                    facilityId: facility.id,
                    facilityName: facility.name,
                    facilityAddress: facility.address,
                    serviceId: detail.serviceId,
                    serviceName: detail.serviceName,
                    servicePriceLabel: detail.servicePriceLabel,
                    servicePriceValue: detail.servicePriceValue,
                    dateLabel: _displayDate(selectedGroup.date).replaceAll('\n', ' '),
                    slotLabel: _selectedSlotLabel ?? '',
                    slotId: _selectedSlotId,
                    appointmentDate: selectedGroup.date,
                    appointmentTime: _selectedSlotLabel,
                  ),
                );
              },
            ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadDetail,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    const StepHeader(currentStep: 1),
                    const SizedBox(height: 18),
                    SummaryCard(
                      title: facility.name,
                      subtitle: facility.address,
                    ),
                    const SizedBox(height: 16),
                    const SectionTitle('Chuyên khoa'),
                    const SizedBox(height: 8),
                    const _OutlinedSelectTile(
                      icon: Icons.medical_services_outlined,
                      title: 'TIÊM NGỪA',
                      subtitle: null,
                    ),
                    const SizedBox(height: 14),
                    const SectionTitle('Dịch vụ'),
                    const SizedBox(height: 8),
                    _OutlinedSelectTile(
                      icon: Icons.vaccines_outlined,
                      title: safeDetail!.serviceName,
                      subtitle: safeDetail.servicePriceLabel,
                    ),
                    const SizedBox(height: 14),
                    const SectionTitle('Ngày khám'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: safeDetail.slots.map((item) {
                        return ChoiceChipPill(
                          label: _displayDate(item.date),
                          selected: _selectedDate == item.date,
                          onTap: () => _selectGroup(item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const SectionTitle('Buổi sáng'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (selectedGroup?.morningSlots ?? const <VaccinationSlotItem>[]).map((item) {
                        final label = '${item.startTime ?? ''} - ${item.endTime ?? ''}'.trim();
                        return ChoiceChipPill(
                          label: label,
                          subtitle: '${item.availableCount} chỗ',
                          selected: _selectedSlotId == item.slotId,
                          onTap: () => _selectSlot(item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const SectionTitle('Buổi chiều'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (selectedGroup?.afternoonSlots ?? const <VaccinationSlotItem>[]).map((item) {
                        final label = '${item.startTime ?? ''} - ${item.endTime ?? ''}'.trim();
                        return ChoiceChipPill(
                          label: label,
                          subtitle: '${item.availableCount} chỗ',
                          selected: _selectedSlotId == item.slotId,
                          onTap: () => _selectSlot(item),
                        );
                      }).toList(),
                    ),
                  ],
                ),
    );
  }
}

class VaccinationProfileScreen extends StatefulWidget {
  const VaccinationProfileScreen({
    super.key,
    required this.draft,
  });

  final VaccinationBookingDraft draft;

  @override
  State<VaccinationProfileScreen> createState() => _VaccinationProfileScreenState();
}

class _VaccinationProfileScreenState extends State<VaccinationProfileScreen> with RouteAware {
  VaccinationPatientProfile? _selectedProfile;
  bool _loading = true;
  bool _subscribedToRouteObserver = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscribedToRouteObserver) return;
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
      _subscribedToRouteObserver = true;
    }
  }

  @override
  void didPopNext() {
    _loadProfiles();
  }

  @override
  void dispose() {
    if (_subscribedToRouteObserver) {
      appRouteObserver.unsubscribe(this);
    }
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    await VaccinationBookingCatalog.loadPatientProfiles();
    if (!mounted) return;
    final profiles = VaccinationBookingCatalog.patientProfiles;
    VaccinationPatientProfile? selected;
    if (profiles.isNotEmpty) {
      for (final profile in profiles) {
        if (profile.isPrimary) {
          selected = profile;
          break;
        }
      }
      selected ??= profiles.first;
    }

    setState(() {
      _selectedProfile = selected;
      _loading = false;
    });
  }

  String _profileLabel(VaccinationPatientProfile? profile) {
    if (profile == null) return 'CHƯA TỪNG KHÁM ĐĂNG KÝ MỚI';
    final parts = <String>[];
    if (profile.gender != null && profile.gender!.isNotEmpty) parts.add(profile.gender!);
    if (profile.birthDate != null && profile.birthDate!.isNotEmpty) parts.add(profile.birthDate!);
    return parts.isEmpty ? profile.fullName : '${profile.fullName} • ${parts.join(' • ')}';
  }

  VaccinationBookingDraft _buildDraftFromProfile(VaccinationPatientProfile profile) {
    return widget.draft.copyWith(
      patientProfileId: profile.id,
      profileLabel: _profileLabel(profile),
      patientName: profile.fullName,
      phone: profile.phoneNumber ?? widget.draft.phone,
      fullName: profile.fullName,
      birthDate: profile.birthDate ?? widget.draft.birthDate,
      gender: profile.gender ?? widget.draft.gender,
      identityNumber: profile.citizenId ?? widget.draft.identityNumber,
      insuranceNumber: profile.insuranceNumber ?? widget.draft.insuranceNumber,
      email: profile.email ?? widget.draft.email,
      occupation: profile.occupation ?? widget.draft.occupation,
      country: profile.nationality ?? widget.draft.country,
      ethnicity: profile.ethnicity ?? widget.draft.ethnicity,
      city: profile.province ?? widget.draft.city,
      district: profile.district ?? widget.draft.district,
      ward: profile.ward ?? widget.draft.ward,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = VaccinationBookingCatalog.patientProfiles;
    final hasProfiles = profiles.isNotEmpty;
    final selectedProfile = _selectedProfile;
    final selectedDraft = selectedProfile == null
        ? widget.draft
        : _buildDraftFromProfile(selectedProfile);

    return VaccinationPageScaffold(
      title: 'Chọn hồ sơ',
      onBack: () => context.pop(),
      bottom: selectedProfile == null
          ? null
          : PrimaryActionBar(
              label: 'TIẾP TỤC',
              onTap: () {
                context.push('/vaccination-booking/confirm', extra: selectedDraft);
              },
            ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                const StepHeader(currentStep: 2),
                const SizedBox(height: 18),
                if (!hasProfiles) ...[
                  Container(
                    height: 340,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 38,
                          backgroundColor: Color(0xFFE5E8EE),
                          child: Icon(Icons.description_outlined, size: 34, color: Color(0xFF8A98AA)),
                        ),
                        const SizedBox(height: 18),
                        TextButton(
                          onPressed: () => context.push('/vaccination-booking/confirm', extra: widget.draft),
                          child: const Text('CHƯA TỪNG KHÁM ĐĂNG KÝ MỚI'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ...profiles.map((profile) {
                    final selected = _selectedProfile?.id == profile.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => setState(() => _selectedProfile = profile),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFE9F8FF) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? VaccinationBookingColors.blue : VaccinationBookingColors.line,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                color: selected ? VaccinationBookingColors.blue : VaccinationBookingColors.subtext,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.fullName,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _profileLabel(profile),
                                      style: const TextStyle(fontSize: 12, color: VaccinationBookingColors.subtext),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                profile.isPrimary ? 'Chính' : 'Phụ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: selected ? VaccinationBookingColors.blue : VaccinationBookingColors.subtext,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.push('/vaccination-booking/confirm', extra: widget.draft),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('CHƯA TỪNG KHÁM ĐĂNG KÝ MỚI'),
                  ),
                ],
              ],
            ),
    );
  }
}

class VaccinationConfirmScreen extends StatefulWidget {
  const VaccinationConfirmScreen({
    super.key,
    required this.draft,
  });

  final VaccinationBookingDraft draft;

  @override
  State<VaccinationConfirmScreen> createState() => _VaccinationConfirmScreenState();
}

class _VaccinationConfirmScreenState extends State<VaccinationConfirmScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _birthController;
  late final TextEditingController _identityController;
  late final TextEditingController _insuranceController;
  late final TextEditingController _emailController;
  late final TextEditingController _occupationController;
  late final TextEditingController _countryController;
  late final TextEditingController _ethnicityController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _wardController;
  String _gender = 'Nam';
  bool _submitted = false;

  List<String> get _provinceOptions {
    final provinces = VietnamAddressCatalog.provinces()
        .map(VietnamAddressCatalog.displayName)
        .where((value) => value.isNotEmpty)
        .toList();
    return <String>[VietnamAddressCatalog.provincePlaceholder, ...provinces];
  }

  List<String> get _districtOptions {
    if (_cityController.text.trim().isEmpty) {
      return const [VietnamAddressCatalog.districtPlaceholder];
    }
    final districts = VietnamAddressCatalog.districtsByProvinceName(_cityController.text)
        .map(VietnamAddressCatalog.displayName)
        .where((value) => value.isNotEmpty)
        .toList();
    return <String>[VietnamAddressCatalog.districtPlaceholder, ...districts];
  }

  List<String> get _wardOptions {
    if (_cityController.text.trim().isEmpty || _districtController.text.trim().isEmpty) {
      return const [VietnamAddressCatalog.wardPlaceholder];
    }
    final wards = VietnamAddressCatalog.wardsBySelection(_cityController.text, _districtController.text)
        .map(VietnamAddressCatalog.displayName)
        .where((value) => value.isNotEmpty)
        .toList();
    return <String>[VietnamAddressCatalog.wardPlaceholder, ...wards];
  }

  String _normalizeProvince(String value) {
    final normalized = VietnamAddressCatalog.displayName(VietnamAddressCatalog.provinceByName(value));
    return normalized.isEmpty ? value : normalized;
  }

  String _normalizeDistrict(String province, String district) {
    final normalized = VietnamAddressCatalog.displayName(VietnamAddressCatalog.districtByName(province, district));
    return normalized.isEmpty ? district : normalized;
  }

  String _normalizeWard(String province, String district, String ward) {
    final selectedProvince = _normalizeProvince(province);
    final selectedDistrict = _normalizeDistrict(province, district);
    if (selectedProvince.trim().isEmpty || selectedDistrict.trim().isEmpty || ward.trim().isEmpty) {
      return ward;
    }
    final wards = VietnamAddressCatalog.wardsBySelection(selectedProvince, selectedDistrict);
    for (final item in wards) {
      final itemName = VietnamAddressCatalog.displayName(item);
      if (itemName.toLowerCase() == ward.trim().toLowerCase()) return itemName;
    }
    return ward;
  }

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.draft.phone);
    _fullNameController = TextEditingController(text: widget.draft.fullName);
    _birthController = TextEditingController(text: widget.draft.birthDate);
    _identityController = TextEditingController(text: widget.draft.identityNumber);
    _insuranceController = TextEditingController(text: widget.draft.insuranceNumber);
    _emailController = TextEditingController(text: widget.draft.email);
    _occupationController = TextEditingController(text: widget.draft.occupation);
    _countryController = TextEditingController(text: widget.draft.country);
    _ethnicityController = TextEditingController(text: widget.draft.ethnicity);
    _cityController = TextEditingController(text: _normalizeProvince(widget.draft.city));
    _districtController = TextEditingController(text: _normalizeDistrict(widget.draft.city, widget.draft.district));
    _wardController = TextEditingController(text: _normalizeWard(widget.draft.city, widget.draft.district, widget.draft.ward));
    _gender = widget.draft.gender;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fullNameController.dispose();
    _birthController.dispose();
    _identityController.dispose();
    _insuranceController.dispose();
    _emailController.dispose();
    _occupationController.dispose();
    _countryController.dispose();
    _ethnicityController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facility = VaccinationBookingCatalog.facilityById(widget.draft.facilityId);

    return VaccinationPageScaffold(
      title: 'Xác nhận thông tin',
      onBack: () => context.pop(),
      bottom: PrimaryActionBar(
        label: 'TIẾP TỤC',
        onTap: () async {
          setState(() => _submitted = true);
          final isValid = _formKey.currentState?.validate() ?? false;
          if (!isValid) return;

          final updatedDraft = widget.draft.copyWith(
            facilityId: facility.id,
            facilityName: facility.name,
            facilityAddress: facility.address,
            phone: _phoneController.text.trim(),
            fullName: _fullNameController.text.trim(),
            birthDate: _birthController.text.trim(),
            gender: _gender,
            identityNumber: _identityController.text.trim(),
            insuranceNumber: _insuranceController.text.trim(),
            email: _emailController.text.trim(),
            occupation: _occupationController.text.trim(),
            country: _countryController.text.trim(),
            ethnicity: _ethnicityController.text.trim(),
            city: _cityController.text.trim(),
            district: _districtController.text.trim(),
            ward: _wardController.text.trim(),
            patientProfileId: widget.draft.patientProfileId,
            patientName: _fullNameController.text.trim().isEmpty
                ? widget.draft.patientName
                : _fullNameController.text.trim(),
          );

          if (widget.draft.patientProfileId != null) {
            await VaccinationBookingCatalog.updatePatientProfile(
              patientId: widget.draft.patientProfileId!,
              fullName: _fullNameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              citizenId: _identityController.text.trim(),
              insuranceNumber: _insuranceController.text.trim(),
              email: _emailController.text.trim(),
              gender: _gender,
              dateOfBirth: _birthController.text.trim(),
              occupation: _occupationController.text.trim(),
              nationality: _countryController.text.trim(),
              ethnicity: _ethnicityController.text.trim(),
              province: _cityController.text.trim(),
              district: _districtController.text.trim(),
              ward: _wardController.text.trim(),
              addressDetail: [_cityController.text.trim(), _districtController.text.trim(), _wardController.text.trim()]
                  .where((value) => value.isNotEmpty)
                  .join(', '),
              emergencyContact: _phoneController.text.trim(),
            );
          }

          context.push(
            '/vaccination-booking/payment',
            extra: updatedDraft,
          );
        },
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            const StepHeader(currentStep: 3),
            const SizedBox(height: 18),
            SummaryCard(
              title: facility.name,
              subtitle: facility.address,
            ),
            const SizedBox(height: 14),
            const SectionTitle('Thông tin đặt khám'),
            const SizedBox(height: 8),
            _InfoPanel(
              children: [
                _SummaryLine(icon: Icons.medical_services_outlined, text: widget.draft.specialty),
                _SummaryLine(icon: Icons.vaccines_outlined, text: widget.draft.serviceName),
                _SummaryLine(
                  icon: Icons.calendar_month_outlined,
                  text: '${widget.draft.dateLabel} (${widget.draft.slotLabel})',
                ),
                _SummaryLine(
                  icon: Icons.payments_outlined,
                  text: widget.draft.servicePriceLabel,
                  emphasize: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const SectionTitle('Thông tin người khám'),
            const SizedBox(height: 8),
            _FormField(
              label: 'Số điện thoại',
              controller: _phoneController,
              requiredField: true,
            ),
            _FormField(
              label: 'Họ và tên',
              controller: _fullNameController,
              requiredField: true,
            ),
            Row(
              children: [
                Expanded(
                  child: _FormField(
                    label: 'Ngày sinh',
                    controller: _birthController,
                    suffix: const Icon(Icons.calendar_month_outlined, size: 18),
                    requiredField: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DropField(
                    label: 'Giới tính',
                    value: _gender,
                    values: const ['Chọn giới tính', 'Nam', 'Nữ'],
                    requiredField: true,
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                ),
              ],
            ),
            _FormField(
              label: 'Mã định danh/CCCD',
              controller: _identityController,
              requiredField: true,
              keyboardType: TextInputType.number,
            ),
            _FormField(
              label: 'Mã bảo hiểm y tế',
              controller: _insuranceController,
              requiredField: true,
              keyboardType: TextInputType.text,
            ),
            _FormField(
              label: 'Email',
              controller: _emailController,
              requiredField: true,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập đầy đủ thông tin';
                }
                final email = value.trim();
                final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailPattern.hasMatch(email)) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),
            _DropField(
              label: 'Nghề nghiệp',
              value: _occupationController.text.isEmpty ? 'Chọn nghề nghiệp' : _occupationController.text,
              values: const ['Chọn nghề nghiệp', 'Nhân viên văn phòng', 'Sinh viên'],
              requiredField: true,
              onChanged: (value) => setState(() => _occupationController.text = value == 'Chọn nghề nghiệp' ? '' : value),
            ),
            _DropField(
              label: 'Quốc gia',
              value: _countryController.text.isEmpty ? 'Chọn quốc gia' : _countryController.text,
              values: const ['Chọn quốc gia', 'Việt Nam'],
              requiredField: true,
              onChanged: (value) => setState(() => _countryController.text = value == 'Chọn quốc gia' ? '' : value),
            ),
            _DropField(
              label: 'Dân tộc',
              value: _ethnicityController.text.isEmpty ? 'Chọn dân tộc' : _ethnicityController.text,
              values: const ['Chọn dân tộc', 'Kinh', 'Hoa'],
              requiredField: true,
              onChanged: (value) => setState(() => _ethnicityController.text = value == 'Chọn dân tộc' ? '' : value),
            ),
            _DropField(
              label: 'Tỉnh/Thành phố',
              value: _cityController.text.isEmpty ? 'Chọn Tỉnh/Thành phố' : _cityController.text,
              values: _provinceOptions,
              requiredField: true,
              onChanged: (value) => setState(() {
                _cityController.text = value == VietnamAddressCatalog.provincePlaceholder ? '' : value;
                _districtController.text = '';
                _wardController.text = '';
              }),
            ),
            _DropField(
              label: 'Quận/Huyện',
              value: _districtController.text.isEmpty ? 'Chọn Quận/Huyện' : _districtController.text,
              values: _districtOptions,
              requiredField: true,
              onChanged: (value) => setState(() {
                _districtController.text = value == VietnamAddressCatalog.districtPlaceholder ? '' : value;
                _wardController.text = '';
              }),
            ),
            _DropField(
              label: 'Phường/Xã',
              value: _wardController.text.isEmpty ? 'Chọn Phường/Xã' : _wardController.text,
              values: _wardOptions,
              requiredField: true,
              onChanged: (value) => setState(() => _wardController.text = value == VietnamAddressCatalog.wardPlaceholder ? '' : value),
            ),
          ],
        ),
      ),
    );
  }
}

class VaccinationPaymentScreen extends StatefulWidget {
  const VaccinationPaymentScreen({
    super.key,
    required this.draft,
  });

  final VaccinationBookingDraft draft;

  @override
  State<VaccinationPaymentScreen> createState() => _VaccinationPaymentScreenState();
}

class _VaccinationPaymentScreenState extends State<VaccinationPaymentScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final facility = VaccinationBookingCatalog.facilityById(widget.draft.facilityId);

    return VaccinationPageScaffold(
      title: 'Chọn hồ sơ',
      onBack: () => context.pop(),
      bottom: PrimaryActionBar(
        label: _isSubmitting ? 'ĐANG XỬ LÝ...' : 'HOÀN THÀNH ĐẶT LỊCH',
        onTap: () {
          if (_isSubmitting) return;
          _submitBooking();
        },
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          const StepHeader(currentStep: 4),
          const SizedBox(height: 18),
          SummaryCard(
            title: facility.name,
            subtitle: facility.address,
          ),
          const SizedBox(height: 14),
          SummaryCard(
            title: 'Thông tin bệnh nhân',
            subtitle: widget.draft.patientName.isEmpty ? 'Nguyễn Văn A' : widget.draft.patientName,
          ),
          const SizedBox(height: 14),
          _InfoPanel(
            children: [
              _SummaryLine(icon: Icons.medical_services_outlined, text: widget.draft.specialty),
              _SummaryLine(icon: Icons.vaccines_outlined, text: widget.draft.serviceName),
              _SummaryLine(icon: Icons.calendar_month_outlined, text: '${widget.draft.dateLabel} (${widget.draft.slotLabel})'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (_isSubmitting) return;

    final serviceId = widget.draft.serviceId;
    final slotId = widget.draft.slotId;
    final facilityId = widget.draft.facilityId;
    if (serviceId == null || slotId == null || facilityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu thông tin lịch tiêm.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      var patientId = widget.draft.patientProfileId;
      if (patientId == null) {
        final createdProfile = await VaccinationBookingCatalog.createPatientProfile(
          fullName: widget.draft.fullName.isNotEmpty ? widget.draft.fullName : widget.draft.patientName,
          phoneNumber: widget.draft.phone,
          citizenId: widget.draft.identityNumber.trim(),
          insuranceNumber: widget.draft.insuranceNumber.trim(),
          email: widget.draft.email.trim(),
          gender: widget.draft.gender,
          dateOfBirth: widget.draft.birthDate,
          occupation: widget.draft.occupation,
          nationality: widget.draft.country,
          ethnicity: widget.draft.ethnicity,
          province: widget.draft.city,
          district: widget.draft.district,
          ward: widget.draft.ward,
          addressDetail: [widget.draft.city, widget.draft.district, widget.draft.ward]
              .where((value) => value.trim().isNotEmpty)
              .join(', '),
          emergencyContact: widget.draft.phone,
          relationshipToUser: 'Bản thân',
        );
        patientId = createdProfile?.id;
      }

      if (patientId == null) {
        throw Exception('Không tạo được hồ sơ bệnh nhân.');
      }

      final appointment = await VaccinationBookingCatalog.createAppointment(
        patientId: patientId.toString(),
        facilityId: facilityId.toString(),
        serviceId: serviceId.toString(),
        slotId: slotId.toString(),
        appointmentDate: widget.draft.appointmentDate ?? widget.draft.dateLabel,
        appointmentTime: widget.draft.appointmentTime ?? widget.draft.slotLabel,
        note: 'Đặt lịch tiêm chủng',
        symptomsNote: 'Đăng ký tiêm chủng',
      );

      final appointmentId = appointment?['id']?.toString();
      if (appointmentId == null || appointmentId.isEmpty) {
        throw Exception('Không tạo được lịch hẹn.');
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Đặt lịch thành công'),
            content: const Text('Lịch tiêm chủng của bạn đã được tạo thành công và đã cập nhật vào mục Lịch hẹn.'),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Xem lịch hẹn'),
              ),
            ],
          );
        },
      );
      if (!mounted) return;
      context.go('/appointments');
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể hoàn tất đặt lịch: ${_extractErrorMessage(e)}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể hoàn tất đặt lịch: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
      if (message is List && message.isNotEmpty) {
        return message.map((item) => item.toString()).join(', ');
      }
    }
    return error.message ?? 'Không xác định được lỗi';
  }
}

class VaccinationFilterScreen extends StatefulWidget {
  const VaccinationFilterScreen({super.key});

  @override
  State<VaccinationFilterScreen> createState() => _VaccinationFilterScreenState();
}

class _VaccinationFilterScreenState extends State<VaccinationFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _service = 'Tất cả';
  String _city = 'Thành phố Cần Thơ';
  String _facility = 'Bệnh viện Phụ sản Thành Phố Cần Thơ';
  List<String> _serviceOptions = const ['Tất cả'];
  List<String> _cityOptions = const ['Tất cả'];
  List<String> _facilityOptions = const ['Tất cả'];

  @override
  void initState() {
    super.initState();
    VaccinationBookingCatalog.loadRemote().then((_) {
      final serviceOptions = <String>{
        'Tất cả',
        ...VaccinationBookingCatalog.packages
            .map((item) => item.badge.isNotEmpty ? item.badge : item.title)
            .where((value) => value.trim().isNotEmpty),
      }.toList();
      final cityOptions = <String>{
        'Tất cả',
        ...VaccinationBookingCatalog.facilities.map((facility) => _cityLabelFromAddress(facility.address)),
      }.toList();
      final facilityOptions = <String>{
        'Tất cả',
        ...VaccinationBookingCatalog.facilities.map((facility) => facility.name),
      }.toList();

      if (serviceOptions.isNotEmpty) _serviceOptions = serviceOptions;
      if (cityOptions.isNotEmpty) _cityOptions = cityOptions;
      if (facilityOptions.isNotEmpty) _facilityOptions = facilityOptions;

      if (!_cityOptions.contains(_city)) {
        _city = _cityOptions.length > 1 ? _cityOptions[1] : 'Tất cả';
      }
      if (!_facilityOptions.contains(_facility)) {
        _facility = _facilityOptions.length > 1 ? _facilityOptions[1] : 'Tất cả';
      }
      if (!_serviceOptions.contains(_service)) {
        _service = _serviceOptions.length > 1 ? _serviceOptions[1] : 'Tất cả';
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasBackendData = VaccinationBookingCatalog.facilities.isNotEmpty || VaccinationBookingCatalog.packages.isNotEmpty;
    return VaccinationPageScaffold(
      title: 'Chọn lọc theo',
      onBack: () => context.pop(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          VaccinationSearchBar(controller: _searchController),
          const SizedBox(height: 22),
          const SectionTitle('Loại dịch vụ'),
          const SizedBox(height: 10),
          SwitchChips(
            values: _serviceOptions,
            selected: _service,
            onSelect: (value) => setState(() => _service = value),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Tỉnh thành'),
          const SizedBox(height: 10),
          SwitchChips(
            values: _cityOptions,
            selected: _city,
            onSelect: (value) => setState(() => _city = value),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Cơ sở y tế'),
          const SizedBox(height: 10),
          SwitchChips(
            values: _facilityOptions,
            selected: _facility,
            onSelect: (value) => setState(() => _facility = value),
          ),
          if (hasBackendData) ...[
            const SizedBox(height: 22),
            Text(
              'Dữ liệu đang lấy từ backend thật',
              style: TextStyle(
                fontSize: 12,
                color: VaccinationBookingColors.subtext,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _cityLabelFromAddress(String address) {
    final lower = address.toLowerCase();
    if (lower.contains('cần thơ')) return 'Thành phố Cần Thơ';
    if (lower.contains('hà nội')) return 'Thành phố Hà Nội';
    if (lower.contains('hcm') || lower.contains('hồ chí minh') || lower.contains('sài gòn')) {
      return 'Thành phố Hồ Chí Minh';
    }
    return 'Khác';
  }
}
class _VaccinationPackageCard extends StatelessWidget {
  const _VaccinationPackageCard({
    required this.item,
    required this.facility,
    required this.onTap,
  });

  final VaccinationPackage item;
  final VaccinationFacility facility;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12084A69),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: VaccinationBookingColors.blue,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.facilityName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: VaccinationBookingColors.blue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            facility.address,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: VaccinationBookingColors.subtext,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: facility.logoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    item.badge,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: facility.logoColor,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.priceLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFA726),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.note,
                    style: const TextStyle(fontSize: 11, color: VaccinationBookingColors.subtext),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [VaccinationBookingColors.mint, VaccinationBookingColors.blue],
                ),
              ),
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Đặt lịch',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({
    required this.facility,
    required this.onTap,
  });

  final VaccinationFacility facility;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12084A69),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: facility.logoColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  facility.logoText,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: facility.logoColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facility.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: VaccinationBookingColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    facility.address,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: VaccinationBookingColors.subtext,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '(${facility.rating.toStringAsFixed(1)})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFFB648),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ...List.generate(
                        5,
                        (index) => const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFC531)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlinedSelectTile extends StatelessWidget {
  const _OutlinedSelectTile({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VaccinationBookingColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: VaccinationBookingColors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: VaccinationBookingColors.text,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 12, color: VaccinationBookingColors.subtext),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProfileCard extends StatelessWidget {
  const _EmptyProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const CircleAvatar(
        radius: 38,
        backgroundColor: Color(0xFFE5E8EE),
        child: Icon(Icons.description_outlined, size: 34, color: Color(0xFF8A98AA)),
      ),
    );
  }
}
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VaccinationBookingColors.line),
      ),
      child: Column(children: children),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.icon,
    required this.text,
    this.emphasize = false,
  });

  final IconData icon;
  final String text;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: VaccinationBookingColors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: emphasize ? Colors.black : VaccinationBookingColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.requiredField = false,
    this.validator,
    this.keyboardType,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final bool requiredField;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator ??
            (value) {
              if (!requiredField) return null;
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập đầy đủ thông tin';
              }
              return null;
            },
        decoration: InputDecoration(
          labelText: requiredField ? '$label *' : label,
          suffixIcon: suffix,
          labelStyle: const TextStyle(fontSize: 12, color: VaccinationBookingColors.subtext),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: VaccinationBookingColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: VaccinationBookingColors.blue),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE53935)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE53935)),
          ),
        ),
      ),
    );
  }
}

class _DropField extends StatelessWidget {
  const _DropField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.requiredField = false,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: values.contains(value) ? value : values.first,
        validator: (selected) {
          if (!requiredField) return null;
          if (selected == null || selected == values.first) {
            return 'Vui lòng chọn đầy đủ thông tin';
          }
          return null;
        },
        items: values
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        decoration: InputDecoration(
          labelText: requiredField ? '$label *' : label,
          labelStyle: const TextStyle(fontSize: 12, color: VaccinationBookingColors.subtext),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: VaccinationBookingColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: VaccinationBookingColors.blue),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE53935)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE53935)),
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: VaccinationBookingColors.text,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}







