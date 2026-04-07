
const { PrismaClient } = require('@prisma/client');
async function test() {
  const passwords = ['password', '', 'root', '123456', 'admin'];
  for (const p of passwords) {
    const url = 'mysql://root:' + p + '@localhost:3306/clinic_admin';
    const prisma = new PrismaClient({ datasources: { db: { url } } });
    try {
      await prisma.$connect();
      console.log('SUCCESS:', url);
      process.exit(0);
    } catch (e) {
      console.log('FAILED:', url);
    } finally {
      await prisma.$disconnect();
    }
  }
  console.log('ALL FAILED');
}
test();

