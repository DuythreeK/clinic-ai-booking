import { AppointmentStatus, Gender, PrismaClient, UserRole, SlotStatus, AppointmentType } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding data...');

  const sharedPassword = await bcrypt.hash('Admin@123', 10);

  // 1. Specialty
  console.log('- Specialties');
  const spec = await prisma.specialty.upsert({
    where: { specialty_id: BigInt(1) },
    update: {},
    create: {
      specialty_id: BigInt(1),
      name: 'Nội Tổng Quát',
      description: 'Khám nội khoa',
      isActive: 1,
    },
  });

  // 2. Facility
  console.log('- Facility');
  const facility = await prisma.facility.upsert({
    where: { facility_id: BigInt(1) },
    update: {},
    create: {
      facility_id: BigInt(1),
      name: 'Phòng khám Đa khoa PKC',
      facility_type: 'clinic',
      address_detail: '123 Nguyễn Trãi',
      phone: '02431234567',
    },
  });

  // 3. Admin User
  console.log('- Admin');
  await prisma.user.upsert({
    where: { email: 'admin@clinic.local' },
    update: {},
    create: {
      full_name: 'Quản trị viên',
      email: 'admin@clinic.local',
      phone: '0900000001',
      password_hash: sharedPassword,
      role: UserRole.admin,
    },
  });

  // 4. Doctor
  console.log('- Doctor');
  const doctorUser = await prisma.user.upsert({
    where: { email: 'doctor@clinic.local' },
    update: {},
    create: {
      full_name: 'BS. Nguyễn Văn A',
      email: 'doctor@clinic.local',
      phone: '0988000000',
      password_hash: sharedPassword,
      role: UserRole.doctor,
    },
  });

  const doctor = await prisma.doctor.upsert({
    where: { user_id: doctorUser.user_id },
    update: {},
    create: {
      user_id: doctorUser.user_id,
      full_name: 'BS. Nguyễn Văn A',
      specialty_id: spec.specialty_id,
      facility_id: facility.facility_id,
      experience_years: 10,
      consultation_fee: 300000,
      license_number: 'CCHN-0001',
    },
  });

  // 5. Patient
  console.log('- Patient');
  const patientUser = await prisma.user.upsert({
    where: { email: 'patient@clinic.local' },
    update: {},
    create: {
      full_name: 'Bệnh nhân mẫu',
      email: 'patient@clinic.local',
      phone: '0911000000',
      password_hash: sharedPassword,
      role: UserRole.patient,
    },
  });

  const patient = await prisma.patientProfile.upsert({
    where: { user_id: patientUser.user_id },
    update: {},
    create: {
      user_id: patientUser.user_id,
      gender: Gender.male,
      date_of_birth: new Date('1990-01-01'),
      address: 'Hà Nội',
    },
  });

  // 6. Schedule
  console.log('- Schedule');
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(0,0,0,0);

  const schedule = await prisma.schedule.create({
    data: {
      doctor_id: doctor.doctor_id,
      workDate: tomorrow,
      startTime: new Date(tomorrow.getTime() + 8*60*60*1000),
      endTime: new Date(tomorrow.getTime() + 17*60*60*1000),
      maxSlots: 20,
    },
  });

  // 7. Slot
  console.log('- Slot');
  const slot = await prisma.slot.create({
    data: {
      doctor_id: doctor.doctor_id,
      facility_id: facility.facility_id,
      slot_date: tomorrow,
      start_time: new Date(tomorrow.getTime() + 9*60*60*1000),
      end_time: new Date(tomorrow.getTime() + 9*30*60*1000),
      status: SlotStatus.AVAILABLE,
    },
  });

  // 8. Appointment
  console.log('- Appointment');
  await prisma.appointment.create({
    data: {
      appointment_code: 'APT-1001',
      user_id: doctorUser.user_id, // booked by
      patient_id: patient.user_id,
      facility_id: facility.facility_id,
      doctor_id: doctor.doctor_id,
      slot_id: slot.slot_id,
      schedule_id: schedule.scheduleId,
      appointment_type: AppointmentType.consultation,
      appointment_date: tomorrow,
      appointment_time: new Date(tomorrow.getTime() + 9*60*60*1000),
      status: AppointmentStatus.pending,
      total_amount: 300000,
    },
  });

  console.log('✅ SEED SUCCESSFUL');
}

main()
  .catch((e) => {
    console.error('Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
