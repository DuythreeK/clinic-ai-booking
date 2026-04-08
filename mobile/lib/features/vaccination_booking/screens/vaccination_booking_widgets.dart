import 'package:flutter/material.dart';

class VaccinationBookingColors {
  VaccinationBookingColors._();

  static const background = Color(0xFFF4FBFF);
  static const gradientTop = Color(0xFFDDF5FF);
  static const gradientBottom = Color(0xFFF9FDFF);
  static const mint = Color(0xFF20C8C2);
  static const blue = Color(0xFF359CFF);
  static const text = Color(0xFF24364E);
  static const subtext = Color(0xFF778BA4);
  static const line = Color(0xFFE4EDF5);
}

class VaccinationPageScaffold extends StatelessWidget {
  const VaccinationPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onBack,
    this.bottom,
  });

  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaccinationBookingColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              VaccinationBookingColors.gradientTop,
              VaccinationBookingColors.gradientBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    _TopIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: onBack,
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: VaccinationBookingColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 38),
                  ],
                ),
              ),
              Expanded(child: child),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}

class VaccinationSearchBar extends StatelessWidget {
  const VaccinationSearchBar({
    super.key,
    required this.controller,
    this.trailing,
    this.onChanged,
  });

  final TextEditingController controller;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11094A69),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Tim goi kham.....',
                hintStyle: const TextStyle(color: VaccinationBookingColors.subtext),
                prefixIcon: const Icon(Icons.search_rounded, color: VaccinationBookingColors.subtext),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          trailing!,
        ],
      ],
    );
  }
}

class FilterButton extends StatelessWidget {
  const FilterButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11094A69),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.tune_rounded,
          color: VaccinationBookingColors.text,
        ),
      ),
    );
  }
}

class SwitchChips extends StatelessWidget {
  const SwitchChips({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelect,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final active = value == selected;
        return InkWell(
          onTap: () => onSelect(value),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? VaccinationBookingColors.blue : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active ? VaccinationBookingColors.blue : VaccinationBookingColors.line,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : VaccinationBookingColors.text,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.currentStep,
  });

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.medical_services_outlined,
      Icons.person_rounded,
      Icons.verified_rounded,
      Icons.account_balance_wallet_rounded,
    ];

    return Row(
      children: List.generate(icons.length * 2 - 1, (index) {
        if (index.isOdd) {
          final active = index ~/ 2 < currentStep - 1;
          return Expanded(
            child: Container(
              height: 2,
              color: active ? VaccinationBookingColors.blue : Colors.black87,
            ),
          );
        }

        final step = index ~/ 2 + 1;
        final active = step <= currentStep;
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0x1320C8C2) : Colors.transparent,
          ),
          child: Icon(
            icons[step - 1],
            size: 18,
            color: active ? VaccinationBookingColors.blue : Colors.black87,
          ),
        );
      }),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.outlined = true,
  });

  final String title;
  final String subtitle;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: outlined ? Border.all(color: const Color(0xFF8DC2FF)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: VaccinationBookingColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: VaccinationBookingColors.subtext,
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryActionBar extends StatelessWidget {
  const PrimaryActionBar({
    super.key,
    required this.label,
    required this.onTap,
    this.leadingText,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? leadingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      color: Colors.white.withOpacity(0.88),
      child: Row(
        children: [
          if (leadingText != null) ...[
            Expanded(child: leadingText!),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [VaccinationBookingColors.mint, VaccinationBookingColors.blue],
                ),
              ),
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: VaccinationBookingColors.blue,
      ),
    );
  }
}

class ChoiceChipPill extends StatelessWidget {
  const ChoiceChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0x1220C8C2) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? VaccinationBookingColors.blue : VaccinationBookingColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? VaccinationBookingColors.blue : VaccinationBookingColors.text,
          ),
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 18, color: VaccinationBookingColors.text),
        ),
      ),
    );
  }
}

