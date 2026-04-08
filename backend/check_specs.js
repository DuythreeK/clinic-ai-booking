const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
  const specs = await prisma.specialty.findMany();
  console.log(JSON.stringify(specs, (key, value) => typeof value === 'bigint' ? value.toString() : value, 2));
}
main();
