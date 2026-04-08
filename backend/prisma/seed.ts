import {
  AppointmentStatus,
  AppointmentType,
  FacilityType,
  Gender,
  PaymentMethod,
  PaymentStatus,
  PrismaClient,
  ScreeningStatus,
  SlotStatus,
  UserRole,
  UserStatus,
} from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();
const hash = bcrypt.hashSync('123456', 10);

const startOfDay = (date = new Date()) => {
  const value = new Date(date);
  value.setHours(0, 0, 0, 0);
  return value;
};

const atTime = (baseDate: Date, hours: number, minutes: number) => {
  const value = new Date(baseDate);
  value.setHours(hours, minutes, 0, 0);
  return value;
};

async function clearDatabase() {
  await prisma.aiTriageMessage.deleteMany();
  await prisma.aiTriageSession.deleteMany();
  await prisma.notification.deleteMany();
  await prisma.payment.deleteMany();
  await prisma.doctorReview.deleteMany();
  await prisma.vaccinationRegistration.deleteMany();
  await prisma.medicalRecord.deleteMany();
  await prisma.preVisitForm.deleteMany();
  await prisma.appointmentStatusLog.deleteMany();
  await prisma.appointment.deleteMany();
  await prisma.slot.deleteMany();
  await prisma.serviceVaccine.deleteMany();
  await prisma.service.deleteMany();
  await prisma.vaccine.deleteMany();
  await prisma.doctor.deleteMany();
  await prisma.patientProfile.deleteMany();
  await prisma.passwordResetToken.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.specialty.deleteMany();
  await prisma.facility.deleteMany();
  await prisma.user.deleteMany();
}

