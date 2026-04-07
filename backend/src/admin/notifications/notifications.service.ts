import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { NotifType, Prisma } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { resolvePagination } from '../common/utils/pagination.util';
import {
  CreateNotificationDto,
  NotificationListQueryDto,
  UpdateNotificationDto,
} from './dto/notification.dto';

const notificationInclude = {
  patient: true,
  appointment: true,
} satisfies Prisma.NotificationInclude;

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: NotificationListQueryDto) {
    const { skip, take, page, limit } = resolvePagination(query);
    const where: Prisma.NotificationWhereInput = {
      patientId: query.patientId,
      appointmentId: query.appointmentId,
      type: query.type,
      isRead: query.isRead,
      isSent: query.isSent,
      OR: query.search
        ? [
            { title: { contains: query.search } },
            { message: { contains: query.search } },
            { patient: { is: { fullName: { contains: query.search } } } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        skip,
        take,
        include: notificationInclude,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.notification.count({ where }),
    ]);

    return { data: items, meta: { page, limit, total } };
  }

  async findOne(id: string) {
    const notification = await this.prisma.notification.findUnique({
      where: { id },
      include: notificationInclude,
    });
    if (!notification) {
      throw new NotFoundException('Khong tim thay thong bao');
    }

    return notification;
  }

  async create(dto: CreateNotificationDto) {
    const patient = await this.prisma.patient.findUnique({
      where: { id: dto.patientId },
    });

    if (!patient) {
      throw new BadRequestException('Benh nhan khong ton tai');
    }

    if (dto.appointmentId) {
      const appointment = await this.prisma.appointment.findUnique({
        where: { id: dto.appointmentId },
      });
      if (!appointment) {
        throw new BadRequestException('Lich hen khong ton tai');
      }
    }

    return this.prisma.notification.create({
      data: {
        patientId: dto.patientId,
        appointmentId: dto.appointmentId,
        type: dto.type ?? NotifType.system,
        title: dto.title,
        message: dto.message,
        isSent: dto.isSent ?? false,
      },
      include: notificationInclude,
    });
  }

  async update(id: string, dto: UpdateNotificationDto) {
    await this.findOne(id);

    return this.prisma.notification.update({
      where: { id },
      data: {
        title: dto.title,
        message: dto.message,
        isRead: dto.isRead,
        isSent: dto.isSent,
      },
      include: notificationInclude,
    });
  }
}
