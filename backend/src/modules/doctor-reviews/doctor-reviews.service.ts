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
      where: { doctorId: this.toBigIntId(dto.doctorId) },
    });

    if (!doctor || doctor.isActive !== 1) {
      throw new NotFoundException('Doctor not found');
    }

    if (dto.appointmentId) {
      const appointment = await this.prisma.appointment.findUnique({
        where: { appointmentId: this.toBigIntId(dto.appointmentId) },
      });

      if (!appointment || appointment.userId !== this.toBigIntId(userId)) {
        throw new NotFoundException('Appointment not found');
      }
    }

    const review = await this.prisma.doctorReview.create({
      data: {
        doctorId: this.toBigIntId(dto.doctorId),
        userId: this.toBigIntId(userId),
        appointmentId: dto.appointmentId
          ? this.toBigIntId(dto.appointmentId)
          : undefined,
        rating: dto.rating,
        comment: dto.comment,
      },
    });

    return okResponse('Create doctor review successfully', {
      id: toNumberId(review.review_id),
      doctorId: toNumberId(review.doctorId),
      appointmentId: review.appointmentId ? toNumberId(review.appointmentId) : null,
      rating: review.rating,
      comment: review.comment,
      createdAt: review.createdAt,
    });
  }
}
