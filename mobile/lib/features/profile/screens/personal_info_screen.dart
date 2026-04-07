import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  static const _profile = _ProfileData(
    ecoreId: '1092302',
    username: 'nguyenvana',
    firstName: 'Nguyen',
    lastName: 'Van A',
    dateOfBirth: '12 - 02 - 1994',
    gender: 'Nam',
    phone: '08189213921',
    email: 'nguyenvana@gmail.com',
    city: 'Ha Noi',
    ward: 'Mo Lao',
    address: 'Duong Nguyen Trai, Mo Lao, Ha Noi',
    citizenId: '001194000123',
    occupation: 'Nhan vien van phong',
    emergencyContact: '0902123456',
  );

  @override
  Widget build(BuildContext context) {
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
                    _IconCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Thong tin ca nhan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF203248),
                        ),
                      ),
                    ),
                    _IconCircleButton(
                      icon: Icons.edit_outlined,
                      onTap: () => context.push('/profile/edit'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('Ho so'),
                      const SizedBox(height: 10),
                      _InfoCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const SizedBox(),
                                Expanded(child: _InfoCell(label: 'Ecore ID', value: _profile.ecoreId)),
                                const SizedBox(width: 18),
                                Expanded(child: _InfoCell(label: 'Ten nguoi dung', value: _profile.username)),
                              ]..removeAt(0),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(child: _InfoCell(label: 'Ten', value: _profile.firstName)),
                                const SizedBox(width: 18),
                                Expanded(child: _InfoCell(label: 'Ho', value: _profile.lastName)),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(child: _InfoCell(label: 'Ngay sinh', value: _profile.dateOfBirth)),
                                const SizedBox(width: 18),
                                Expanded(child: _InfoCell(label: 'Gioi tinh', value: _profile.gender)),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(child: _InfoCell(label: 'CCCD', value: _profile.citizenId)),
                                const SizedBox(width: 18),
                                Expanded(child: _InfoCell(label: 'Nghe nghiep', value: _profile.occupation)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel('Thong tin lien he'),
                      const SizedBox(height: 10),
                      _InfoCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _InfoCell(label: 'So dien thoai', value: _profile.phone)),
                                const SizedBox(width: 18),
                                Expanded(child: _InfoCell(label: 'Email', value: _profile.email)),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(child: _InfoCell(label: 'Tinh/Thanh pho', value: _profile.city)),
                                const SizedBox(width: 18),
                                Expanded(child: _InfoCell(label: 'Phuong', value: _profile.ward)),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _InfoCell(label: 'Dia chi cu the', value: _profile.address),
                            const SizedBox(height: 18),
                            _InfoCell(
                              label: 'Lien he khan cap',
                              value: _profile.emergencyContact,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel('Tien ich'),
                      const SizedBox(height: 10),
                      _QuickActionCard(
                        icon: Icons.receipt_long_rounded,
                        title: 'Lich su phieu kham',
                        subtitle: 'Xem lai cac lan kham, chi tiet phieu va danh gia',
                        onTap: () => context.push('/medical-history'),
                      ),
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
}

class EditPersonalInfoScreen extends StatefulWidget {
  const EditPersonalInfoScreen({super.key});

  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  final _ecoreIdController = TextEditingController(text: PersonalInfoScreen._profile.ecoreId);
  final _usernameController = TextEditingController(text: PersonalInfoScreen._profile.username);
  final _firstNameController = TextEditingController(text: PersonalInfoScreen._profile.firstName);
  final _lastNameController = TextEditingController(text: PersonalInfoScreen._profile.lastName);
  final _dateController = TextEditingController(text: PersonalInfoScreen._profile.dateOfBirth);
  final _phoneController = TextEditingController(text: '+628232877994');
  final _emailController = TextEditingController(text: PersonalInfoScreen._profile.email);
  final _cityController = TextEditingController(text: PersonalInfoScreen._profile.city);
  final _wardController = TextEditingController(text: PersonalInfoScreen._profile.ward);
  final _addressController = TextEditingController(text: PersonalInfoScreen._profile.address);
  final _citizenIdController = TextEditingController(text: PersonalInfoScreen._profile.citizenId);
  final _occupationController = TextEditingController(text: PersonalInfoScreen._profile.occupation);
  String _gender = 'Nam';

  @override
  void dispose() {
    _ecoreIdController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _wardController.dispose();
    _addressController.dispose();
    _citizenIdController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    _IconCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Chinh sua thong tin ca nhan',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('Ho so'),
                      const SizedBox(height: 10),
                      _EditCard(
                        children: [
                          _LineField(label: 'Ecore ID', controller: _ecoreIdController, enabled: false),
                          _LineField(label: 'Username', controller: _usernameController),
                          _LineField(label: 'Ten', controller: _firstNameController),
                          _LineField(label: 'Ho', controller: _lastNameController),
                          _DateField(label: 'Ngay sinh', controller: _dateController),
                          const SizedBox(height: 14),
                          const Text(
                            'Gioi tinh',
                            style: TextStyle(fontSize: 12, color: Color(0xFF95A3B8)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _GenderOption(
                                label: 'Nam',
                                value: 'Nam',
                                groupValue: _gender,
                                onChanged: (value) => setState(() => _gender = value),
                              ),
                              const SizedBox(width: 28),
                              _GenderOption(
                                label: 'Nu',
                                value: 'Nu',
                                groupValue: _gender,
                                onChanged: (value) => setState(() => _gender = value),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _LineField(label: 'CCCD', controller: _citizenIdController),
                          _LineField(label: 'Nghe nghiep', controller: _occupationController),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel('Thong tin lien he'),
                      const SizedBox(height: 10),
                      _EditCard(
                        children: [
                          _LineField(
                            label: 'Nhap so dien thoai',
                            controller: _phoneController,
                            prefix: const Icon(Icons.flag, size: 18, color: Color(0xFFF05A5A)),
                          ),
                          _LineField(
                            label: 'Nhap email',
                            controller: _emailController,
                            prefix: const Icon(Icons.mail_outline_rounded, size: 18, color: Color(0xFF8B9BB0)),
                          ),
                          _LineField(label: 'Tinh/Thanh pho', controller: _cityController),
                          _LineField(label: 'Phuong', controller: _wardController),
                          _LineField(label: 'Dia chi cu the', controller: _addressController, maxLines: 2),
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
                            onPressed: () => context.pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Luu thay doi',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
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
}

class _ProfileData {
  const _ProfileData({
    required this.ecoreId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.phone,
    required this.email,
    required this.city,
    required this.ward,
    required this.address,
    required this.citizenId,
    required this.occupation,
    required this.emergencyContact,
  });

  final String ecoreId;
  final String username;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String gender;
  final String phone;
  final String email;
  final String city;
  final String ward;
  final String address;
  final String citizenId;
  final String occupation;
  final String emergencyContact;
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({
    required this.icon,
    required this.onTap,
  });

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
              child: Icon(
                icon,
                color: const Color(0xFF20BEB7),
              ),
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
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF97A8BC),
            ),
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
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFFABB6C7)),
        ),
        const SizedBox(height: 6),
        Text(
          value,
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

class _LineField extends StatelessWidget {
  const _LineField({
    required this.label,
    required this.controller,
    this.prefix,
    this.enabled = true,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final Widget? prefix;
  final bool enabled;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefix,
          filled: false,
          isDense: true,
          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF99A8BB)),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE4EBF3)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF2BC6BE)),
          ),
          disabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE4EBF3)),
          ),
        ),
        style: TextStyle(
          fontSize: 15,
          fontWeight: enabled ? FontWeight.w700 : FontWeight.w500,
          color: enabled ? const Color(0xFF283A53) : const Color(0xFF7B8DA6),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          filled: false,
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF99A8BB)),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE4EBF3)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF2BC6BE)),
          ),
        ),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF283A53),
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB7C4D5)),
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF377DFF) : Colors.transparent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF304159),
            ),
          ),
        ],
      ),
    );
  }
}
