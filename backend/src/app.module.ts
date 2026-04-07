import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config'; // Nhớ chạy: npm install @nestjs/config
import { PrismaModule } from './prisma/prisma.module';
import { ClinicsModule } from './modules/clinics/clinics.module';
import { SlotsModule } from './modules/slots/slots.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    ClinicsModule,
    SlotsModule,
  ],
})
export class AppModule {}