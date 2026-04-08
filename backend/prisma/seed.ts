import { PrismaClient, UserRole, FacilityType } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function upsertUser(params: {
  email: string;
  fullName: string;
  phone: string;
  role: UserRole;
  password: string;
}) {
  const passwordHash = await bcrypt.hash(params.password, 10);
  return prisma.user.upsert({
    where: { email: params.email },
    update: {
      full_name: params.fullName,
      phone: params.phone,
      role: params.role,
      password_hash: passwordHash,
      status: 'active',
    },
    create: {
      email: params.email,
      full_name: params.fullName,
      phone: params.phone,
      role: params.role,
      password_hash: passwordHash,
      status: 'active',
    },
  });
}

async function ensurePrimaryPatientProfile(userId: bigint, fullName: string, phone: string) {
  const existing = await prisma.patientProfile.findFirst({
    where: {
      user_id: userId,
      is_primary: 1,
    },
  });

  if (existing) {
    return existing;
  }

  return prisma.patientProfile.create({
    data: {
      user_id: userId,
      full_name: fullName,
      phone_number: phone,
      is_primary: 1,
      gender: 'male',
    },
  });
}

async function ensureSlotsForDoctor(
  doctorId: bigint,
  facilityId: bigint,
  startHours: number[],
) {
  const today = new Date();
  const from = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const to = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 14);

  const existing = await prisma.slot.count({
    where: {
      doctor_id: doctorId,
      facility_id: facilityId,
      is_active: 1,
      status: 'AVAILABLE',
      slot_date: {
        gte: from,
        lte: to,
      },
    },
  });

  if (existing > 0) {
    return;
  }

  const rows: Array<{
    facility_id: bigint;
    doctor_id: bigint;
    slot_date: Date;
    start_time: Date;
    end_time: Date;
    duration_minutes: number;
    available_count: number;
    status: 'AVAILABLE';
    is_active: number;
  }> = [];

  for (let i = 1; i <= 7; i++) {
    const d = new Date(today.getFullYear(), today.getMonth(), today.getDate() + i);
    const dayStart = new Date(d.getFullYear(), d.getMonth(), d.getDate());

    for (const h of startHours) {
      const start = new Date(d.getFullYear(), d.getMonth(), d.getDate(), h, 0, 0);
      const end = new Date(d.getFullYear(), d.getMonth(), d.getDate(), h, 30, 0);

      rows.push({
        facility_id: facilityId,
        doctor_id: doctorId,
        slot_date: dayStart,
        start_time: start,
        end_time: end,
        duration_minutes: 30,
        available_count: 10,
        status: 'AVAILABLE',
        is_active: 1,
      });
    }
  }

  if (rows.length > 0) {
    await prisma.slot.createMany({ data: rows });
  }
}

