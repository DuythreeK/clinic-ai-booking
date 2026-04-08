import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const sharedPassword = await bcrypt.hash('Admin@123', 10);

  await (prisma.user as any).upsert({
    where: { email: 'admin@clinic.local' },
    update: {},
    create: {
      full_name: 'Quản trị viên',
      email: 'admin@clinic.local',
      phone: '0900000001',
      password_hash: sharedPassword,
      role: 'admin',
    },
  });

  console.log('✅ Admin account created: admin@clinic.local / Admin@123');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
