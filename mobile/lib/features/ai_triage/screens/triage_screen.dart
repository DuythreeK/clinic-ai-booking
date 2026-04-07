import 'package:flutter/material.dart';

class TriageScreen extends StatefulWidget {
  const TriageScreen({Key? key}) : super(key: key);

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  final List<String> _selectedSymptoms = [];
  final List<String> _availableSymptoms = [
    'Sốt cao',
    'Ho',
    'Viêm họng',
    'Đau đầu',
    'Chóng mặt',
    'Buồn nôn',
    'Mệt mỏi',
    'Ớn lạnh',
    'Khó thở',
    'Đau bụng',
    'Tiêu chảy',
    'Táo bón',
  ];

  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lọc triệu chứng AI'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chọn các triệu chứng bạn đang gặp phải để AI giúp bạn xác định các bác sĩ phù hợp nhất.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Symptoms Selection
            const Text(
              'Các triệu chứng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSymptoms.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSymptoms.add(symptom);
                      } else {
                        _selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Additional Notes
            const Text(
              'Mô tả thêm (tuỳ chọn)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Mô tả chi tiết về các triệu chứng của bạn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedSymptoms.isEmpty
                    ? null
                    : () => _performTriage(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Lọc triệu chứng'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Hủy'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _performTriage() {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang phân tích triệu chứng...'),
          ],
        ),
      ),
    );

    // Simulate AI processing
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close loading dialog
      _showTriageResults();
    });
  }

  void _showTriageResults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết quả lọc triệu chứng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Các bác sĩ được đề xuất:'),
            const SizedBox(height: 12),
            _buildRecommendedDoctorTile(
              'Bác sĩ Nội khoa',
              'Chuyên khoa: Nội khoa',
              'Độ phù hợp: 95%',
            ),
            const SizedBox(height: 8),
            _buildRecommendedDoctorTile(
              'Bác sĩ Thần kinh',
              'Chuyên khoa: Thần kinh',
              'Độ phù hợp: 80%',
            ),
            const SizedBox(height: 16),
            const Text('Độ nghiêm trọng: Vừa phải'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to booking with recommended specialties
            },
            child: const Text('Đặt lịch'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedDoctorTile(
    String title,
    String subtitle1,
    String subtitle2,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(subtitle1, style: const TextStyle(fontSize: 12)),
          Text(subtitle2, style: const TextStyle(fontSize: 12, color: Colors.blue)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
