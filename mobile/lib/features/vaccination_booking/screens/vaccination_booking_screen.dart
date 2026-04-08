import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'vaccination_booking_models.dart';
import 'vaccination_booking_widgets.dart';

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
  late String _selectedDate;
  late String _selectedSlot;
  late String _selectedService;

  static const _dates = ['05/03\nThu 5', '06/03\nThu 6', '07/03\nThu 7'];
  static const _slotsMorning = ['07:00 - 08:00', '08:00 - 09:00', '09:00 - 10:00'];
  static const _slotsAfternoon = ['13:00 - 14:00', '14:00 - 15:00', '15:00 - 16:00'];

  @override
  void initState() {
    super.initState();
    _selectedDate = _dates.first;
    _selectedSlot = _slotsMorning.first;
    _selectedService = widget.draft.serviceName;
  }

  @override
  Widget build(BuildContext context) {
    final facility = VaccinationBookingCatalog.facilityById(widget.draft.facilityId);

    return VaccinationPageScaffold(
      title: 'Chọn thông tin khám',
      onBack: () => context.pop(),
      bottom: PrimaryActionBar(
        label: 'TIẾP TỤC',
        onTap: () {
          context.push(
            '/vaccination-booking/profile',
            extra: widget.draft.copyWith(
              facilityId: facility.id,
              facilityName: facility.name,
              facilityAddress: facility.address,
              serviceName: _selectedService,
              dateLabel: _selectedDate.replaceAll('\n', ' '),
              slotLabel: _selectedSlot,
            ),
          );
        },
      ),
      child: ListView(
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
            title: _selectedService,
            subtitle: widget.draft.servicePriceLabel,
          ),
          const SizedBox(height: 14),
          const SectionTitle('Ngày khám'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dates.map((item) {
              return ChoiceChipPill(
                label: item,
                selected: _selectedDate == item,
                onTap: () => setState(() => _selectedDate = item),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const SectionTitle('Buổi sáng'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _slotsMorning.map((item) {
              return ChoiceChipPill(
                label: item,
                selected: _selectedSlot == item,
                onTap: () => setState(() => _selectedSlot = item),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const SectionTitle('Buổi chiều'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _slotsAfternoon.map((item) {
              return ChoiceChipPill(
                label: item,
                selected: _selectedSlot == item,
                onTap: () => setState(() => _selectedSlot = item),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class VaccinationProfileScreen extends StatelessWidget {
  const VaccinationProfileScreen({
    super.key,
    required this.draft,
  });

  final VaccinationBookingDraft draft;

  @override
  Widget build(BuildContext context) {
    return VaccinationPageScaffold(
      title: 'Chọn hồ sơ',
      onBack: () => context.pop(),
      bottom: PrimaryActionBar(
        label: draft.profileLabel,
        onTap: () => context.push('/vaccination-booking/confirm', extra: draft),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: const [
          StepHeader(currentStep: 2),
          SizedBox(height: 34),
          _EmptyProfileCard(),
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
    _cityController = TextEditingController(text: widget.draft.city);
    _districtController = TextEditingController(text: widget.draft.district);
    _wardController = TextEditingController(text: widget.draft.ward);
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
        onTap: () {
          context.push(
            '/vaccination-booking/payment',
            extra: widget.draft.copyWith(
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
              patientName: _fullNameController.text.trim().isEmpty
                  ? widget.draft.patientName
                  : _fullNameController.text.trim(),
            ),
          );
        },
      ),
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
          _FormField(label: 'Số điện thoại', controller: _phoneController),
          _FormField(label: 'Họ và tên', controller: _fullNameController),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Ngày sinh',
                  controller: _birthController,
                  suffix: const Icon(Icons.calendar_month_outlined, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DropField(
                  label: 'Giới tính',
                  value: _gender,
                  values: const ['Nam', 'Nữ'],
                  onChanged: (value) => setState(() => _gender = value),
                ),
              ),
            ],
          ),
          _FormField(label: 'Mã định danh/CCCD', controller: _identityController),
          _FormField(label: 'Mã bảo hiểm y tế', controller: _insuranceController),
          _FormField(label: 'Email', controller: _emailController),
          _DropField(
            label: 'Nghề nghiệp',
            value: _occupationController.text.isEmpty ? 'Chọn nghề nghiệp' : _occupationController.text,
            values: const ['Chọn nghề nghiệp', 'Nhân viên văn phòng', 'Sinh viên'],
            onChanged: (value) => setState(() => _occupationController.text = value == 'Chọn nghề nghiệp' ? '' : value),
          ),
          _DropField(
            label: 'Quốc gia',
            value: _countryController.text.isEmpty ? 'Chọn quốc gia' : _countryController.text,
            values: const ['Chọn quốc gia', 'Việt Nam'],
            onChanged: (value) => setState(() => _countryController.text = value == 'Chọn quốc gia' ? '' : value),
          ),
          _DropField(
            label: 'Dân tộc',
            value: _ethnicityController.text.isEmpty ? 'Chọn dân tộc' : _ethnicityController.text,
            values: const ['Chọn dân tộc', 'Kinh', 'Hoa'],
            onChanged: (value) => setState(() => _ethnicityController.text = value == 'Chọn dân tộc' ? '' : value),
          ),
          _DropField(
            label: 'Tỉnh/Thành phố',
            value: _cityController.text.isEmpty ? 'Chọn Tỉnh/Thành phố' : _cityController.text,
            values: const ['Chọn Tỉnh/Thành phố', 'Cần Thơ', 'Hà Nội', 'TP.HCM'],
            onChanged: (value) => setState(() => _cityController.text = value == 'Chọn Tỉnh/Thành phố' ? '' : value),
          ),
          _DropField(
            label: 'Quận/Huyện',
            value: _districtController.text.isEmpty ? 'Chọn Quận/Huyện' : _districtController.text,
            values: const ['Chọn Quận/Huyện', 'Ninh Kiều', 'Hai Bà Trưng', 'Quận 1'],
            onChanged: (value) => setState(() => _districtController.text = value == 'Chọn Quận/Huyện' ? '' : value),
          ),
          _DropField(
            label: 'Phường/Xã',
            value: _wardController.text.isEmpty ? 'Chọn Phường/Xã' : _wardController.text,
            values: const ['Chọn Phường/Xã', 'Cái Khế', 'Phạm Đình Hổ', 'Bến Nghé'],
            onChanged: (value) => setState(() => _wardController.text = value == 'Chọn Phường/Xã' ? '' : value),
          ),
        ],
      ),
    );
  }
}

class VaccinationPaymentScreen extends StatelessWidget {
  const VaccinationPaymentScreen({
    super.key,
    required this.draft,
  });

  final VaccinationBookingDraft draft;

  @override
  Widget build(BuildContext context) {
    final facility = VaccinationBookingCatalog.facilityById(draft.facilityId);
    final paymentMethod = VaccinationBookingCatalog.paymentMethodById(draft.paymentMethodId);
    const extraFee = 11000;
    final total = draft.servicePriceValue + extraFee;
    final totalLabel = total.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return VaccinationPageScaffold(
      title: 'Chọn hồ sơ',
      onBack: () => context.pop(),
      bottom: PrimaryActionBar(
        label: 'THANH TOÁN',
        leadingText: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$totalLabel VND',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: VaccinationBookingColors.text,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '(Đã bao gồm thuế với phí)',
              style: TextStyle(fontSize: 12, color: VaccinationBookingColors.subtext),
            ),
          ],
        ),
        onTap: () => _showPaymentMethodDialog(context),
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
            subtitle: draft.patientName.isEmpty ? 'Nguyễn Văn A' : draft.patientName,
          ),
          const SizedBox(height: 14),
          _InfoPanel(
            children: [
              _SummaryLine(icon: Icons.medical_services_outlined, text: draft.specialty),
              _SummaryLine(icon: Icons.vaccines_outlined, text: draft.serviceName),
              _SummaryLine(icon: Icons.calendar_month_outlined, text: '${draft.dateLabel} (${draft.slotLabel})'),
              _SummaryLine(icon: Icons.payments_outlined, text: draft.servicePriceLabel, emphasize: true),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
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
            child: Column(
              children: [
                _PriceRow(label: 'Phi kham benh', value: draft.servicePriceLabel),
                const SizedBox(height: 10),
                const Divider(color: VaccinationBookingColors.line),
                const SizedBox(height: 10),
                const _PriceRow(label: 'Phi dat lich (Theo quy dinh)', value: '11.000 VND'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const SectionTitle('Chọn phương thức thanh toán'),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _showPaymentMethodDialog(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF9FCCFF)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: paymentMethod.color.withOpacity(0.14),
                    child: Icon(Icons.account_balance_wallet_rounded, color: paymentMethod.color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      paymentMethod.shortLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: VaccinationBookingColors.blue,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: VaccinationBookingColors.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentMethodDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chọn phương thức thanh toán',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: VaccinationBookingColors.text,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...VaccinationBookingCatalog.paymentMethods.map(
                  (method) => Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: VaccinationBookingColors.line),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: method.color.withOpacity(0.14),
                          child: Text(
                            method.shortLabel.substring(0, method.shortLabel.length > 4 ? 4 : method.shortLabel.length),
                            style: TextStyle(
                              color: method.color,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          method.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: VaccinationBookingColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            values: const ['Tất cả', 'Khám bệnh', 'Vaccine'],
            selected: _service,
            onSelect: (value) => setState(() => _service = value),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Tỉnh thành'),
          const SizedBox(height: 10),
          SwitchChips(
            values: const ['Thành phố Hà Nội', 'Thành phố Hồ Chí Minh', 'Thành phố Cần Thơ'],
            selected: _city,
            onSelect: (value) => setState(() => _city = value),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Cơ sở y tế'),
          const SizedBox(height: 10),
          SwitchChips(
            values: const [
              'Bệnh viện Phụ sản Quốc tế Sài Gòn',
              'Bệnh viện Phụ sản Thành Phố Cần Thơ',
            ],
            selected: _facility,
            onSelect: (value) => setState(() => _facility = value),
          ),
        ],
      ),
    );
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
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
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
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: values.contains(value) ? value : values.first,
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
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: VaccinationBookingColors.subtext),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: VaccinationBookingColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: VaccinationBookingColors.blue),
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
