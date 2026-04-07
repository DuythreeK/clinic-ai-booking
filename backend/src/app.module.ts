import { Module, ValidationPipe } from '@nestjs/common';
import { APP_PIPE } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { AppointmentsModule } from './modules/appointments/appointments.module';
import { AiModule } from './modules/ai/ai.module';
import { ClinicsModule } from './modules/clinics/clinics.module';
import { DoctorsModule } from './modules/doctors/doctors.module';
import { UsersModule } from './modules/users/users.module';
import { PatientsModule } from './modules/patients/patients.module';
import { ServicesModule } from './modules/services/services.module';
import { MedicalRecordsModule } from './modules/medical-records/medical-records.module';
import { DoctorReviewsModule } from './modules/doctor-reviews/doctor-reviews.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { SlotsModule } from './modules/slots/slots.module';
import { SpecialtiesModule } from './modules/specialties/specialties.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    PrismaModule,
    AuthModule,
    AppointmentsModule,
    AiModule,
    ClinicsModule,
    DoctorsModule,
    UsersModule,
    PatientsModule,
    ServicesModule,
    MedicalRecordsModule,
    DoctorReviewsModule,
    PaymentsModule,
    SlotsModule,
    SpecialtiesModule,
  ],
  controllers: [],
  providers: [
    {
      provide: APP_PIPE,
      useValue: new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    },
  ],
})
export class AppModule {}
