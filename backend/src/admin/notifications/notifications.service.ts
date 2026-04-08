import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { resolvePagination } from '../common/utils/pagination.util';
import {
  CreateNotificationDto,
  NotificationListQueryDto,
  UpdateNotificationDto,
} from './dto/notification.dto';

const notificationInclude = {
  user: true,
  appointment: true,
} satisfies Prisma.NotificationInclude;

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: NotificationListQueryDto) {
    const { skip, take, page, limit } = resolvePagination(query);
    const where: Prisma.NotificationWhereInput = {
      user_id: query.patientId ? BigInt(query.patientId) : undefined,
      appointment_id: query.appointmentId ? BigInt(query.appointmentId) : undefined,
      type: query.type as any,
      is_read: query.isRead !== undefined ? (query.isRead ? 1 : 0) : undefined,
      OR: query.search
        ? [
            { title: { contains: query.search } },
            { message: { contains: query.search } },
            { user: { is: { full_name: { contains: query.search } } } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        skip,
        take,
        include: notificationInclude,
        orderBy: { created_at: 'desc' },
      }),
      this.prisma.notification.count({ where }),
    ]);

    return { data: items, meta: { page, limit, total } };
  }

  async findOne(id: string) {
    const notification = await this.prisma.notification.findUnique({
      where: { id: BigInt(id) },
      include: notificationInclude,
    });
    if (!notification) {
      throw new NotFoundException('Khong tim thay thong bao');
    }

    return notification;
  }

  async create(dto: CreateNotificationDto) {
    const user = await this.prisma.user.findUnique({
      where: { user_id: BigInt(dto.patientId) },
    });

    if (!user) {
      throw new BadRequestException('Nguoi dung khong ton tai');
    }

    if (dto.appointmentId) {
      const appointment = await this.prisma.appointment.findUnique({
        where: { appointment_id: BigInt(dto.appointmentId) },
      });
      if (!appointment) {
        throw new BadRequestException('Lich hen khong ton tai');
      }
    }

    return this.prisma.notification.create({
      data: {
        user_id: BigInt(dto.patientId),
        appointment_id: dto.appointmentId ? BigInt(dto.appointmentId) : null,
        type: (dto.type as any) ?? 'system',
        channel: 'in_app',
        title: dto.title,
        message: dto.message,
      },
      include: notificationInclude,
    });
  }

  async update(id: string, dto: UpdateNotificationDto) {
    await this.findOne(id);

    return this.prisma.notification.update({
      where: { id: BigInt(id) },
      data: {
        title: dto.title,
        message: dto.message,
        is_read: dto.isRead !== undefined ? (dto.isRead ? 1 : 0) : undefined,
      },
      include: notificationInclude,
    });
  }
}
