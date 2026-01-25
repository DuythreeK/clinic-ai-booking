import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // Clear existing data (be careful in production!)
  await prisma.appointment.deleteMany();
  await prisma.slot.deleteMany();
  await prisma.doctorClinic.deleteMany();
  await prisma.doctor.deleteMany();
  await prisma.patientProfile.deleteMany();
  await prisma.clinic.deleteMany();
  await prisma.specialty.deleteMany();
  await prisma.adminProfile.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.fcmToken.deleteMany();
  await prisma.user.deleteMany();

  console.log('📋 Creating specialties...');
  const specialties = await prisma.specialty.createMany({
    data: [
      { name: 'Tổng quát', description: 'Bác sĩ đa khoa' },
      { name: 'Tim mạch', description: 'Chuyên khoa Tim mạch' },
      { name: 'Da liễu', description: 'Chuyên khoa Da liễu' },
      { name: 'Tâm thần', description: 'Bác sĩ Tâm thần' },
      { name: 'Nhi khoa', description: 'Chuyên khoa Nhi khoa' },
    ],
  });
  console.log(`✅ Created ${specialties.count} specialties`);

  console.log('🏥 Creating clinics...');
  const clinics = await Promise.all([
    prisma.clinic.create({
      data: {
        name: 'Phòng khám Trung tâm',
        address: '123 Đường Lê Lợi',
        city: 'TP. Hồ Chí Minh',
        country: 'Vietnam',
        phone: '+84 28 1234 5678',
        email: 'contact@clinic-center.vn',
        hours: JSON.stringify({ mon_fri: '08:00-17:00', sat: '09:00-12:00' }),
      },
    }),
    prisma.clinic.create({
      data: {
        name: 'Bệnh viện Quốc tế',
        address: '456 Nguyễn Huệ',
        city: 'Hanoi',
        country: 'Vietnam',
        phone: '+84 24 6789 1234',
        email: 'info@intl-hospital.vn',
        hours: JSON.stringify({ mon_sun: '24/7' }),
      },
    }),
  ]);
  console.log(`✅ Created ${clinics.length} clinics`);

  console.log('👨‍⚕️ Creating admin user...');
  const adminUser = await prisma.user.create({
    data: {
      email: 'admin@clinic.local',
      password: await bcrypt.hash('admin123', 10),
      firstName: 'Admin',
      lastName: 'User',
      role: UserRole.ADMIN,
      admin: {
        create: {},
      },
    },
  });
  console.log(`✅ Admin user created (email: ${adminUser.email})`);

  console.log('👨‍⚕️ Creating sample doctors...');
  const doctor1 = await prisma.user.create({
    data: {
      email: 'doctor1@clinic.local',
      password: await bcrypt.hash('doctor123', 10),
      firstName: 'Nguyễn',
      lastName: 'Văn A',
      phone: '0901234567',
      role: UserRole.DOCTOR,
      doctor: {
        create: {
          licenseNumber: 'DL001',
          specialtyId: specialties.data[0].id, // Tổng quát
          isApproved: true,
          bio: 'Bác sĩ chuyên khoa Đa khoa có 10 năm kinh nghiệm',
          yearsExperience: 10,
          rating: 4.8,
          totalReviews: 150,
          doctorClinics: {
            create: [
              { clinicId: clinics[0].id },
              { clinicId: clinics[1].id },
            ],
          },
        },
      },
    },
  });

  const doctor2 = await prisma.user.create({
    data: {
      email: 'doctor2@clinic.local',
      password: await bcrypt.hash('doctor123', 10),
      firstName: 'Trần',
      lastName: 'Thị B',
      phone: '0912345678',
      role: UserRole.DOCTOR,
      doctor: {
        create: {
          licenseNumber: 'DL002',
          specialtyId: specialties.data[1].id, // Tim mạch
          isApproved: true,
          bio: 'Chuyên khoa Tim mạch với bằng cấp quốc tế',
          yearsExperience: 15,
          rating: 4.9,
          totalReviews: 200,
          doctorClinics: {
            create: [{ clinicId: clinics[0].id }],
          },
        },
      },
    },
  });
  console.log('✅ Created 2 sample doctors');

  console.log('👤 Creating sample patient...');
  const patientUser = await prisma.user.create({
    data: {
      email: 'patient@clinic.local',
      password: await bcrypt.hash('patient123', 10),
      firstName: 'Lê',
      lastName: 'Văn C',
      phone: '0923456789',
      role: UserRole.PATIENT,
      patient: {
        create: {
          gender: 'M',
          address: '789 Trần Hưng Đạo',
          city: 'TP. Hồ Chí Minh',
          country: 'Vietnam',
        },
      },
    },
  });
  console.log(`✅ Patient created (email: ${patientUser.email})`);

  console.log('📅 Creating sample slots...');
  const now = new Date();
  const tomorrow = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);

  await Promise.all([
    prisma.slot.create({
      data: {
        doctorId: doctor1.doctor!.id,
        clinicId: clinics[0].id,
        startAt: new Date(tomorrow.setHours(8, 0, 0, 0)),
        endAt: new Date(tomorrow.setHours(8, 30, 0, 0)),
      },
    }),
    prisma.slot.create({
      data: {
        doctorId: doctor1.doctor!.id,
        clinicId: clinics[0].id,
        startAt: new Date(tomorrow.setHours(9, 0, 0, 0)),
        endAt: new Date(tomorrow.setHours(9, 30, 0, 0)),
      },
    }),
    prisma.slot.create({
      data: {
        doctorId: doctor2.doctor!.id,
        clinicId: clinics[0].id,
        startAt: new Date(tomorrow.setHours(14, 0, 0, 0)),
        endAt: new Date(tomorrow.setHours(14, 30, 0, 0)),
      },
    }),
  ]);
  console.log('✅ Created sample slots');

  console.log('✨ Seeding completed!');
}

main()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
