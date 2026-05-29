import 'package:flutter/material.dart';
/*
  MedicalHistoryScreen
  - Vai trò: danh sách các phiếu khám / lịch sử khám của người dùng
  - Gọi backend: `MedicalHistoryCatalog.loadRemote()` chịu trách nhiệm gọi endpoint lịch sử khám (ví dụ `/medical-records`)
  - Lưu ý: mở chi tiết phiếu khám bằng route `/medical-history/:id`
*/
import 'package:go_router/go_router.dart';

import '../../booking/screens/doctor_hub_models.dart';
import 'medical_history_models.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  Future<void> _loadData() async {
    await DoctorCatalog.instance.loadRemote();
    await MedicalHistoryCatalog.loadRemote();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting && MedicalHistoryCatalog.items.isEmpty;
        return Scaffold(
          backgroundColor: const Color(0xFFF5FBFF),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE9F8FF), Color(0xFFF9FEFF)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        _RoundHeaderButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Lịch sử phiếu khám',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF24354D),
                            ),
                          ),
                        ),
                        const SizedBox(width: 38),
                      ],
                    ),
                  ),
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                            itemCount: MedicalHistoryCatalog.items.length,
                            itemBuilder: (context, index) {
                              final item = MedicalHistoryCatalog.items[index];
                              final doctor = MedicalHistoryCatalog.doctorOf(item.doctorId);

                              return GestureDetector(
                                onTap: () => context.push('/medical-history/${item.id}'),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
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
                                        width: 56,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: index == 0
                                              ? const LinearGradient(
                                                  colors: [Color(0xFF2DC7C4), Color(0xFF1EB7C8)],
                                                )
                                              : const LinearGradient(
                                                  colors: [Color(0xFFB8C0CA), Color(0xFF9FAAB6)],
                                                ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              item.day,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.monthYear,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.title,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF24354C),
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.open_in_new_rounded,
                                                  size: 18,
                                                  color: Color(0xFFFFB648),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: doctor?.name ?? item.doctorName,
                                                    style: const TextStyle(
                                                      color: Color(0xFF2E5BFF),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: ' - ${item.specialty}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF7C90A8),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                _TinyPill(
                                                  label: item.primaryStatus,
                                                  color: index == 0
                                                      ? const Color(0xFF20C6C1)
                                                      : const Color(0xFFEAE8FF),
                                                  textColor: index == 0
                                                      ? Colors.white
                                                      : const Color(0xFF6D6FF6),
                                                ),
                                                const SizedBox(width: 8),
                                                _TinyPill(
                                                  label: item.feeLabel,
                                                  color: const Color(0xFFEAE8FF),
                                                  textColor: const Color(0xFF6D6FF6),
                                                ),
                                                const SizedBox(width: 8),
                                                _TinyPill(
                                                  label: item.secondaryStatus,
                                                  color: index == 0
                                                      ? const Color(0xFFE7FFF5)
                                                      : const Color(0xFFF2F4F8),
                                                  textColor: index == 0
                                                      ? const Color(0xFF28C76F)
                                                      : const Color(0xFF66778F),
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
                            },
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
}

class _RoundHeaderButton extends StatelessWidget {
  const _RoundHeaderButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF5C6E86)),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
