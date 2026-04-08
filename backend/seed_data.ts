import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding data...');

  // Get first user
  const user = await prisma.user.findFirst();
  if (user) {
    const existingPatient = await prisma.patientProfile.findFirst({
      where: { user_id: user.user_id }
    });

    if (!existingPatient) {
      await prisma.patientProfile.create({
        data: {
          user_id: user.user_id,
          full_name: user.full_name,
          phone_number: user.phone || '0123456789',
          is_primary: 1,
        }
      });
      console.log('Created patient profile for user', user.user_id);
    } else {
      console.log('Patient profile already exists');
    }
  }

  // Find facility
  const facilities = await prisma.facility.findMany();
  for (const facility of facilities) {
    const existingService = await prisma.service.findFirst({
      where: { facility_id: facility.facility_id }
    });

    if (!existingService) {
      await prisma.service.create({
        data: {
          facility_id: facility.facility_id,
          name: 'Khám Tổng Quát',
          description: 'Dịch vụ khám tổng quát định kỳ',
          price: 500000,
          duration_minutes: 30,
          is_active: 1
        }
      });
      console.log('Created service for facility', facility.facility_id);
    } else {
      console.log('Service already exists for facility', facility.facility_id);
    }
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
