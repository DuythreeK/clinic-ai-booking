import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/services/auth_service.dart';
import '../services/ai_service.dart';

class _FunctionalSeverity {
  const _FunctionalSeverity({
    required this.level,
    required this.range,
    required this.description,
    required this.color,
  });

  final String level;
  final String range;
  final String description;
  final Color color;
}

class AiTriageScreen extends StatefulWidget {
  const AiTriageScreen({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<AiTriageScreen> createState() => _AiTriageScreenState();
}

class _AiTriageScreenState extends State<AiTriageScreen> {
  final TextEditingController _symptomsController = TextEditingController();
  AiTriageResult? _result;
  bool _isLoading = false;
  String? _error;
  _FunctionalSeverity _selectedSeverity = _severityOptions[1];

  String? _selectedBodyArea;
  String? _selectedDuration;

  final Set<String> _selectedSymptoms = <String>{};
  final Set<String> _selectedWarningSigns = <String>{};

  static const List<String> _quickSymptoms = [
    'Sốt',
    'Ho',
    'Đau họng',
    'Đau đầu',
    'Đau bụng',
    'Buồn nôn',
    'Đau ngực',
    'Khó thở',
    'Chóng mặt',
    'Đau khớp',
    'Mệt mỏi',
    'Phát ban',
  ];

  static const List<String> _warningSigns = [
    'Khó thở trầm trọng',
    'Đau ngực dữ dội',
    'Ngất xỉu',
    'Sốt cao > 39°C',
    'Nôn ra máu',
    'Mất nước nghiêm trọng',
  ];

  static const List<String> _bodyAreas = [
    'Đầu',
    'Tai Mũi Họng',
    'Ngực',
    'Bụng',
    'Lưng',
    'Da',
    'Tiết niệu',
    'Toàn thân',
  ];

  static const List<String> _durations = [
    'Hôm nay',
    '1-2 ngày',
    '3-7 ngày',
    '1-4 tuần',
    '> 1 tháng',
  ];

  static const List<_FunctionalSeverity> _severityOptions = [
    _FunctionalSeverity(
      level: 'Nhẹ',
      range: '1-3',
      description: 'Khó chịu nhẹ, vẫn sinh hoạt và làm việc bình thường.',
      color: Colors.green,
    ),
    _FunctionalSeverity(
      level: 'Vừa',
      range: '4-6',
      description: 'Đau khó chịu rõ rệt, bắt đầu ảnh hưởng đến sự tập trung.',
      color: Colors.amber,
    ),
    _FunctionalSeverity(
      level: 'Nặng',
      range: '7-8',
      description: 'Rất đau, mệt, không thể làm việc, cần nằm nghỉ hoàn toàn.',
      color: Colors.orange,
    ),
    _FunctionalSeverity(
      level: 'Khẩn cấp',
      range: '9-10',
      description: 'Đau dữ dội, không thể chịu đựng, cần hỗ trợ y tế ngay.',
      color: Colors.red,
    ),
  ];

  late final AiService _aiService =
      AiService(dioClient: widget.authService.dioClient);

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  void _toggleSelection(Set<String> bucket, String value) {
    setState(() {
      if (bucket.contains(value)) {
        bucket.remove(value);
      } else {
        bucket.add(value);
      }
    });
  }

  String _buildSymptomsPayload() {
    final notes = _symptomsController.text.trim();
    final sections = <String>[];

    if (_selectedSymptoms.isNotEmpty) {
      sections.add('Triệu chứng chính: ${_selectedSymptoms.join(', ')}');
    }

    if (_selectedBodyArea != null) {
      sections.add('Vị trí ảnh hưởng: $_selectedBodyArea');
    }

    sections.add(
      'Mức độ: ${_selectedSeverity.level} (${_selectedSeverity.description})',
    );

    if (_selectedDuration != null) {
      sections.add('Thời gian kéo dài: $_selectedDuration');
    }

    if (_selectedWarningSigns.isNotEmpty) {
      sections.add('Dấu hiệu cảnh báo: ${_selectedWarningSigns.join(', ')}');
    }

    if (notes.isNotEmpty) {
      sections.add('Chi tiết khác: $notes');
    }

    return sections.join('. ');
  }

  Future<void> _runTriage() async {
    final payload = _buildSymptomsPayload();
    final hasMeaningfulInput =
        _selectedSymptoms.isNotEmpty || _symptomsController.text.trim().length >= 5;

    if (!hasMeaningfulInput) {
      setState(() {
        _error = 'Vui lòng chọn ít nhất một triệu chứng hoặc nhập thêm chi tiết.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _aiService.triageSymptoms(payload);
      if (!mounted) return;

      setState(() {
        _result = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trợ lý Y tế AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Cung cấp các triệu chứng của bạn để AI phân tích và đưa ra tư vấn y tế nhanh chóng.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          const Text(
            '1) Chọn triệu chứng chính',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSymptoms
                .map(
                  (symptom) => FilterChip(
                    label: Text(symptom),
                    selected: _selectedSymptoms.contains(symptom),
                    onSelected: (_) => _toggleSelection(_selectedSymptoms, symptom),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            '2) Vị trí ảnh hưởng',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedBodyArea,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Chọn vị trí',
            ),
            items: _bodyAreas
                .map((area) => DropdownMenuItem<String>(value: area, child: Text(area)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedBodyArea = value;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text(
            '3) Mức độ đau/khó chịu',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _severityOptions
                .map(
                  (option) => ChoiceChip(
                    label: Text('${option.level} (${option.range})'),
                    selected: _selectedSeverity.level == option.level,
                    selectedColor: option.color.withOpacity(0.25),
                    side: BorderSide(color: option.color.withOpacity(0.7)),
                    labelStyle: TextStyle(
                      color: _selectedSeverity.level == option.level
                          ? option.color.withOpacity(0.95)
                          : null,
                      fontWeight: _selectedSeverity.level == option.level
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedSeverity = option;
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedSeverity.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _selectedSeverity.color.withOpacity(0.55)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flag, color: _selectedSeverity.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedSeverity.level} (${_selectedSeverity.range}): ${_selectedSeverity.description}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '4) Thời gian kéo dài',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _durations
                .map(
                  (duration) => ChoiceChip(
                    label: Text(duration),
                    selected: _selectedDuration == duration,
                    onSelected: (_) {
                      setState(() {
                        _selectedDuration = duration;
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            '5) Dấu hiệu cảnh báo nguy hiểm',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _warningSigns
                .map(
                  (sign) => FilterChip(
                    label: Text(sign),
                    selected: _selectedWarningSigns.contains(sign),
                    onSelected: (_) => _toggleSelection(_selectedWarningSigns, sign),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _symptomsController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Chi tiết bổ sung',
              hintText: 'Ví dụ: Sốt cao về đêm, nuốt đau, không bị dị ứng...',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isLoading ? null : _runTriage,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isLoading ? 'Đang phân tích...' : 'Phân tích chẩn đoán'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mức độ khẩn cấp: ${_result!.urgency}'),
                    const SizedBox(height: 6),
                    Text('Chuyên khoa đề xuất: ${_result!.specialty}'),
                    const SizedBox(height: 8),
                    Text(_result!.reasoning),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                final specialty = Uri.encodeQueryComponent(_result!.specialty);
                context.go('/?tab=0&specialty=$specialty');
              },
              child: const Text('Tìm Bác sĩ ngay'),
            ),
          ],
        ],
      ),
    );
  }
}

