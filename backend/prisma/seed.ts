import { PrismaClient, UserRole, FacilityType } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const DOCTOR_AVATAR_A =
  'https://images.pexels.com/photos/6749778/pexels-photo-6749778.jpeg?auto=compress&cs=tinysrgb&w=400';
const DOCTOR_AVATAR_B =
  'https://images.pexels.com/photos/5214995/pexels-photo-5214995.jpeg?auto=compress&cs=tinysrgb&w=400';
const DOCTOR_AVATAR_C =
  'https://images.pexels.com/photos/5215017/pexels-photo-5215017.jpeg?auto=compress&cs=tinysrgb&w=400';
const DOCTOR_AVATAR_D =
  'https://images.pexels.com/photos/6129041/pexels-photo-6129041.jpeg?auto=compress&cs=tinysrgb&w=400';
const DOCTOR_AVATAR_E =
  'https://images.pexels.com/photos/7108348/pexels-photo-7108348.jpeg?auto=compress&cs=tinysrgb&w=400';
const DOCTOR_AVATAR_F =
  'https://images.pexels.com/photos/8460157/pexels-photo-8460157.jpeg?auto=compress&cs=tinysrgb&w=400';

async function upsertUser(params: {
  email: string;
  fullName: string;
  phone: string;
  role: UserRole;
  password: string;
  avatarUrl?: string;
}) {
  const passwordHash = await bcrypt.hash(params.password, 10);
  return prisma.user.upsert({
    where: { email: params.email },
    update: {
      full_name: params.fullName,
      phone: params.phone,
      role: params.role,
      password_hash: passwordHash,
      avatar_url: params.avatarUrl,
      status: 'active',
    },
    create: {
      email: params.email,
      full_name: params.fullName,
      phone: params.phone,
      role: params.role,
      password_hash: passwordHash,
      avatar_url: params.avatarUrl,
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
  timeBlocks: Array<[number, number]>,
) {
  const today = new Date();
  const from = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const to = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 14);

  await prisma.slot.deleteMany({
    where: {
      doctor_id: doctorId,
      facility_id: facilityId,
      appointment: null,
      slot_date: {
        gte: from,
        lte: to,
      },
    },
  });

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

    for (const [h, m] of timeBlocks) {
      const start = new Date(d.getFullYear(), d.getMonth(), d.getDate(), h, m, 0);
      const end = new Date(d.getFullYear(), d.getMonth(), d.getDate(), h, m + 30, 0);

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

async function ensureServiceForFacility(
  facilityId: bigint,
  name: string,
  price: number,
  durationMinutes: number,
) {
  const existing = await prisma.service.findFirst({
    where: {
      facility_id: facilityId,
      name,
    },
  });

  if (existing) {
    return existing;
  }

  return prisma.service.create({
    data: {
      facility_id: facilityId,
      name,
      price,
      duration_minutes: durationMinutes,
      is_active: 1,
    },
  });
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

  const specialtyPediatrics = await prisma.specialty.upsert({
    where: { name: 'Nhi khoa' },
    update: { description: 'Chuyen khoa nhi', is_active: 1 },
    create: { name: 'Nhi khoa', description: 'Chuyen khoa nhi', is_active: 1 },
  });

  const specialtyEnt = await prisma.specialty.upsert({
    where: { name: 'Tai mui hong' },
    update: { description: 'Chuyen khoa tai mui hong', is_active: 1 },
    create: {
      name: 'Tai mui hong',
      description: 'Chuyen khoa tai mui hong',
      is_active: 1,
    },
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

  let facilityC = await prisma.facility.findFirst({ where: { name: 'Co so Thu Duc' } });
  if (!facilityC) {
    facilityC = await prisma.facility.create({
      data: {
        name: 'Co so Thu Duc',
        facility_type: FacilityType.clinic,
        phone: '02855556666',
        email: 'thuduc@clinic.local',
        address_detail: '89 Vo Van Ngan, Thu Duc, TP HCM',
        province: 'TP HCM',
        district: 'Thu Duc',
        ward: 'Linh Chieu',
        opening_hours: '08:00-17:00',
        is_active: 1,
      },
    });
  }

  let facilityD = await prisma.facility.findFirst({ where: { name: 'Co so Binh Thanh' } });
  if (!facilityD) {
    facilityD = await prisma.facility.create({
      data: {
        name: 'Co so Binh Thanh',
        facility_type: FacilityType.hospital,
        phone: '02877778888',
        email: 'binhthanh@clinic.local',
        address_detail: '16 Dien Bien Phu, Binh Thanh, TP HCM',
        province: 'TP HCM',
        district: 'Binh Thanh',
        ward: 'Phuong 15',
        opening_hours: '08:00-17:00',
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
    avatarUrl: DOCTOR_AVATAR_A,
  });

  const doctorUserB = await upsertUser({
    email: 'doctor.tranthib@clinic.local',
    fullName: 'Tran Thi B',
    phone: '0902222222',
    role: UserRole.doctor,
    password: '12345678',
    avatarUrl: DOCTOR_AVATAR_B,
  });

  const doctorUserC = await upsertUser({
    email: 'doctor.leduyc@clinic.local',
    fullName: 'Le Duy C',
    phone: '0903333333',
    role: UserRole.doctor,
    password: '12345678',
    avatarUrl: DOCTOR_AVATAR_C,
  });

  const doctorUserD = await upsertUser({
    email: 'doctor.phamthid@clinic.local',
    fullName: 'Pham Thi D',
    phone: '0904444444',
    role: UserRole.doctor,
    password: '12345678',
    avatarUrl: DOCTOR_AVATAR_D,
  });

  const doctorUserE = await upsertUser({
    email: 'doctor.nguyenvane@clinic.local',
    fullName: 'Nguyen Van E',
    phone: '0905555555',
    role: UserRole.doctor,
    password: '12345678',
    avatarUrl: DOCTOR_AVATAR_E,
  });

  const doctorUserF = await upsertUser({
    email: 'doctor.tranthif@clinic.local',
    fullName: 'Tran Thi F',
    phone: '0906666666',
    role: UserRole.doctor,
    password: '12345678',
    avatarUrl: DOCTOR_AVATAR_F,
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
        avatar_url: DOCTOR_AVATAR_A,
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
        avatar_url: DOCTOR_AVATAR_A,
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
        avatar_url: DOCTOR_AVATAR_B,
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
        avatar_url: DOCTOR_AVATAR_B,
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
        avatar_url: DOCTOR_AVATAR_C,
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
        avatar_url: DOCTOR_AVATAR_C,
      consultation_fee: 280000,
      is_active: 1,
    },
  });

  await prisma.doctor.upsert({
    where: { user_id: doctorUserD.user_id },
    update: {
      full_name: 'Bac si Pham Thi D',
      specialty_id: specialtyPediatrics.specialty_id,
      facility_id: facilityC.facility_id,
      title: 'Bac si Nhi khoa',
      bio: '9 nam kinh nghiem nhi khoa',
      experience_years: 9,
        avatar_url: DOCTOR_AVATAR_D,
      consultation_fee: 260000,
      is_active: 1,
    },
    create: {
      user_id: doctorUserD.user_id,
      full_name: 'Bac si Pham Thi D',
      specialty_id: specialtyPediatrics.specialty_id,
      facility_id: facilityC.facility_id,
      title: 'Bac si Nhi khoa',
      bio: '9 nam kinh nghiem nhi khoa',
      experience_years: 9,
        avatar_url: DOCTOR_AVATAR_D,
      consultation_fee: 260000,
      is_active: 1,
    },
  });

  await prisma.doctor.upsert({
    where: { user_id: doctorUserE.user_id },
    update: {
      full_name: 'Bac si Nguyen Van E',
      specialty_id: specialtyEnt.specialty_id,
      facility_id: facilityD.facility_id,
      title: 'Bac si Tai Mui Hong',
      bio: '11 nam kinh nghiem tai mui hong',
      experience_years: 11,
        avatar_url: DOCTOR_AVATAR_E,
      consultation_fee: 300000,
      is_active: 1,
    },
    create: {
      user_id: doctorUserE.user_id,
      full_name: 'Bac si Nguyen Van E',
      specialty_id: specialtyEnt.specialty_id,
      facility_id: facilityD.facility_id,
      title: 'Bac si Tai Mui Hong',
      bio: '11 nam kinh nghiem tai mui hong',
      experience_years: 11,
        avatar_url: DOCTOR_AVATAR_E,
      consultation_fee: 300000,
      is_active: 1,
    },
  });

  await prisma.doctor.upsert({
    where: { user_id: doctorUserF.user_id },
    update: {
      full_name: 'Bac si Tran Thi F',
      specialty_id: specialtyGeneral.specialty_id,
      facility_id: facilityC.facility_id,
      title: 'Bac si Noi tong hop',
      bio: '7 nam kinh nghiem noi tong hop',
      experience_years: 7,
        avatar_url: DOCTOR_AVATAR_F,
      consultation_fee: 240000,
      is_active: 1,
    },
    create: {
      user_id: doctorUserF.user_id,
      full_name: 'Bac si Tran Thi F',
      specialty_id: specialtyGeneral.specialty_id,
      facility_id: facilityC.facility_id,
      title: 'Bac si Noi tong hop',
      bio: '7 nam kinh nghiem noi tong hop',
      experience_years: 7,
        avatar_url: DOCTOR_AVATAR_F,
      consultation_fee: 240000,
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

  const [doctorA, doctorB, doctorC, doctorD, doctorE, doctorF] = await Promise.all([
    prisma.doctor.findUnique({ where: { user_id: doctorUserA.user_id } }),
    prisma.doctor.findUnique({ where: { user_id: doctorUserB.user_id } }),
    prisma.doctor.findUnique({ where: { user_id: doctorUserC.user_id } }),
    prisma.doctor.findUnique({ where: { user_id: doctorUserD.user_id } }),
    prisma.doctor.findUnique({ where: { user_id: doctorUserE.user_id } }),
    prisma.doctor.findUnique({ where: { user_id: doctorUserF.user_id } }),
  ]);

  // Gio hanh chinh: 08:00-11:30 va 13:00-16:30
  const businessHourBlocks: Array<[number, number]> = [
    [8, 0], [8, 30], [9, 0], [9, 30], [10, 0], [10, 30], [11, 0],
    [13, 0], [13, 30], [14, 0], [14, 30], [15, 0], [15, 30], [16, 0],
  ];

  if (doctorA != null) {
    await ensureSlotsForDoctor(doctorA.doctor_id, facilityA.facility_id, businessHourBlocks);
  }

  if (doctorB != null) {
    await ensureSlotsForDoctor(doctorB.doctor_id, facilityA.facility_id, businessHourBlocks);
  }

  if (doctorC != null) {
    await ensureSlotsForDoctor(doctorC.doctor_id, facilityB.facility_id, businessHourBlocks);
  }

  if (doctorD != null) {
    await ensureSlotsForDoctor(doctorD.doctor_id, facilityC.facility_id, businessHourBlocks);
  }

  if (doctorE != null) {
    await ensureSlotsForDoctor(doctorE.doctor_id, facilityD.facility_id, businessHourBlocks);
  }

  if (doctorF != null) {
    await ensureSlotsForDoctor(doctorF.doctor_id, facilityC.facility_id, businessHourBlocks);
  }

  await ensureServiceForFacility(facilityA.facility_id, 'Kham tong quat', 200000, 30);
  await ensureServiceForFacility(facilityB.facility_id, 'Kham da lieu', 280000, 30);
  await ensureServiceForFacility(facilityC.facility_id, 'Kham nhi tong quat', 260000, 30);
  await ensureServiceForFacility(facilityD.facility_id, 'Kham tai mui hong', 300000, 30);

  const facilityCount = await prisma.facility.count({ where: { is_active: 1 } });
  const doctorCount = await prisma.doctor.count({ where: { is_active: 1 } });
  console.log(
    `Seed complete. Facilities: ${facilityCount}, Doctors: ${doctorCount}. Slots are in business hours.`,
  );
}

main()
  .catch((e) => {
    console.error('Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
