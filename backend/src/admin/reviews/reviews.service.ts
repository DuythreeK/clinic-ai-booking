import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AppointmentStatus, Prisma } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { resolvePagination } from '../common/utils/pagination.util';
import { CreateReviewDto, ReviewListQueryDto, UpdateReviewDto } from './dto/review.dto';

const reviewInclude = {
  appointment: true,
  user: true,
  doctor: {
    include: {
      user: true,
      specialty: true,
    },
  },
} satisfies Prisma.DoctorReviewInclude;

@Injectable()
export class ReviewsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: ReviewListQueryDto) {
    const { skip, take, page, limit } = resolvePagination(query);
    const where: Prisma.DoctorReviewWhereInput = {
      doctor_id: query.doctorId ? BigInt(query.doctorId) : undefined,
      user_id: query.patientId ? BigInt(query.patientId) : undefined,
      is_visible: query.isVisible !== undefined ? (query.isVisible ? 1 : 0) : undefined,
      OR: query.search
        ? [
            { appointment: { is: { appointment_code: { contains: query.search } } } },
            { user: { is: { full_name: { contains: query.search } } } },
            { doctor: { is: { full_name: { contains: query.search } } } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.doctorReview.findMany({
        where,
        skip,
        take,
        include: reviewInclude,
        orderBy: { created_at: 'desc' },
      }),
      this.prisma.doctorReview.count({ where }),
    ]);

    return { data: items, meta: { page, limit, total } };
  }

  async findOne(id: string) {
    const review = await this.prisma.doctorReview.findUnique({
      where: { review_id: BigInt(id) },
      include: reviewInclude,
    });
    if (!review) {
      throw new NotFoundException('Khong tim thay danh gia');
    }

    return review;
  }

  async create(dto: CreateReviewDto) {
    return this.prisma.$transaction(async (tx) => {
      const appointment = await tx.appointment.findUnique({
        where: { appointment_id: BigInt(dto.appointmentId) },
      });

      if (!appointment) {
        throw new NotFoundException('Khong tim thay lich hen');
      }

      if (appointment.status !== AppointmentStatus.completed) {
        throw new BadRequestException('Chi duoc danh gia lich hen da hoan thanh');
      }

      const existing = await tx.doctorReview.findUnique({
        where: { appointment_id: BigInt(dto.appointmentId) },
      });
      if (existing) {
        throw new BadRequestException('Lich hen nay da co danh gia');
      }

      const review = await tx.doctorReview.create({
        data: {
          appointment_id: appointment.appointment_id,
          user_id: appointment.user_id,
          doctor_id: appointment.doctor_id!,
          rating: dto.rating,
          comment: dto.comment,
        },
      });

      return tx.doctorReview.findUniqueOrThrow({
        where: { review_id: review.review_id },
        include: reviewInclude,
      });
    });
  }

  async update(id: string, dto: UpdateReviewDto) {
    const review = await this.findOne(id);

    return this.prisma.doctorReview.update({
      where: { review_id: BigInt(id) },
      data: {
        admin_reply: dto.adminReply,
        admin_reply_at: dto.adminReply ? new Date() : undefined,
        is_visible: dto.isVisible !== undefined ? (dto.isVisible ? 1 : 0) : undefined,
      },
      include: reviewInclude,
    });
  }
}
