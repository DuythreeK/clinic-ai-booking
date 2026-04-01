import { Module } from '@nestjs/common';
import { PrismaModule } from '@/prisma/prisma.module';
import { DoctorReviewsController } from './doctor-reviews.controller';
import { DoctorReviewsService } from './doctor-reviews.service';

@Module({
  imports: [PrismaModule],
  controllers: [DoctorReviewsController],
  providers: [DoctorReviewsService],
})
export class DoctorReviewsModule {}
