import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding data...');

  // Get first user
  const user = await prisma.user.findFirst();
  if (user) {
    const existingPatient = await prisma.patientProfile.findFirst({
      where: { userId: user.userId }
    });

    if (!existingPatient) {
      await prisma.patientProfile.create({
        data: {
          userId: user.userId,
          fullName: user.fullName,
          phone_number: user.phone || '0123456789',
          is_primary: 1,
        }
      });
      console.log('Created patient profile for user', user.userId);
    } else {
      console.log('Patient profile already exists');
    }
  }

  // Find facility
  const facilities = await prisma.facility.findMany();
  for (const facility of facilities) {
    const existingService = await prisma.service.findFirst({
      where: { facilityId: facility.facilityId }
    });

    if (!existingService) {
      await prisma.service.create({
        data: {
          facilityId: facility.facilityId,
          name: 'Khám Tổng Quát',
          description: 'Dịch vụ khám tổng quát định kỳ',
          price: 500000,
          duration_minutes: 30,
          isActive: 1
        }
      });
      console.log('Created service for facility', facility.facilityId);
    } else {
      console.log('Service already exists for facility', facility.facilityId);
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
