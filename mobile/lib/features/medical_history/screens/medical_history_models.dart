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
      title: 'Viem ruot cap tinh',
      day: '03',
      monthYear: 'Thang 5\n2025',
      doctorId: 'dr-pediatrician',
      specialty: 'Nha si',
      feeLabel: '100.000d',
      primaryStatus: 'NEW',
      secondaryStatus: 'Chuan bi kham',
      orderNumber: '11458523',
      queueNumber: '11458523',
      clinicFeeLabel: '100.000d',
      totalAmountLabel: '102.000d',
      symptomNote:
          'Nguyen nhan/Trieu chung: Lai bi dau bung nhung da dai hon, vua dau vua non, dau o duoi bung ben phai am i khong dut.',
      caseSummary:
          'Mo ta ket qua kham: Sau khi tham kham tai CTUT Care+, benh nhan cho biet bi dau rang dai dang, dau va nhon o vung duoi ham ben phai, kem theo trieu chung o mui chua sau khi an. Bac si cho doan day co the la dau hieu cua viem nui cap tinh hoac van de viem rang mieng lien quan den tai mui hong.',
      fileName: 'CD_VNdu_cap_tinh.pdf',
      fileUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    ),
    MedicalHistoryItem(
      id: 'visit-02',
      title: 'Viem khoang mieng',
      day: '22',
      monthYear: 'Thang 3\n2025',
      doctorId: 'dr-mistry-brick',
      specialty: 'Nha si',
      feeLabel: '100.000d',
      primaryStatus: '100.000d',
      secondaryStatus: 'Ket thuc',
      orderNumber: '11502008',
      queueNumber: '11502008',
      clinicFeeLabel: '100.000d',
      totalAmountLabel: '100.000d',
      symptomNote:
          'Nguyen nhan/Trieu chung: Dau nhuc khoang mieng, kho an nhai va co vet loet nho tai niem mac.',
      caseSummary:
          'Mo ta ket qua kham: Bac si ve sinh, sat khuan vung ton thuong va huong dan cham soc tai nha. Tinh trang da on dinh sau dieu tri.',
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

