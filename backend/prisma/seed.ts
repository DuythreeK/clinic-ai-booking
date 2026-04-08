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

const createHourlySlots = async (
  prisma: PrismaClient,
  facilityId: bigint,
  doctorId: bigint,
  dates: Date[],
  morningCount = 6,
  afternoonCount = 4,
) => {
  const tasks = dates.flatMap((date) =>
    Array.from({ length: 10 }, (_, index) => 7 + index).map((hour) =>
      prisma.slot.create({
        data: {
          facility_id: facilityId,
          doctor_id: doctorId,
          slot_date: date,
          start_time: atTime(date, hour, 0),
          end_time: atTime(date, hour + 1, 0),
          duration_minutes: 60,
          available_count: hour < 12 ? morningCount : afternoonCount,
          status: SlotStatus.AVAILABLE,
        },
      }),
    ),
  );

  return Promise.all(tasks);
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

  const [general, cardio, dentistry, dermatology, pediatrics, vaccination] = await Promise.all([
    prisma.specialty.create({ data: { name: 'Tổng quát', description: 'Khám tổng quát' } }),
    prisma.specialty.create({ data: { name: 'Tim mạch', description: 'Khám tim mạch' } }),
    prisma.specialty.create({ data: { name: 'Nha sĩ', description: 'Khám răng hàm mặt' } }),
    prisma.specialty.create({ data: { name: 'Da liễu', description: 'Khám và điều trị da liễu' } }),
    prisma.specialty.create({ data: { name: 'Nhi khoa', description: 'Khám trẻ em và nhi khoa' } }),
    prisma.specialty.create({ data: { name: 'Tiêm chủng', description: 'Dịch vụ tiêm chủng' } }),
  ]);

  const facilities = {
    heartCare: await prisma.facility.create({ data: { name: 'Phòng khám HeartCare Central', facility_type: FacilityType.clinic, phone: '0907000001', email: 'heartcare@clinic.local', address_detail: '65 Pasteur', province: 'TP.HCM', district: 'Quận 1', ward: 'Bến Nghé', opening_hours: '07:00-17:00', rating_avg: 4.8 } }),
    nhaKhoaBinhAn: await prisma.facility.create({ data: { name: 'Phòng khám Nha khoa Bình An', facility_type: FacilityType.clinic, phone: '0907000002', email: 'binhan@clinic.local', address_detail: '44 Nguyễn Đình Chiểu', province: 'TP.HCM', district: 'Quận 1', ward: 'Đa Kao', opening_hours: '08:00-18:00', rating_avg: 4.7 } }),
    rangHamMat: await prisma.facility.create({ data: { name: 'Bệnh viện Răng Hàm Mặt Trung Ương', facility_type: FacilityType.hospital, phone: '0907000003', email: 'ranghammat@clinic.local', address_detail: '201A Nguyễn Chí Thanh', province: 'TP.HCM', district: 'Quận 5', ward: 'Phường 12', opening_hours: '07:00-16:30', rating_avg: 4.6 } }),
    daLieuSaiGon: await prisma.facility.create({ data: { name: 'Bệnh viện Phụ sản Quốc tế Sài Gòn', facility_type: FacilityType.hospital, phone: '0907000004', email: 'saigon@clinic.local', address_detail: '63 Bùi Viện', province: 'TP.HCM', district: 'Quận 1', ward: 'Phạm Ngũ Lão', opening_hours: '07:00-17:00', rating_avg: 4.7 } }),
    nhiHaNoi: await prisma.facility.create({ data: { name: 'Bệnh viện đa khoa Hà Nội', facility_type: FacilityType.hospital, phone: '0907000005', email: 'hanoi@clinic.local', address_detail: '29 Hàn Thuyên', province: 'Hà Nội', district: 'Hai Bà Trưng', ward: 'Phạm Đình Hổ', opening_hours: '07:00-17:00', rating_avg: 4.4 } }),
    tiemChungCanTho: await prisma.facility.create({ data: { name: 'Bệnh viện Phụ sản Thành Phố Cần Thơ', facility_type: FacilityType.hospital, phone: '0907000006', email: 'cantho-vaccine@clinic.local', address_detail: '106 Cách Mạng Tháng Tám', province: 'Cần Thơ', district: 'Ninh Kiều', ward: 'Cái Khế', opening_hours: '07:00-17:00', rating_avg: 4.8 } }),
  };

  const admin = await prisma.user.create({ data: { role: UserRole.admin, full_name: 'System Admin', email: 'admin@clinic.local', phone: '0907999000', password_hash: hash, status: UserStatus.active } });

  const patient = await prisma.user.create({ data: { role: UserRole.patient, full_name: 'Nguyễn Văn A', email: 'patient@clinic.local', phone: '0908111222', password_hash: hash, status: UserStatus.active } });

  const doctorUsers = await Promise.all([
    prisma.user.create({ data: { role: UserRole.doctor, full_name: 'BS. Minh Khang', email: 'doctor1@clinic.local', phone: '0907001001', password_hash: hash, status: UserStatus.active } }),
    prisma.user.create({ data: { role: UserRole.doctor, full_name: 'BS. Thảo Vy', email: 'doctor2@clinic.local', phone: '0907001002', password_hash: hash, status: UserStatus.active } }),
    prisma.user.create({ data: { role: UserRole.doctor, full_name: 'BS. Hải Đăng', email: 'doctor3@clinic.local', phone: '0907001003', password_hash: hash, status: UserStatus.active } }),
    prisma.user.create({ data: { role: UserRole.doctor, full_name: 'BS. Minh Nhật', email: 'doctor4@clinic.local', phone: '0907001004', password_hash: hash, status: UserStatus.active } }),
    prisma.user.create({ data: { role: UserRole.doctor, full_name: 'BS. Phương Anh', email: 'doctor5@clinic.local', phone: '0907001005', password_hash: hash, status: UserStatus.active } }),
    prisma.user.create({ data: { role: UserRole.doctor, full_name: 'BS. Minh Quân', email: 'doctor6@clinic.local', phone: '0907001006', password_hash: hash, status: UserStatus.active } }),
    prisma.user.create({ data: { role: UserRole.doctor, full_name: 'BS. Ngọc Lan', email: 'doctor7@clinic.local', phone: '0907001007', password_hash: hash, status: UserStatus.active } }),
    prisma.user.create({ data: { role: UserRole.doctor, full_name: 'BS. Đức Long', email: 'doctor8@clinic.local', phone: '0907001008', password_hash: hash, status: UserStatus.active } }),
  ]);

  const doctorRecords = {
    cardio: await prisma.doctor.create({ data: { user_id: doctorUsers[0].user_id, full_name: doctorUsers[0].full_name, specialty_id: cardio.specialty_id, facility_id: facilities.heartCare.facility_id, title: 'Nội tim mạch can thiệp', bio: 'Bác sĩ chuyên điều trị bệnh tim mạch và tầm soát nguy cơ đột quỵ.', experience_years: 25, avatar_url: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=900&q=80', consultation_fee: 100000 } }),
    dentistry: await prisma.doctor.create({ data: { user_id: doctorUsers[1].user_id, full_name: doctorUsers[1].full_name, specialty_id: dentistry.specialty_id, facility_id: facilities.nhaKhoaBinhAn.facility_id, title: 'Chỉnh nha & phục hình răng', bio: 'Bác sĩ chuyên chỉnh nha thẩm mỹ và phục hình răng.', experience_years: 9, avatar_url: 'https://images.unsplash.com/photo-1614608682850-e0d6ed316d47?auto=format&fit=crop&w=900&q=80', consultation_fee: 120000 } }),
    oralSurgery: await prisma.doctor.create({ data: { user_id: doctorUsers[2].user_id, full_name: doctorUsers[2].full_name, specialty_id: dentistry.specialty_id, facility_id: facilities.rangHamMat.facility_id, title: 'Nhổ răng khôn & implant', bio: 'Bác sĩ có thế mạnh về tiểu phẫu răng khôn và implant.', experience_years: 8, avatar_url: 'https://images.unsplash.com/photo-1527613426441-4da17471b66d?auto=format&fit=crop&w=900&q=80', consultation_fee: 150000 } }),
    dentalGeneral: await prisma.doctor.create({ data: { user_id: doctorUsers[3].user_id, full_name: doctorUsers[3].full_name, specialty_id: dentistry.specialty_id, facility_id: facilities.nhaKhoaBinhAn.facility_id, title: 'Điều trị tủy & nha khoa tổng quát', bio: 'Bác sĩ tổng quát phù hợp khám định kỳ và điều trị tủy răng.', experience_years: 11, avatar_url: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=900&q=80', consultation_fee: 90000 } }),
    neuro: await prisma.doctor.create({ data: { user_id: doctorUsers[4].user_id, full_name: doctorUsers[4].full_name, specialty_id: general.specialty_id, facility_id: facilities.nhiHaNoi.facility_id, title: 'Thần kinh cơ xương khớp', bio: 'Bác sĩ có kinh nghiệm với đau nửa đầu và rối loạn giấc ngủ.', experience_years: 13, avatar_url: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&w=900&q=80', consultation_fee: 130000 } }),
    vaccine: await prisma.doctor.create({ data: { user_id: doctorUsers[5].user_id, full_name: doctorUsers[5].full_name, specialty_id: vaccination.specialty_id, facility_id: facilities.tiemChungCanTho.facility_id, title: 'Tư vấn và sàng lọc tiêm chủng', bio: 'Bác sĩ phụ trách tư vấn, sàng lọc và theo dõi sau tiêm.', experience_years: 7, avatar_url: 'https://images.unsplash.com/photo-1612531386530-97286d97c2d2?auto=format&fit=crop&w=900&q=80', consultation_fee: 160000 } }),
    skin: await prisma.doctor.create({ data: { user_id: doctorUsers[6].user_id, full_name: doctorUsers[6].full_name, specialty_id: dermatology.specialty_id, facility_id: facilities.daLieuSaiGon.facility_id, title: 'Da liễu thẩm mỹ', bio: 'Bác sĩ chuyên điều trị mụn, viêm da và chăm sóc da thẩm mỹ.', experience_years: 10, avatar_url: 'https://images.unsplash.com/photo-1594824476967-48c8b9642734?auto=format&fit=crop&w=900&q=80', consultation_fee: 140000 } }),
    child: await prisma.doctor.create({ data: { user_id: doctorUsers[7].user_id, full_name: doctorUsers[7].full_name, specialty_id: pediatrics.specialty_id, facility_id: facilities.nhiHaNoi.facility_id, title: 'Nhi khoa tổng quát', bio: 'Bác sĩ theo dõi tăng trưởng, dinh dưỡng và bệnh thường gặp ở trẻ em.', experience_years: 12, avatar_url: 'https://images.unsplash.com/photo-1584515933487-779824d29309?auto=format&fit=crop&w=900&q=80', consultation_fee: 110000 } }),
  };

  const primaryProfile = await prisma.patientProfile.create({
    data: {
      user_id: patient.user_id,
      full_name: 'Nguyễn Văn A',
      phone_number: '0908111222',
      citizen_id: '001094000001',
      insurance_number: 'HYT-1994-0001',
      email: 'nguyenvana.patient@clinic.local',
      gender: Gender.male,
      date_of_birth: new Date('1994-02-12'),
      blood_type: 'O+',
      occupation: 'Nhân viên văn phòng',
      ethnicity: 'Kinh',
      nationality: 'Việt Nam',
      address_detail: 'Số 12, Đường Nguyễn Trãi',
      province: 'Hà Nội',
      district: 'Hà Đông',
      ward: 'Mộ Lao',
      medical_conditions: 'Không',
      allergies: 'Không',
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
      citizen_id: '075018000002',
      insurance_number: 'HYT-2018-0002',
      email: 'nguyenminhan.patient@clinic.local',
      gender: Gender.female,
      date_of_birth: new Date('2018-06-10'),
      blood_type: 'A+',
      occupation: 'Học sinh',
      ethnicity: 'Kinh',
      nationality: 'Việt Nam',
      address_detail: 'Số 12, Đường Nguyễn Trãi',
      province: 'Hà Nội',
      district: 'Hà Đông',
      ward: 'Mộ Lao',
      medical_conditions: 'Không',
      allergies: 'Dị ứng hải sản',
      emergency_contact: '0908111222',
      relationship_to_user: 'Con',
      is_primary: 0,
    },
  });
  const parentProfile = await prisma.patientProfile.create({
    data: {
      user_id: patient.user_id,
      full_name: 'Nguyễn Thị Mai',
      phone_number: '0908222333',
      citizen_id: '001090000003',
      insurance_number: 'HYT-1990-0003',
      email: 'nguyenthimai.patient@clinic.local',
      gender: Gender.female,
      date_of_birth: new Date('1990-08-21'),
      blood_type: 'B+',
      occupation: 'Giáo viên',
      ethnicity: 'Kinh',
      nationality: 'Việt Nam',
      address_detail: 'Số 12, Đường Nguyễn Trãi',
      province: 'Hà Nội',
      district: 'Hà Đông',
      ward: 'Mộ Lao',
      medical_conditions: 'Viêm dạ dày nhẹ',
      allergies: 'Không',
      emergency_contact: '0908111222',
      relationship_to_user: 'Vợ',
      is_primary: 0,
    },
  });

  const [hepB, hpv, flu] = await Promise.all([
    prisma.vaccine.create({ data: { name: 'Viêm gan B', manufacturer: 'VNVC Pharma', country_of_origin: 'Việt Nam', dose_count: 3 } }),
    prisma.vaccine.create({ data: { name: 'HPV', manufacturer: 'Merck', country_of_origin: 'Mỹ', dose_count: 3 } }),
    prisma.vaccine.create({ data: { name: 'Cúm mùa', manufacturer: 'Sanofi', country_of_origin: 'Pháp', dose_count: 1 } }),
  ]);

  const services = {
    hepB: await prisma.service.create({ data: { facility_id: facilities.nhiHaNoi.facility_id, name: 'Tiêm chủng Viêm gan siêu vi B người lớn', description: 'Thanh toán tại cơ sở', price: 150000, duration_minutes: 30, vaccines: { create: [{ vaccine_id: hepB.vaccine_id, quantity: 1 }] } } }),
    vaccination: await prisma.service.create({ data: { facility_id: facilities.tiemChungCanTho.facility_id, name: 'Tiêm ngừa cúm mùa', description: 'Thanh toán tại BV', price: 160000, duration_minutes: 30, vaccines: { create: [{ vaccine_id: flu.vaccine_id, quantity: 1 }] } } }),
    hpv: await prisma.service.create({ data: { facility_id: facilities.daLieuSaiGon.facility_id, name: 'Gói Vaccine HPV (Gói 1)', description: 'Thanh toán tại cơ sở', price: 7300000, duration_minutes: 45, vaccines: { create: [{ vaccine_id: hpv.vaccine_id, quantity: 1 }] } } }),
    skin: await prisma.service.create({ data: { facility_id: facilities.daLieuSaiGon.facility_id, name: 'Khám da liễu tổng quát', description: 'Thanh toán tại cơ sở', price: 140000, duration_minutes: 20 } }),
    child: await prisma.service.create({ data: { facility_id: facilities.nhiHaNoi.facility_id, name: 'Khám nhi tổng quát', description: 'Thanh toán tại cơ sở', price: 110000, duration_minutes: 20 } }),
  };

  const today = startOfDay();
  const yesterday = new Date(today); yesterday.setDate(yesterday.getDate() - 1);
  const twoDaysAgo = new Date(today); twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);
  const tomorrow = new Date(today); tomorrow.setDate(tomorrow.getDate() + 1);
  const dayAfterTomorrow = new Date(today); dayAfterTomorrow.setDate(dayAfterTomorrow.getDate() + 2);
  const threeDaysAfter = new Date(today); threeDaysAfter.setDate(threeDaysAfter.getDate() + 3);
  const fourDaysAfter = new Date(today); fourDaysAfter.setDate(fourDaysAfter.getDate() + 4);
  const fiveDaysAfter = new Date(today); fiveDaysAfter.setDate(fiveDaysAfter.getDate() + 5);

  const slots = {
    comp1: await prisma.slot.create({ data: { facility_id: doctorRecords.cardio.facility_id, doctor_id: doctorRecords.cardio.doctor_id, slot_date: twoDaysAgo, start_time: atTime(twoDaysAgo, 8, 0), end_time: atTime(twoDaysAgo, 8, 30), duration_minutes: 30, available_count: 0, status: SlotStatus.FULL } }),
    comp2: await prisma.slot.create({ data: { facility_id: doctorRecords.dentalGeneral.facility_id, doctor_id: doctorRecords.dentalGeneral.doctor_id, slot_date: yesterday, start_time: atTime(yesterday, 9, 0), end_time: atTime(yesterday, 9, 30), duration_minutes: 30, available_count: 0, status: SlotStatus.FULL } }),
    today1: await prisma.slot.create({ data: { facility_id: doctorRecords.dentistry.facility_id, doctor_id: doctorRecords.dentistry.doctor_id, slot_date: today, start_time: atTime(today, 10, 0), end_time: atTime(today, 10, 30), duration_minutes: 30, available_count: 0, status: SlotStatus.FULL } }),
    today2: await prisma.slot.create({ data: { facility_id: doctorRecords.oralSurgery.facility_id, doctor_id: doctorRecords.oralSurgery.doctor_id, slot_date: today, start_time: atTime(today, 11, 0), end_time: atTime(today, 11, 30), duration_minutes: 30, available_count: 0, status: SlotStatus.FULL } }),
    today3: await prisma.slot.create({ data: { facility_id: doctorRecords.neuro.facility_id, doctor_id: doctorRecords.neuro.doctor_id, slot_date: today, start_time: atTime(today, 14, 0), end_time: atTime(today, 14, 30), duration_minutes: 30, available_count: 0, status: SlotStatus.FULL } }),
    next1: await prisma.slot.create({ data: { facility_id: doctorRecords.cardio.facility_id, doctor_id: doctorRecords.cardio.doctor_id, slot_date: tomorrow, start_time: atTime(tomorrow, 10, 0), end_time: atTime(tomorrow, 10, 30), duration_minutes: 30, available_count: 5, status: SlotStatus.AVAILABLE } }),
    next2: await prisma.slot.create({ data: { facility_id: doctorRecords.vaccine.facility_id, doctor_id: doctorRecords.vaccine.doctor_id, slot_date: dayAfterTomorrow, start_time: atTime(dayAfterTomorrow, 7, 0), end_time: atTime(dayAfterTomorrow, 8, 0), duration_minutes: 60, available_count: 6, status: SlotStatus.AVAILABLE } }),
    next3: await prisma.slot.create({ data: { facility_id: doctorRecords.skin.facility_id, doctor_id: doctorRecords.skin.doctor_id, slot_date: dayAfterTomorrow, start_time: atTime(dayAfterTomorrow, 13, 0), end_time: atTime(dayAfterTomorrow, 13, 30), duration_minutes: 30, available_count: 4, status: SlotStatus.AVAILABLE } }),
    next4: await prisma.slot.create({ data: { facility_id: doctorRecords.child.facility_id, doctor_id: doctorRecords.child.doctor_id, slot_date: dayAfterTomorrow, start_time: atTime(dayAfterTomorrow, 15, 0), end_time: atTime(dayAfterTomorrow, 15, 30), duration_minutes: 30, available_count: 4, status: SlotStatus.AVAILABLE } }),
    vac1: await prisma.slot.create({ data: { facility_id: doctorRecords.vaccine.facility_id, doctor_id: doctorRecords.vaccine.doctor_id, slot_date: tomorrow, start_time: atTime(tomorrow, 8, 0), end_time: atTime(tomorrow, 8, 30), duration_minutes: 30, available_count: 6, status: SlotStatus.AVAILABLE } }),
    vac2: await prisma.slot.create({ data: { facility_id: doctorRecords.vaccine.facility_id, doctor_id: doctorRecords.vaccine.doctor_id, slot_date: tomorrow, start_time: atTime(tomorrow, 9, 0), end_time: atTime(tomorrow, 9, 30), duration_minutes: 30, available_count: 5, status: SlotStatus.AVAILABLE } }),
    vac3: await prisma.slot.create({ data: { facility_id: doctorRecords.vaccine.facility_id, doctor_id: doctorRecords.vaccine.doctor_id, slot_date: dayAfterTomorrow, start_time: atTime(dayAfterTomorrow, 7, 0), end_time: atTime(dayAfterTomorrow, 7, 30), duration_minutes: 30, available_count: 6, status: SlotStatus.AVAILABLE } }),
    vac4: await prisma.slot.create({ data: { facility_id: doctorRecords.vaccine.facility_id, doctor_id: doctorRecords.vaccine.doctor_id, slot_date: dayAfterTomorrow, start_time: atTime(dayAfterTomorrow, 10, 0), end_time: atTime(dayAfterTomorrow, 10, 30), duration_minutes: 30, available_count: 5, status: SlotStatus.AVAILABLE } }),
    vac5: await prisma.slot.create({ data: { facility_id: doctorRecords.vaccine.facility_id, doctor_id: doctorRecords.vaccine.doctor_id, slot_date: threeDaysAfter, start_time: atTime(threeDaysAfter, 8, 30), end_time: atTime(threeDaysAfter, 9, 0), duration_minutes: 30, available_count: 6, status: SlotStatus.AVAILABLE } }),
    vac6: await prisma.slot.create({ data: { facility_id: doctorRecords.vaccine.facility_id, doctor_id: doctorRecords.vaccine.doctor_id, slot_date: threeDaysAfter, start_time: atTime(threeDaysAfter, 13, 30), end_time: atTime(threeDaysAfter, 14, 0), duration_minutes: 30, available_count: 4, status: SlotStatus.AVAILABLE } }),
    vac7: await prisma.slot.create({ data: { facility_id: doctorRecords.vaccine.facility_id, doctor_id: doctorRecords.vaccine.doctor_id, slot_date: fourDaysAfter, start_time: atTime(fourDaysAfter, 7, 30), end_time: atTime(fourDaysAfter, 8, 0), duration_minutes: 30, available_count: 6, status: SlotStatus.AVAILABLE } }),
    vac8: await prisma.slot.create({ data: { facility_id: doctorRecords.vaccine.facility_id, doctor_id: doctorRecords.vaccine.doctor_id, slot_date: fourDaysAfter, start_time: atTime(fourDaysAfter, 15, 0), end_time: atTime(fourDaysAfter, 15, 30), duration_minutes: 30, available_count: 4, status: SlotStatus.AVAILABLE } }),
  };

  await Promise.all(
    [tomorrow, dayAfterTomorrow, threeDaysAfter, fourDaysAfter, fiveDaysAfter].flatMap((date, dateIndex) =>
      Array.from({ length: 10 }, (_, index) => 7 + index)
        .filter((hour) => !(dateIndex === 0 && hour === 7))
        .map((hour) =>
          prisma.slot.create({
            data: {
              facility_id: doctorRecords.vaccine.facility_id,
              doctor_id: doctorRecords.vaccine.doctor_id,
              slot_date: date,
              start_time: atTime(date, hour, 0),
              end_time: atTime(date, hour + 1, 0),
              duration_minutes: 60,
              available_count: hour < 12 ? 6 : 4,
              status: SlotStatus.AVAILABLE,
            },
          }),
        ),
    ),
  );

  await Promise.all([
    createHourlySlots(prisma, facilities.daLieuSaiGon.facility_id, doctorRecords.skin.doctor_id, [
      tomorrow,
      dayAfterTomorrow,
      threeDaysAfter,
      fourDaysAfter,
      fiveDaysAfter,
    ]),
    createHourlySlots(prisma, facilities.nhiHaNoi.facility_id, doctorRecords.neuro.doctor_id, [
      tomorrow,
      dayAfterTomorrow,
      threeDaysAfter,
      fourDaysAfter,
      fiveDaysAfter,
    ]),
  ]);

  const completed1 = await prisma.appointment.create({ data: { appointment_code: 'APT-DEMO-0001', user_id: patient.user_id, patient_id: primaryProfile.patient_id, facility_id: doctorRecords.cardio.facility_id, doctor_id: doctorRecords.cardio.doctor_id, slot_id: slots.comp1.slot_id, appointment_type: AppointmentType.consultation, appointment_date: twoDaysAgo, appointment_time: atTime(twoDaysAgo, 8, 0), status: AppointmentStatus.completed, symptoms_note: 'Đau bụng âm ỉ, buồn nôn và mệt mỏi.', note: 'Tái khám nếu triệu chứng kéo dài.', total_amount: 102000 } });
  const completed2 = await prisma.appointment.create({ data: { appointment_code: 'APT-DEMO-0002', user_id: patient.user_id, patient_id: primaryProfile.patient_id, facility_id: doctorRecords.dentalGeneral.facility_id, doctor_id: doctorRecords.dentalGeneral.doctor_id, slot_id: slots.comp2.slot_id, appointment_type: AppointmentType.consultation, appointment_date: yesterday, appointment_time: atTime(yesterday, 9, 0), status: AppointmentStatus.completed, symptoms_note: 'Đau nhức khoang miệng, khó ăn nhai.', note: 'Theo dõi thêm sau 3 ngày.', total_amount: 100000 } });

  await prisma.appointment.createMany({ data: [
    { appointment_code: 'APT-TODAY-0001', user_id: patient.user_id, patient_id: primaryProfile.patient_id, facility_id: doctorRecords.dentistry.facility_id, doctor_id: doctorRecords.dentistry.doctor_id, slot_id: slots.today1.slot_id, appointment_type: AppointmentType.consultation, appointment_date: today, appointment_time: atTime(today, 10, 0), status: AppointmentStatus.confirmed, total_amount: 120000 },
    { appointment_code: 'APT-TODAY-0002', user_id: patient.user_id, patient_id: primaryProfile.patient_id, facility_id: doctorRecords.oralSurgery.facility_id, doctor_id: doctorRecords.oralSurgery.doctor_id, slot_id: slots.today2.slot_id, appointment_type: AppointmentType.consultation, appointment_date: today, appointment_time: atTime(today, 11, 0), status: AppointmentStatus.confirmed, total_amount: 150000 },
    { appointment_code: 'APT-TODAY-0003', user_id: patient.user_id, patient_id: childProfile.patient_id, facility_id: doctorRecords.neuro.facility_id, doctor_id: doctorRecords.neuro.doctor_id, slot_id: slots.today3.slot_id, appointment_type: AppointmentType.consultation, appointment_date: today, appointment_time: atTime(today, 14, 0), status: AppointmentStatus.pending, total_amount: 130000 },
    { appointment_code: 'APT-TODAY-0004', user_id: patient.user_id, patient_id: parentProfile.patient_id, facility_id: doctorRecords.skin.facility_id, doctor_id: doctorRecords.skin.doctor_id, slot_id: slots.next3.slot_id, appointment_type: AppointmentType.consultation, appointment_date: dayAfterTomorrow, appointment_time: atTime(dayAfterTomorrow, 13, 0), status: AppointmentStatus.confirmed, total_amount: 140000 },
    { appointment_code: 'APT-TODAY-0005', user_id: patient.user_id, patient_id: childProfile.patient_id, facility_id: doctorRecords.child.facility_id, doctor_id: doctorRecords.child.doctor_id, slot_id: slots.next4.slot_id, appointment_type: AppointmentType.consultation, appointment_date: dayAfterTomorrow, appointment_time: atTime(dayAfterTomorrow, 15, 0), status: AppointmentStatus.confirmed, total_amount: 110000 },
  ] });

  const vaccinationAppointment = await prisma.appointment.create({ data: { appointment_code: 'APT-VAC-0001', user_id: patient.user_id, patient_id: childProfile.patient_id, facility_id: doctorRecords.vaccine.facility_id, doctor_id: doctorRecords.vaccine.doctor_id, slot_id: slots.next2.slot_id, service_id: services.vaccination.service_id, appointment_type: AppointmentType.vaccination, appointment_date: dayAfterTomorrow, appointment_time: atTime(dayAfterTomorrow, 7, 0), status: AppointmentStatus.pending, note: 'Tiêm ngừa cúm mùa định kỳ', total_amount: 160000 } });

  await prisma.payment.createMany({ data: [
    { appointment_id: completed1.appointment_id, payment_method: PaymentMethod.cash, amount: 102000, transaction_code: 'PAY-DEMO-0001', status: PaymentStatus.success, paid_at: new Date(twoDaysAgo) },
    { appointment_id: completed2.appointment_id, payment_method: PaymentMethod.cash, amount: 100000, transaction_code: 'PAY-DEMO-0002', status: PaymentStatus.success, paid_at: new Date(yesterday) },
    { appointment_id: vaccinationAppointment.appointment_id, payment_method: PaymentMethod.bank_transfer, amount: 160000, transaction_code: 'PAY-DEMO-0003', status: PaymentStatus.pending },
  ] });

  await prisma.medicalRecord.create({ data: { appointment_id: completed1.appointment_id, patient_id: primaryProfile.patient_id, doctor_id: doctorRecords.cardio.doctor_id, symptoms: 'Đau bụng, buồn nôn, mệt mỏi kéo dài.', diagnosis: 'Viêm ruột cấp tính', treatment_plan: 'Theo dõi chế độ ăn uống, nghỉ ngơi và tái khám nếu đau tăng.', prescription: [{ name: 'Men tiêu hóa', dose: '2 viên/ngày' }, { name: 'ORS', dose: 'Uống sau ăn' }], attachments: [{ fileName: 'CD_VNdu_cap_tinh.pdf', fileUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf' }] } });
  await prisma.medicalRecord.create({ data: { appointment_id: completed2.appointment_id, patient_id: primaryProfile.patient_id, doctor_id: doctorRecords.dentalGeneral.doctor_id, symptoms: 'Đau nhức khoang miệng, khó ăn nhai.', diagnosis: 'Viêm khoang miệng', treatment_plan: 'Sát khuẩn tại chỗ, vệ sinh miệng và tái khám nếu cần.', prescription: [{ name: 'Nước súc miệng', dose: '2 lần/ngày' }], attachments: [{ fileName: 'ket_qua_kham_22_03.pdf', fileUrl: 'https://www.orimi.com/pdf-test.pdf' }] } });

  await prisma.doctorReview.createMany({ data: [
    { doctor_id: doctorRecords.cardio.doctor_id, user_id: patient.user_id, appointment_id: completed1.appointment_id, rating: 5, comment: 'Bác sĩ tận tâm và tư vấn rất rõ ràng.' },
    { doctor_id: doctorRecords.dentalGeneral.doctor_id, user_id: patient.user_id, appointment_id: completed2.appointment_id, rating: 4, comment: 'Khám cẩn thận, hướng dẫn dễ hiểu.' },
    { doctor_id: doctorRecords.skin.doctor_id, user_id: patient.user_id, rating: 5, comment: 'Tư vấn da liễu rất kỹ và dễ hiểu.' },
    { doctor_id: doctorRecords.child.doctor_id, user_id: patient.user_id, rating: 4, comment: 'Bác sĩ thân thiện với trẻ nhỏ.' },
  ] });

  await prisma.vaccinationRegistration.create({ data: { appointment_id: vaccinationAppointment.appointment_id, contact_phone: childProfile.phone_number ?? patient.phone, contact_email: patient.email, screening_status: ScreeningStatus.pending, allergy_history: 'Không', underlying_disease: 'Không', current_medications: 'Không', previous_vaccination_history: 'Đã tiêm các mũi cơ bản' } });

  console.log('Seed completed.');
  console.log(`Admin: ${admin.email} / 123456`);
  console.log(`Patient: ${patient.email} / 123456`);
}

main().catch((error) => {
  console.error('Seed error:', error);
  process.exit(1);
}).finally(async () => {
  await prisma.$disconnect();
});
