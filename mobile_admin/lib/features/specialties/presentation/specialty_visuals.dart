import 'package:flutter/material.dart';

import '../domain/admin_specialty.dart';

class SpecialtyVisualOption {
  const SpecialtyVisualOption({
    required this.key,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final String key;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
}

class SpecialtyVisuals {
  static const options = [
    SpecialtyVisualOption(
      key: 'heart',
      icon: Icons.favorite_border_rounded,
      iconColor: Color(0xFFFF676D),
      backgroundColor: Color(0xFFFFEEF0),
    ),
    SpecialtyVisualOption(
      key: 'brain',
      icon: Icons.psychology_outlined,
      iconColor: Color(0xFF6D7EFF),
      backgroundColor: Color(0xFFEFF1FF),
    ),
    SpecialtyVisualOption(
      key: 'eye',
      icon: Icons.remove_red_eye_outlined,
      iconColor: Color(0xFF1CB98A),
      backgroundColor: Color(0xFFE9FBF4),
    ),
    SpecialtyVisualOption(
      key: 'internal',
      icon: Icons.medical_services_outlined,
      iconColor: Color(0xFFFFB647),
      backgroundColor: Color(0xFFFFF4DE),
    ),
    SpecialtyVisualOption(
      key: 'bone',
      icon: Icons.accessibility_new_rounded,
      iconColor: Color(0xFF4C8DFF),
      backgroundColor: Color(0xFFEAF2FF),
    ),
    SpecialtyVisualOption(
      key: 'child',
      icon: Icons.child_care_outlined,
      iconColor: Color(0xFF6A96FF),
      backgroundColor: Color(0xFFEFF4FF),
    ),
  ];

  static SpecialtyVisualOption fromSpecialty(AdminSpecialty specialty) {
    final source = '${specialty.code} ${specialty.name}'.toLowerCase();

    if (source.contains('tim')) {
      return options[0];
    }
    if (source.contains('thần kinh') || source.contains('than kinh')) {
      return options[1];
    }
    if (source.contains('mắt') || source.contains('mat')) {
      return options[2];
    }
    if (source.contains('xương') ||
        source.contains('xuong') ||
        source.contains('khớp') ||
        source.contains('khop')) {
      return options[4];
    }
    if (source.contains('nhi')) {
      return options[5];
    }

    return options[3];
  }
}
