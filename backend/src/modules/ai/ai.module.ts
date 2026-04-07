import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { AiService } from './ai.service';
import { AiController } from './ai.controller';
import { PrismaModule } from '@/prisma/prisma.module';

@Module({
  imports: [
    PrismaModule,
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'default-secret',
    }),
  ],
  controllers: [AiController],
  providers: [AiService],
  exports: [AiService],
})
export class AiModule {}