async function main() {
  await clearDatabase();

  const [dentistry, cardio, neuro, vaccination] = await Promise.all([
    prisma.specialty.create({ data: { name: 'Nha sĩ', description: 'Khám răng hàm mặt' } }),
    prisma.specialty.create({ data: { name: 'Tim mạch', description: 'Khám tim mạch' } }),
    prisma.specialty.create({ data: { name: 'Thần kinh', description: 'Khám thần kinh' } }),
    prisma.specialty.create({ data: { name: 'Tiêm chủng', description: 'Dịch vụ tiêm chủng' } }),
  ]);

  const facilities = {
    heartCare: await prisma.facility.create({
      data: {
        name: 'Phòng khám HeartCare Central',
        facility_type: FacilityType.clinic,
        phone: '0907000001',
        email: 'heartcare@clinic.local',
        address_detail: '65 Pasteur',
        province: 'TP.HCM',
        district: 'Quận 1',
        ward: 'Bến Nghé',
        opening_hours: '07:00-17:00',
        rating_avg: 4.8,
      },
    }),
    binhAn: await prisma.facility.create({
      data: {
        name: 'Phòng khám Nha khoa Bình An',
        facility_type: FacilityType.clinic,
        phone: '0907000002',
        email: 'binhan@clinic.local',
        address_detail: '44 Nguyễn Đình Chiểu',
        province: 'TP.HCM',
        district: 'Quận 1',
        ward: 'Đa Kao',
        opening_hours: '08:00-18:00',
        rating_avg: 4.7,
      },
    }),
    hoaBinh: await prisma.facility.create({
      data: {
        name: 'Bệnh viện Răng Hàm Mặt Trung Ương',
        facility_type: FacilityType.hospital,
        phone: '0907000003',
        email: 'ranghammat@clinic.local',
        address_detail: '201A Nguyễn Chí Thanh',
        province: 'TP.HCM',
        district: 'Quận 5',
        ward: 'Phường 12',
        opening_hours: '07:00-16:30',
        rating_avg: 4.6,
      },
    }),
    canTho: await prisma.facility.create({
      data: {
        name: 'Bệnh viện Phụ sản Thành Phố Cần Thơ',
        facility_type: FacilityType.hospital,
        phone: '0907000005',
        email: 'cantho-vaccine@clinic.local',
        address_detail: '106 Cách Mạng Tháng Tám',
        province: 'Cần Thơ',
        district: 'Ninh Kiều',
        ward: 'Cái Khế',
        opening_hours: '07:00-17:00',
        rating_avg: 4.8,
      },
    }),
  };

  const [admin, patient, doctor1, doctor2, doctor3, doctor4, doctor5] = await Promise.all([
    prisma.user.create({ data: { role: UserRole.admin, full_name: 'System Admin', email: 'admin@clinic.local', phone: '0907999000', password_hash: hash, status: UserStatus.active } }),
    prisma.user.create({ data: { role: UserRole.patient, full_name: 'Nguyễn Văn A', email: 'patient@clinic.local', phone: '0908111222', password_hash: hash, status: UserStatus.active } }),
    prisma.user.create({ data: { role: UserRole.doctor, full_name: 'Dr. Pediatrician', email: 'doctor1@clinic.local', phone: '0907001001', password_hash: hash, status: UserStatus.active } }),
    prisma.user.create({ data: { role: UserRole.doctor, full_name: 'Dr. Fillerup Grab', email: 'doctor2@clinic.local', phone: '0907001002', password_hash: hash, status: UserStatus.active } }),
    prisma.user.create({ data: { role: UserRole.doctor, full_name: 'Dr. Balestra', email: 'doctor3@clinic.local', phone: '0907001003', password_hash: hash, status: UserStatus.active } }),
    prisma.user.create({ data: { role: UserRole.doctor, full_name: 'Dr. Mistry Brick', email: 'doctor4@clinic.local', phone: '0907001004', password_hash: hash, status: UserStatus.active } }),
    prisma.user.create({ data: { role: UserRole.doctor, full_name: 'Dr. Vaccine Care', email: 'doctor5@clinic.local', phone: '0907001005', password_hash: hash, status: UserStatus.active } }),
  ]);

  const doctors = {
    pediatrician: await prisma.doctor.create({ data: { user_id: doctor1.user_id, full_name: doctor1.full_name, specialty_id: cardio.specialty_id, facility_id: facilities.heartCare.facility_id, title: 'Nội tim mạch can thiệp', bio: 'Bác sĩ chuyên điều trị bệnh tim mạch và tầm soát nguy cơ đột quỵ.', experience_years: 25, avatar_url: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=900&q=80', consultation_fee: 100000 } }),
    fillerup: await prisma.doctor.create({ data: { user_id: doctor2.user_id, full_name: doctor2.full_name, specialty_id: dentistry.specialty_id, facility_id: facilities.binhAn.facility_id, title: 'Chỉnh nha & phục hình răng', bio: 'Bác sĩ chuyên chỉnh nha thẩm mỹ và phục hình răng.', experience_years: 9, avatar_url: 'https://images.unsplash.com/photo-1614608682850-e0d6ed316d47?auto=format&fit=crop&w=900&q=80', consultation_fee: 120000 } }),
    balestra: await prisma.doctor.create({ data: { user_id: doctor3.user_id, full_name: doctor3.full_name, specialty_id: dentistry.specialty_id, facility_id: facilities.hoaBinh.facility_id, title: 'Nhổ răng khôn & implant', bio: 'Bác sĩ có thế mạnh về tiểu phẫu răng khôn và implant.', experience_years: 8, avatar_url: 'https://images.unsplash.com/photo-1527613426441-4da17471b66d?auto=format&fit=crop&w=900&q=80', consultation_fee: 150000 } }),
    mistry: await prisma.doctor.create({ data: { user_id: doctor4.user_id, full_name: doctor4.full_name, specialty_id: dentistry.specialty_id, facility_id: facilities.binhAn.facility_id, title: 'Điều trị tủy & nha khoa tổng quát', bio: 'Bác sĩ tổng quát phù hợp khám định kỳ và điều trị tủy răng.', experience_years: 11, avatar_url: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=900&q=80', consultation_fee: 90000 } }),
    vaccineCare: await prisma.doctor.create({ data: { user_id: doctor5.user_id, full_name: doctor5.full_name, specialty_id: vaccination.specialty_id, facility_id: facilities.canTho.facility_id, title: 'Tư vấn và sàng lọc tiêm chủng', bio: 'Bác sĩ phụ trách tư vấn, sàng lọc và theo dõi sau tiêm.', experience_years: 7, avatar_url: 'https://images.unsplash.com/photo-1612531386530-97286d97c2d2?auto=format&fit=crop&w=900&q=80', consultation_fee: 160000 } }),
  };

  const primaryProfile = await prisma.patientProfile.create({
    data: {
      user_id: patient.user_id,
      full_name: patient.full_name,
      phone_number: patient.phone,
      gender: Gender.male,
      date_of_birth: new Date('1994-02-12'),
      occupation: 'Nhân viên văn phòng',
      ethnicity: 'Kinh',
      nationality: 'Việt Nam',
      address_detail: 'Đường Nguyễn Trãi',
      province: 'Hà Nội',
      district: 'Hà Đông',
      ward: 'Mộ Lao',
      emergency_contact: '0902123456',
      relationship_to_user: 'Bản thân',
      is_primary: 1,
    },
  });

  const childProfile = await prisma.patientProfile.create({
    data: {
      user_id: patient.user_id,
      full_name: 'Nguyễn Minh An',
      phone_number: '0908333444',
      gender: Gender.female,
      date_of_birth: new Date('2018-06-10'),
      occupation: 'Học sinh',
      ethnicity: 'Kinh',
      nationality: 'Việt Nam',
      address_detail: 'Đường Nguyễn Trãi',
      province: 'Hà Nội',
      district: 'Hà Đông',
      ward: 'Mộ Lao',
      emergency_contact: patient.phone,
      relationship_to_user: 'Con',
      is_primary: 0,
    },
  });
  const [hepB, hpv, flu] = await Promise.all([
    prisma.vaccine.create({ data: { name: 'Viêm gan B', manufacturer: 'VNVC Pharma', country_of_origin: 'Việt Nam', dose_count: 3 } }),
    prisma.vaccine.create({ data: { name: 'HPV', manufacturer: 'Merck', country_of_origin: 'Mỹ', dose_count: 3 } }),
    prisma.vaccine.create({ data: { name: 'Cúm mùa', manufacturer: 'Sanofi', country_of_origin: 'Pháp', dose_count: 1 } }),
  ]);

  const services = {
    hepB: await prisma.service.create({ data: { facility_id: facilities.canTho.facility_id, name: 'Tiêm chủng Viêm gan siêu vi B người lớn', description: 'Thanh toán tại cơ sở', price: 0, duration_minutes: 30, vaccines: { create: [{ vaccine_id: hepB.vaccine_id, quantity: 1 }] } } }),
    tiemNgua: await prisma.service.create({ data: { facility_id: facilities.canTho.facility_id, name: 'Tiêm ngừa', description: 'Thanh toán tại BV', price: 160000, duration_minutes: 30, vaccines: { create: [{ vaccine_id: flu.vaccine_id, quantity: 1 }] } } }),
    hpv: await prisma.service.create({ data: { facility_id: facilities.canTho.facility_id, name: 'Gói Vaccine HPV (Gói 1)', description: 'Thanh toán tại cơ sở', price: 7300000, duration_minutes: 45, vaccines: { create: [{ vaccine_id: hpv.vaccine_id, quantity: 1 }] } } }),
  };

  const today = startOfDay();
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const slots = {
    old1: await prisma.slot.create({ data: { facility_id: doctors.pediatrician.facility_id, doctor_id: doctors.pediatrician.doctor_id, slot_date: yesterday, start_time: atTime(yesterday, 8, 0), end_time: atTime(yesterday, 8, 30), duration_minutes: 30, available_count: 0, status: SlotStatus.FULL } }),
    old2: await prisma.slot.create({ data: { facility_id: doctors.mistry.facility_id, doctor_id: doctors.mistry.doctor_id, slot_date: yesterday, start_time: atTime(yesterday, 9, 0), end_time: atTime(yesterday, 9, 30), duration_minutes: 30, available_count: 0, status: SlotStatus.FULL } }),
    today1: await prisma.slot.create({ data: { facility_id: doctors.fillerup.facility_id, doctor_id: doctors.fillerup.doctor_id, slot_date: today, start_time: atTime(today, 10, 0), end_time: atTime(today, 10, 30), duration_minutes: 30, available_count: 0, status: SlotStatus.FULL } }),
    today2: await prisma.slot.create({ data: { facility_id: doctors.balestra.facility_id, doctor_id: doctors.balestra.doctor_id, slot_date: today, start_time: atTime(today, 11, 0), end_time: atTime(today, 11, 30), duration_minutes: 30, available_count: 0, status: SlotStatus.FULL } }),
    today3: await prisma.slot.create({ data: { facility_id: doctors.pediatrician.facility_id, doctor_id: doctors.pediatrician.doctor_id, slot_date: today, start_time: atTime(today, 14, 0), end_time: atTime(today, 14, 30), duration_minutes: 30, available_count: 0, status: SlotStatus.FULL } }),
    next1: await prisma.slot.create({ data: { facility_id: doctors.pediatrician.facility_id, doctor_id: doctors.pediatrician.doctor_id, slot_date: tomorrow, start_time: atTime(tomorrow, 10, 0), end_time: atTime(tomorrow, 10, 30), duration_minutes: 30, available_count: 5, status: SlotStatus.AVAILABLE } }),
    next2: await prisma.slot.create({ data: { facility_id: doctors.vaccineCare.facility_id, doctor_id: doctors.vaccineCare.doctor_id, slot_date: tomorrow, start_time: atTime(tomorrow, 7, 0), end_time: atTime(tomorrow, 8, 0), duration_minutes: 60, available_count: 6, status: SlotStatus.AVAILABLE } }),
  };

  const completed1 = await prisma.appointment.create({
    data: {
      appointment_code: 'APT-DEMO-0001',
      user_id: patient.user_id,
      patient_id: primaryProfile.patient_id,
      facility_id: doctors.pediatrician.facility_id,
      doctor_id: doctors.pediatrician.doctor_id,
      slot_id: slots.old1.slot_id,
      appointment_type: AppointmentType.consultation,
      appointment_date: yesterday,
      appointment_time: atTime(yesterday, 8, 0),
      status: AppointmentStatus.completed,
      symptoms_note: 'Đau bụng âm ỉ, buồn nôn và mệt mỏi.',
      note: 'Tái khám nếu triệu chứng kéo dài.',
      total_amount: 102000,
    },
  });

  const completed2 = await prisma.appointment.create({
    data: {
      appointment_code: 'APT-DEMO-0002',
      user_id: patient.user_id,
      patient_id: primaryProfile.patient_id,
      facility_id: doctors.mistry.facility_id,
      doctor_id: doctors.mistry.doctor_id,
      slot_id: slots.old2.slot_id,
      appointment_type: AppointmentType.consultation,
      appointment_date: yesterday,
      appointment_time: atTime(yesterday, 9, 0),
      status: AppointmentStatus.completed,
      symptoms_note: 'Đau nhức khoang miệng, khó ăn nhai.',
      note: 'Theo dõi thêm sau 3 ngày.',
      total_amount: 100000,
    },
  });

  await prisma.appointment.createMany({
    data: [
      { appointment_code: 'APT-TODAY-0001', user_id: patient.user_id, patient_id: primaryProfile.patient_id, facility_id: doctors.fillerup.facility_id, doctor_id: doctors.fillerup.doctor_id, slot_id: slots.today1.slot_id, appointment_type: AppointmentType.consultation, appointment_date: today, appointment_time: atTime(today, 10, 0), status: AppointmentStatus.confirmed, total_amount: 120000 },
      { appointment_code: 'APT-TODAY-0002', user_id: patient.user_id, patient_id: primaryProfile.patient_id, facility_id: doctors.balestra.facility_id, doctor_id: doctors.balestra.doctor_id, slot_id: slots.today2.slot_id, appointment_type: AppointmentType.consultation, appointment_date: today, appointment_time: atTime(today, 11, 0), status: AppointmentStatus.confirmed, total_amount: 150000 },
      { appointment_code: 'APT-TODAY-0003', user_id: patient.user_id, patient_id: childProfile.patient_id, facility_id: doctors.pediatrician.facility_id, doctor_id: doctors.pediatrician.doctor_id, slot_id: slots.today3.slot_id, appointment_type: AppointmentType.consultation, appointment_date: today, appointment_time: atTime(today, 14, 0), status: AppointmentStatus.pending, total_amount: 130000 },
    ],
  });
  const vaccinationAppointment = await prisma.appointment.create({
    data: {
      appointment_code: 'APT-VAC-0001',
      user_id: patient.user_id,
      patient_id: childProfile.patient_id,
      facility_id: doctors.vaccineCare.facility_id,
      doctor_id: doctors.vaccineCare.doctor_id,
      slot_id: slots.next2.slot_id,
      service_id: services.tiemNgua.service_id,
      appointment_type: AppointmentType.vaccination,
      appointment_date: tomorrow,
      appointment_time: atTime(tomorrow, 7, 0),
      status: AppointmentStatus.pending,
      note: 'Tiêm ngừa định kỳ',
      total_amount: 160000,
    },
  });

  await prisma.payment.createMany({
    data: [
      { appointment_id: completed1.appointment_id, payment_method: PaymentMethod.cash, amount: 102000, transaction_code: 'PAY-DEMO-0001', status: PaymentStatus.success, paid_at: new Date(yesterday) },
      { appointment_id: completed2.appointment_id, payment_method: PaymentMethod.cash, amount: 100000, transaction_code: 'PAY-DEMO-0002', status: PaymentStatus.success, paid_at: new Date(yesterday) },
      { appointment_id: vaccinationAppointment.appointment_id, payment_method: PaymentMethod.bank_transfer, amount: 160000, transaction_code: 'PAY-DEMO-0003', status: PaymentStatus.pending },
    ],
  });

  await prisma.medicalRecord.create({
    data: {
      appointment_id: completed1.appointment_id,
      patient_id: primaryProfile.patient_id,
      doctor_id: doctors.pediatrician.doctor_id,
      symptoms: 'Đau bụng, buồn nôn, mệt mỏi kéo dài.',
      diagnosis: 'Viêm ruột cấp tính',
      treatment_plan: 'Theo dõi chế độ ăn uống, nghỉ ngơi và tái khám nếu đau tăng.',
      prescription: [{ name: 'Men tiêu hóa', dose: '2 viên/ngày' }],
      attachments: [{ fileName: 'CD_VNdu_cap_tinh.pdf', fileUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf' }],
    },
  });

  await prisma.medicalRecord.create({
    data: {
      appointment_id: completed2.appointment_id,
      patient_id: primaryProfile.patient_id,
      doctor_id: doctors.mistry.doctor_id,
      symptoms: 'Đau nhức khoang miệng, khó ăn nhai.',
      diagnosis: 'Viêm khoang miệng',
      treatment_plan: 'Sát khuẩn tại chỗ, vệ sinh miệng và tái khám nếu cần.',
      prescription: [{ name: 'Nước súc miệng', dose: '2 lần/ngày' }],
      attachments: [{ fileName: 'ket_qua_kham_22_03.pdf', fileUrl: 'https://www.orimi.com/pdf-test.pdf' }],
    },
  });

  await prisma.doctorReview.createMany({
    data: [
      { doctor_id: doctors.pediatrician.doctor_id, user_id: patient.user_id, appointment_id: completed1.appointment_id, rating: 5, comment: 'Bác sĩ tận tâm và tư vấn rất rõ ràng.' },
      { doctor_id: doctors.mistry.doctor_id, user_id: patient.user_id, appointment_id: completed2.appointment_id, rating: 4, comment: 'Khám cẩn thận, hướng dẫn dễ hiểu.' },
    ],
  });

  await prisma.vaccinationRegistration.create({
    data: {
      appointment_id: vaccinationAppointment.appointment_id,
      contact_phone: childProfile.phone_number ?? patient.phone,
      contact_email: patient.email,
      screening_status: ScreeningStatus.pending,
      allergy_history: 'Không',
      underlying_disease: 'Không',
      current_medications: 'Không',
      previous_vaccination_history: 'Đã tiêm các mũi cơ bản',
    },
  });

  console.log('Seed completed.');
  console.log(`Admin: ${admin.email} / 123456`);
  console.log(`Patient: ${patient.email} / 123456`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
