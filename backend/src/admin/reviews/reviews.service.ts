import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ApptStatus, Prisma } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { resolvePagination } from '../common/utils/pagination.util';
import { CreateReviewDto, ReviewListQueryDto, UpdateReviewDto } from './dto/review.dto';

const reviewInclude = {
  appointment: true,
  patient: true,
  doctor: {
    include: {
      user: true,
      specialty: true,
    },
  },
} satisfies Prisma.ReviewInclude;

@Injectable()
export class ReviewsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: ReviewListQueryDto) {
    const { skip, take, page, limit } = resolvePagination(query);
    const where: Prisma.ReviewWhereInput = {
      doctorId: query.doctorId,
      patientId: query.patientId,
      isVisible: query.isVisible,
      OR: query.search
        ? [
            { appointment: { is: { refCode: { contains: query.search } } } },
            { patient: { is: { fullName: { contains: query.search } } } },
            { doctor: { is: { user: { is: { fullName: { contains: query.search } } } } } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.review.findMany({
        where,
        skip,
        take,
        include: reviewInclude,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.review.count({ where }),
    ]);

    return { data: items, meta: { page, limit, total } };
  }

  async findOne(id: string) {
    const review = await this.prisma.review.findUnique({
      where: { id },
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
        where: { id: dto.appointmentId },
      });

      if (!appointment) {
        throw new NotFoundException('Khong tim thay lich hen');
      }

      if (appointment.status !== ApptStatus.completed) {
        throw new BadRequestException('Chi duoc danh gia lich hen da hoan thanh');
      }

      const existing = await tx.review.findUnique({
        where: { appointmentId: dto.appointmentId },
      });
      if (existing) {
        throw new BadRequestException('Lich hen nay da co danh gia');
      }

      const review = await tx.review.create({
        data: {
          appointmentId: appointment.id,
          patientId: appointment.patientId,
          doctorId: appointment.doctorId,
          rating: dto.rating,
          comment: dto.comment,
        },
      });

      await this.refreshDoctorRating(tx, appointment.doctorId);

      return tx.review.findUniqueOrThrow({
        where: { id: review.id },
        include: reviewInclude,
      });
    });
  }

  async update(id: string, dto: UpdateReviewDto) {
    const review = await this.findOne(id);

    const updated = await this.prisma.$transaction(async (tx) => {
      const next = await tx.review.update({
        where: { id },
        data: {
          adminReply: dto.adminReply,
          isVisible: dto.isVisible,
        },
        include: reviewInclude,
      });

      if (dto.isVisible !== undefined && dto.isVisible !== review.isVisible) {
        await this.refreshDoctorRating(tx, review.doctorId);
      }

      return next;
    });

    return updated;
  }

  private async refreshDoctorRating(
    tx: Prisma.TransactionClient,
    doctorId: string,
  ) {
    const aggregate = await tx.review.aggregate({
      where: {
        doctorId,
        isVisible: true,
      },
      _avg: {
        rating: true,
      },
    });

    await tx.doctor.update({
      where: { id: doctorId },
      data: {
        avgRating: aggregate._avg.rating ?? 0,
      },
    });
  }
}
