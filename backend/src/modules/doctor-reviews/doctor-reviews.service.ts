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

  async createReview(user_id: string, dto: CreateDoctorReviewDto) {
    const doctor = await this.prisma.doctor.findUnique({
      where: { doctor_id: this.toBigIntId(dto.doctor_id) },
    });

    if (!doctor || doctor.is_active !== 1) {
      throw new NotFoundException('Doctor not found');
    }

    if (dto.appointment_id) {
      const appointment = await this.prisma.appointment.findUnique({
        where: { appointment_id: this.toBigIntId(dto.appointment_id) },
      });

      if (!appointment || appointment.user_id !== this.toBigIntId(user_id)) {
        throw new NotFoundException('Appointment not found');
      }
    }

    const review = await this.prisma.doctorReview.create({
      data: {
        doctor_id: this.toBigIntId(dto.doctor_id),
        user_id: this.toBigIntId(user_id),
        appointment_id: dto.appointment_id
          ? this.toBigIntId(dto.appointment_id)
          : undefined,
        rating: dto.rating,
        comment: dto.comment,
      },
    });

    return okResponse('Create doctor review successfully', {
      id: toNumberId(review.review_id),
      doctor_id: toNumberId(review.doctor_id),
      appointment_id: review.appointment_id ? toNumberId(review.appointment_id) : null,
      rating: review.rating,
      comment: review.comment,
      created_at: review.created_at,
    });
  }
}
