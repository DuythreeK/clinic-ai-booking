import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  ApptStatus,
  NotifType,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { formatDateKey, parseDateOnly } from '../common/utils/date.util';
import { resolvePagination } from '../common/utils/pagination.util';
import {
  AppointmentListQueryDto,
  CancelAppointmentDto,
  CreateBookingDto,
  UpdateAppointmentStatusDto,
} from './dto/appointment.dto';

const appointmentInclude = {
  patient: true,
  doctor: {
    include: {
      user: true,
      specialty: true,
    },
  },
  schedule: {
    include: {
      room: true,
    },
  },
  medicalRecord: true,
  review: true,
  notifications: true,
} satisfies Prisma.AppointmentInclude;

@Injectable()
export class AppointmentsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: AppointmentListQueryDto) {
    const { skip, take, page, limit } = resolvePagination(query);
    const where: Prisma.AppointmentWhereInput = {
      status: query.status,
      patientId: query.patientId,
      doctorId: query.doctorId,
      scheduleId: query.scheduleId,
      apptDate:
        query.fromDate || query.toDate
          ? {
              gte: query.fromDate ? parseDateOnly(query.fromDate) : undefined,
              lte: query.toDate ? parseDateOnly(query.toDate) : undefined,
            }
          : undefined,
      OR: query.search
        ? [
            { refCode: { contains: query.search } },
            { patient: { is: { fullName: { contains: query.search } } } },
            { patient: { is: { phone: { contains: query.search } } } },
            { doctor: { is: { user: { is: { fullName: { contains: query.search } } } } } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.appointment.findMany({
        where,
        skip,
        take,
        orderBy: [{ apptDate: 'desc' }, { apptTime: 'desc' }],
        include: appointmentInclude,
      }),
      this.prisma.appointment.count({ where }),
    ]);

    return { data: items, meta: { page, limit, total } };
  }

  async findOne(id: string) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id },
      include: appointmentInclude,
    });

    if (!appointment) {
      throw new NotFoundException('Khong tim thay lich hen');
    }

    return appointment;
  }

  async createBooking(dto: CreateBookingDto) {
    for (let attempt = 0; attempt < 3; attempt += 1) {
      try {
        return await this.prisma.$transaction(async (tx) => {
          const [patient, schedule] = await Promise.all([
            tx.patient.findUnique({ where: { id: dto.patientId } }),
            tx.schedule.findUnique({ where: { id: dto.scheduleId } }),
          ]);

          if (!patient) {
            throw new NotFoundException('Benh nhan khong ton tai');
          }

          if (!schedule) {
            throw new NotFoundException('Lich lam viec khong ton tai');
          }

          if (!schedule.isAvailable || schedule.bookedSlots >= schedule.maxSlots) {
            throw new BadRequestException('Lich nay da het slot');
          }

          const refCode = await this.generateRefCode(tx, schedule.workDate);
          const queueNumber = schedule.bookedSlots + 1;

          const appointment = await tx.appointment.create({
            data: {
              refCode,
              patientId: patient.id,
              doctorId: schedule.doctorId,
              scheduleId: schedule.id,
              apptDate: schedule.workDate,
              apptTime: schedule.startTime,
              queueNumber,
              status: ApptStatus.pending,
              reason: dto.reason,
              symptoms: dto.symptoms,
              notes: dto.notes,
            },
          });

          const updatedSchedule = await tx.schedule.updateMany({
            where: {
              id: schedule.id,
              isAvailable: true,
              bookedSlots: schedule.bookedSlots,
            },
            data: {
              bookedSlots: { increment: 1 },
              isAvailable: queueNumber < schedule.maxSlots,
            },
          });

          if (updatedSchedule.count === 0) {
            throw new BadRequestException('Slot vua duoc dat boi nguoi khac');
          }

          await tx.notification.create({
            data: {
              patientId: patient.id,
              appointmentId: appointment.id,
              type: NotifType.system,
              title: 'Yeu cau dat lich moi',
              message: `Lich hen ${appointment.refCode} da duoc tao va dang cho xac nhan`,
            },
          });

          return tx.appointment.findUniqueOrThrow({
            where: { id: appointment.id },
            include: appointmentInclude,
          });
        });
      } catch (error) {
        if (
          error instanceof Prisma.PrismaClientKnownRequestError &&
          error.code === 'P2002'
        ) {
          continue;
        }

        throw error;
      }
    }

    throw new BadRequestException('Khong the tao ma lich hen, vui long thu lai');
  }

  async updateStatus(id: string, dto: UpdateAppointmentStatusDto) {
    const appointment = await this.getAppointmentOrThrow(id);

    const allowedTransitions: Record<ApptStatus, ApptStatus[]> = {
      pending: [ApptStatus.confirmed, ApptStatus.cancelled],
      confirmed: [ApptStatus.completed, ApptStatus.cancelled],
      completed: [],
      cancelled: [],
    };

    if (!allowedTransitions[appointment.status].includes(dto.status)) {
      throw new BadRequestException(
        `Khong the chuyen trang thai tu ${appointment.status} sang ${dto.status}`,
      );
    }

    if (dto.status === ApptStatus.cancelled) {
      throw new BadRequestException('Dung endpoint cancel de huy lich hen');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const item = await tx.appointment.update({
        where: { id },
        data: {
          status: dto.status,
          completedAt:
            dto.status === ApptStatus.completed ? new Date() : undefined,
        },
        include: appointmentInclude,
      });

      if (dto.status === ApptStatus.confirmed) {
        await tx.notification.create({
          data: {
            patientId: item.patientId,
            appointmentId: item.id,
            type: NotifType.appointment_confirmed,
            title: 'Lich hen da duoc xac nhan',
            message: `Lich ${item.refCode} da duoc xac nhan`,
          },
        });
      }

      return item;
    });

    return updated;
  }

  async cancel(id: string, dto: CancelAppointmentDto) {
    const appointment = await this.getAppointmentOrThrow(id);

    if (appointment.status === ApptStatus.cancelled) {
      throw new BadRequestException('Lich hen da bi huy');
    }

    if (appointment.status === ApptStatus.completed) {
      throw new BadRequestException('Khong the huy lich hen da hoan thanh');
    }

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.appointment.update({
        where: { id },
        data: {
          status: ApptStatus.cancelled,
          cancelReason: dto.cancelReason,
        },
        include: appointmentInclude,
      });

      await tx.schedule.update({
        where: { id: appointment.scheduleId },
        data: {
          bookedSlots: { decrement: 1 },
          isAvailable: true,
        },
      });

      await tx.notification.create({
        data: {
          patientId: updated.patientId,
          appointmentId: updated.id,
          type: NotifType.appointment_cancelled,
          title: 'Lich hen da bi huy',
          message: `Lich ${updated.refCode} da bi huy`,
        },
      });

      return updated;
    });
  }

  private async generateRefCode(
    tx: Prisma.TransactionClient,
    workDate: Date,
  ): Promise<string> {
    const dateKey = formatDateKey(workDate);
    const prefix = `PKC-${dateKey}-`;
    const latest = await tx.appointment.findFirst({
      where: { refCode: { startsWith: prefix } },
      orderBy: { refCode: 'desc' },
      select: { refCode: true },
    });

    const nextNumber = latest
      ? Number(latest.refCode.slice(-4)) + 1
      : 1;

    return `${prefix}${String(nextNumber).padStart(4, '0')}`;
  }

  private async getAppointmentOrThrow(id: string) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id },
      include: appointmentInclude,
    });

    if (!appointment) {
      throw new NotFoundException('Khong tim thay lich hen');
    }

    return appointment;
  }
}
