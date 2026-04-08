import '../../booking/screens/doctor_hub_models.dart';

class MedicalHistoryItem {
  const MedicalHistoryItem({
    required this.id,
    required this.title,
    required this.day,
    required this.monthYear,
    required this.doctorId,
    required this.specialty,
    required this.feeLabel,
    required this.primaryStatus,
    required this.secondaryStatus,
    required this.orderNumber,
    required this.queueNumber,
    required this.clinicFeeLabel,
    required this.totalAmountLabel,
    required this.symptomNote,
    required this.caseSummary,
    required this.fileName,
    required this.fileUrl,
  });

  final String id;
  final String title;
  final String day;
  final String monthYear;
  final String doctorId;
  final String specialty;
  final String feeLabel;
  final String primaryStatus;
  final String secondaryStatus;
  final String orderNumber;
  final String queueNumber;
  final String clinicFeeLabel;
  final String totalAmountLabel;
  final String symptomNote;
  final String caseSummary;
  final String fileName;
  final String fileUrl;
}

class MedicalHistoryCatalog {
  MedicalHistoryCatalog._();

  static const items = <MedicalHistoryItem>[
    MedicalHistoryItem(
      id: 'visit-01',
      title: 'Viêm ruột cấp tính',
      day: '03',
      monthYear: 'Tháng 5\n2025',
      doctorId: 'dr-pediatrician',
      specialty: 'Nha sĩ',
      feeLabel: '100.000đ',
      primaryStatus: 'NEW',
      secondaryStatus: 'Chuẩn bị khám',
      orderNumber: '11458523',
      queueNumber: '11458523',
      clinicFeeLabel: '100.000đ',
      totalAmountLabel: '102.000đ',
      symptomNote:
          'Nguyên nhân/Triệu chứng: Lại bị đau bụng nhưng đã kéo dài hơn, vừa đau vừa nôn, đau ở dưới bụng bên phải âm ỉ không dứt.',
      caseSummary:
          'Mô tả kết quả khám: Sau khi thăm khám tại CTUT Care+, bệnh nhân cho biết bị đau răng dai dẳng, đau nhói ở vùng dưới hàm bên phải, kèm theo triệu chứng ê buốt sau khi ăn. Bác sĩ chẩn đoán đây có thể là dấu hiệu của viêm nướu cấp tính hoặc vấn đề viêm răng miệng liên quan đến tai mũi họng.',
      fileName: 'CD_VNdu_cap_tinh.pdf',
      fileUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    ),
    MedicalHistoryItem(
      id: 'visit-02',
      title: 'Viêm khoang miệng',
      day: '22',
      monthYear: 'Tháng 3\n2025',
      doctorId: 'dr-mistry-brick',
      specialty: 'Nha sĩ',
      feeLabel: '100.000đ',
      primaryStatus: '100.000đ',
      secondaryStatus: 'Kết thúc',
      orderNumber: '11502008',
      queueNumber: '11502008',
      clinicFeeLabel: '100.000đ',
      totalAmountLabel: '100.000đ',
      symptomNote:
          'Nguyên nhân/Triệu chứng: Đau nhức khoang miệng, khó ăn nhai và có vết loét nhỏ tại niêm mạc.',
      caseSummary:
          'Mô tả kết quả khám: Bác sĩ vệ sinh, sát khuẩn vùng tổn thương và hướng dẫn chăm sóc tại nhà. Tình trạng đã ổn định sau điều trị.',
      fileName: 'ket_qua_kham_22_03.pdf',
      fileUrl: 'https://www.orimi.com/pdf-test.pdf',
    ),
  ];

  static MedicalHistoryItem? findById(String id) {
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  static DoctorProfile? doctorOf(String doctorId) {
    return DoctorCatalog.instance.findById(doctorId);
  }
}