async function main() {
  console.log('Seeding doctor-facility mappings...');

  const specialtyGeneral = await prisma.specialty.upsert({
    where: { name: 'Tong quat' },
    update: { description: 'Kham tong quat', is_active: 1 },
    create: { name: 'Tong quat', description: 'Kham tong quat', is_active: 1 },
  });

  const specialtyCardio = await prisma.specialty.upsert({
    where: { name: 'Tim mach' },
    update: { description: 'Chuyen khoa tim mach', is_active: 1 },
    create: { name: 'Tim mach', description: 'Chuyen khoa tim mach', is_active: 1 },
  });

  const specialtyDerm = await prisma.specialty.upsert({
    where: { name: 'Da lieu' },
    update: { description: 'Chuyen khoa da lieu', is_active: 1 },
    create: { name: 'Da lieu', description: 'Chuyen khoa da lieu', is_active: 1 },
  });

  let facilityA = await prisma.facility.findFirst({ where: { name: 'Co so Trung tam Quan 1' } });
  if (!facilityA) {
    facilityA = await prisma.facility.create({
      data: {
        name: 'Co so Trung tam Quan 1',
        facility_type: FacilityType.clinic,
        phone: '02811112222',
        email: 'q1@clinic.local',
        address_detail: '123 Le Loi, Quan 1, TP HCM',
        province: 'TP HCM',
        district: 'Quan 1',
        ward: 'Ben Nghe',
        opening_hours: '08:00-20:00',
        is_active: 1,
      },
    });
  }

  let facilityB = await prisma.facility.findFirst({ where: { name: 'Co so Phu Nhuan' } });
  if (!facilityB) {
    facilityB = await prisma.facility.create({
      data: {
        name: 'Co so Phu Nhuan',
        facility_type: FacilityType.hospital,
        phone: '02833334444',
        email: 'pn@clinic.local',
        address_detail: '45 Hoang Van Thu, Phu Nhuan, TP HCM',
        province: 'TP HCM',
        district: 'Phu Nhuan',
        ward: 'Phuong 9',
        opening_hours: '07:00-21:00',
        is_active: 1,
      },
    });
  }

  const doctorUserA = await upsertUser({
    email: 'doctor.nguyenvana@clinic.local',
    fullName: 'Nguyen Van A',
    phone: '0901111111',
    role: UserRole.doctor,
    password: '12345678',
  });

  const doctorUserB = await upsertUser({
    email: 'doctor.tranthib@clinic.local',
    fullName: 'Tran Thi B',
    phone: '0902222222',
    role: UserRole.doctor,
    password: '12345678',
  });

  const doctorUserC = await upsertUser({
    email: 'doctor.leduyc@clinic.local',
    fullName: 'Le Duy C',
    phone: '0903333333',
    role: UserRole.doctor,
    password: '12345678',
  });

  await prisma.doctor.upsert({
    where: { user_id: doctorUserA.user_id },
    update: {
      full_name: 'Bac si Nguyen Van A',
      specialty_id: specialtyGeneral.specialty_id,
      facility_id: facilityA.facility_id,
      title: 'Bac si Tong quat',
      bio: '10 nam kinh nghiem kham tong quat',
      experience_years: 10,
      consultation_fee: 200000,
      is_active: 1,
    },
    create: {
      user_id: doctorUserA.user_id,
      full_name: 'Bac si Nguyen Van A',
      specialty_id: specialtyGeneral.specialty_id,
      facility_id: facilityA.facility_id,
      title: 'Bac si Tong quat',
      bio: '10 nam kinh nghiem kham tong quat',
      experience_years: 10,
      consultation_fee: 200000,
      is_active: 1,
    },
  });

  await prisma.doctor.upsert({
    where: { user_id: doctorUserB.user_id },
    update: {
      full_name: 'Bac si Tran Thi B',
      specialty_id: specialtyCardio.specialty_id,
      facility_id: facilityA.facility_id,
      title: 'Bac si Tim mach',
      bio: '12 nam kinh nghiem tim mach',
      experience_years: 12,
      consultation_fee: 350000,
      is_active: 1,
    },
    create: {
      user_id: doctorUserB.user_id,
      full_name: 'Bac si Tran Thi B',
      specialty_id: specialtyCardio.specialty_id,
      facility_id: facilityA.facility_id,
      title: 'Bac si Tim mach',
      bio: '12 nam kinh nghiem tim mach',
      experience_years: 12,
      consultation_fee: 350000,
      is_active: 1,
    },
  });

  await prisma.doctor.upsert({
    where: { user_id: doctorUserC.user_id },
    update: {
      full_name: 'Bac si Le Duy C',
      specialty_id: specialtyDerm.specialty_id,
      facility_id: facilityB.facility_id,
      title: 'Bac si Da lieu',
      bio: '8 nam kinh nghiem da lieu',
      experience_years: 8,
      consultation_fee: 280000,
      is_active: 1,
    },
    create: {
      user_id: doctorUserC.user_id,
      full_name: 'Bac si Le Duy C',
      specialty_id: specialtyDerm.specialty_id,
      facility_id: facilityB.facility_id,
      title: 'Bac si Da lieu',
      bio: '8 nam kinh nghiem da lieu',
      experience_years: 8,
      consultation_fee: 280000,
      is_active: 1,
    },
  });

  const patientUser = await upsertUser({
    email: 'a@gmail.com',
    fullName: 'Nguyen Van Patient A',
    phone: '0909999999',
    role: UserRole.patient,
    password: '12345678',
  });
  await ensurePrimaryPatientProfile(patientUser.user_id, 'Nguyen Van Patient A', '0909999999');

  const [doctorA, doctorB, doctorC] = await Promise.all([
    prisma.doctor.findUnique({ where: { user_id: doctorUserA.user_id } }),
    prisma.doctor.findUnique({ where: { user_id: doctorUserB.user_id } }),
    prisma.doctor.findUnique({ where: { user_id: doctorUserC.user_id } }),
  ]);

  if (doctorA != null) {
    await ensureSlotsForDoctor(doctorA.doctor_id, facilityA.facility_id, [8, 9, 10]);
  }

  if (doctorB != null) {
    await ensureSlotsForDoctor(doctorB.doctor_id, facilityA.facility_id, [14, 15, 16]);
  }

  if (doctorC != null) {
    await ensureSlotsForDoctor(doctorC.doctor_id, facilityB.facility_id, [9, 10, 11]);
  }

  console.log('Seed complete. Doctors and slots are attached to facilities.');
}

main()
  .catch((e) => {
    console.error('Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
