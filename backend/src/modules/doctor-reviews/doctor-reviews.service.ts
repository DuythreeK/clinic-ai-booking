import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateDoctorReviewDto } from './dto/doctor-review.dto';
import { okResponse } from '@/common/utils/api-response';
import { toNumberId } from '@/common/utils/formatters';

@Injectable()
export class DoctorReviewsService {
  constructor(private prisma: PrismaService) {}

  private toBigIntId(id: string): bigint {
    return BigInt(id);
  }

  async createReview(userId: string, dto: CreateDoctorReviewDto) {
    const doctor = await this.prisma.doctor.findUnique({
      where: { doctor_id: this.toBigIntId(dto.doctorId) },
    });

    if (!doctor || doctor.is_active !== 1) {
      throw new NotFoundException('Doctor not found');
    }

    if (dto.appointmentId) {
      const appointment = await this.prisma.appointment.findUnique({
        where: { appointment_id: this.toBigIntId(dto.appointmentId) },
      });

      if (!appointment || appointment.user_id !== this.toBigIntId(userId)) {
        throw new NotFoundException('Appointment not found');
      }
    }

    const review = await this.prisma.doctorReview.create({
      data: {
        doctor_id: this.toBigIntId(dto.doctorId),
        user_id: this.toBigIntId(userId),
        appointment_id: dto.appointmentId
          ? this.toBigIntId(dto.appointmentId)
          : undefined,
        rating: dto.rating,
        comment: dto.comment,
      },
    });

    return okResponse('Create doctor review successfully', {
      id: toNumberId(review.review_id),
      doctorId: toNumberId(review.doctor_id),
      appointmentId: review.appointment_id ? toNumberId(review.appointment_id) : null,
      rating: review.rating,
      comment: review.comment,
      createdAt: review.created_at,
    });
  }
}
