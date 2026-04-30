import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const rooms = await prisma.chatRoom.findMany({
    include: {
      messages: {
        orderBy: { timestamp: 'desc' },
        take: 1,
      },
    },
  });
  console.log(JSON.stringify(rooms, null, 2));
}

main().catch(console.error).finally(() => prisma.$disconnect());
