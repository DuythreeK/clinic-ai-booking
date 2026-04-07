import { Module, ValidationPipe } from '@nestjs/common';
import { APP_PIPE } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './admin/auth/auth.module';
import { UsersModule } from './admin/users/users.module';
import { SpecialtiesModule } from './admin/specialties/specialties.module';
import { DoctorsModule } from './admin/doctors/doctors.module';
import { RoomsModule } from './admin/rooms/rooms.module';
import { SchedulesModule } from './admin/schedules/schedules.module';
import { PatientsModule } from './admin/patients/patients.module';
import { AppointmentsModule } from './admin/appointments/appointments.module';
import { MedicalRecordsModule } from './admin/medical-records/medical-records.module';
import { ReviewsModule } from './admin/reviews/reviews.module';
import { NotificationsModule } from './admin/notifications/notifications.module';
import { SettingsModule } from './admin/settings/settings.module';
import { StatsModule } from './admin/stats/stats.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    SpecialtiesModule,
    DoctorsModule,
    RoomsModule,
    SchedulesModule,
    PatientsModule,
    AppointmentsModule,
    MedicalRecordsModule,
    ReviewsModule,
    NotificationsModule,
    SettingsModule,
    StatsModule,
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
