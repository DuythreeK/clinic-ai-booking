import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AppointmentStatus,
  NotificationType,
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
  medical_record: true,
  review: true,
  notifications: true,
} satisfies Prisma.AppointmentInclude;

@Injectable()
export class AppointmentsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: AppointmentListQueryDto) {
    const { skip, take, page, limit } = resolvePagination(query);
    const where: Prisma.AppointmentWhereInput = {
      status: query.status as AppointmentStatus,
      patient_id: query.patientId ? BigInt(query.patientId) : undefined,
      doctor_id: query.doctorId ? BigInt(query.doctorId) : undefined,
      schedule_id: query.scheduleId ? BigInt(query.scheduleId) : undefined,
      appointment_date:
        query.fromDate || query.toDate
          ? {
              gte: query.fromDate ? parseDateOnly(query.fromDate) : undefined,
              lte: query.toDate ? parseDateOnly(query.toDate) : undefined,
            }
          : undefined,
      OR: query.search
        ? [
            { appointment_code: { contains: query.search } },
            { patient: { is: { full_name: { contains: query.search } } } },
            { patient: { is: { phone_number: { contains: query.search } } } },
            { doctor: { is: { user: { is: { full_name: { contains: query.search } } } } } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.appointment.findMany({
        where,
        skip,
        take,
        orderBy: [{ appointment_date: 'desc' }, { appointment_time: 'desc' }],
        include: appointmentInclude,
      }),
      this.prisma.appointment.count({ where }),
    ]);

    return { data: items, meta: { page, limit, total } };
  }

  async findOne(id: string) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { appointment_id: BigInt(id) },
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
            tx.patientProfile.findUnique({ where: { patient_id: BigInt(dto.patientId) } }),
            tx.schedule.findUnique({ where: { scheduleId: BigInt(dto.scheduleId) } }),
          ]);

          if (!patient) {
            throw new NotFoundException('Benh nhan khong ton tai');
          }

          if (!schedule) {
            throw new NotFoundException('Lich lam viec khong ton tai');
          }

          // Group schema schedule doesn't have isAvailable or bookedSlots, using is_active
          if (schedule.is_active === 0) {
            throw new BadRequestException('Lich nay khong con kha dung');
          }

          const appointmentCode = await this.generateRefCode(tx, schedule.workDate);

          const appointment = await tx.appointment.create({
            data: {
              appointment_code: appointmentCode,
              patient_id: patient.patient_id,
              doctor_id: schedule.doctor_id,
              schedule_id: schedule.scheduleId,
              appointment_date: schedule.workDate,
              appointment_time: schedule.startTime,
              status: 'pending',
              note: dto.reason + (dto.symptoms ? `\nTrình bày: ${dto.symptoms}` : '') + (dto.notes ? `\nGhi chú: ${dto.notes}` : ''),
              user_id: patient.user_id,
              facility_id: BigInt(1), // TODO
              slot_id: BigInt(1000 + Math.floor(Math.random() * 9000)), // Temp unique slot_id until full Slot integration
              appointment_type: 'consultation',
              total_amount: new Prisma.Decimal(0),
            },
          });

          await tx.notification.create({
            data: {
              user_id: patient.user_id,
              appointment_id: appointment.appointment_id,
              type: 'system',
              channel: 'in_app',
              title: 'Yêu cầu đặt lịch mới',
              message: `Lịch hẹn ${appointment.appointment_code} đã được tạo và đang chờ xác nhận`,
            },
          });

          return tx.appointment.findUniqueOrThrow({
            where: { appointment_id: appointment.appointment_id },
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

    const allowedTransitions: Record<AppointmentStatus, AppointmentStatus[]> = {
      pending: [AppointmentStatus.confirmed, AppointmentStatus.cancelled],
      confirmed: [AppointmentStatus.checked_in, AppointmentStatus.no_show],
      checked_in: [AppointmentStatus.in_progress, AppointmentStatus.cancelled],
      in_progress: [AppointmentStatus.completed],
      completed: [],
      no_show: [],
      cancelled: [],
    };

    if (!allowedTransitions[appointment.status].includes(dto.status)) {
      throw new BadRequestException(
        `Khong the chuyen trang thai tu ${appointment.status} sang ${dto.status}`,
      );
    }

    if (dto.status === AppointmentStatus.cancelled) {
      throw new BadRequestException('Dùng endpoint cancel để hủy lịch hẹn');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const now = new Date();

      const item = await tx.appointment.update({
        where: { appointment_id: BigInt(id) },
        data: {
          status: dto.status as AppointmentStatus,
          // Note: Add checked_in_at etc to Appointment if needed
        },
        include: appointmentInclude,
      });

      if (dto.status === AppointmentStatus.completed) {
        await tx.patientProfile.update({
          where: { patient_id: item.patient_id },
          data: {
            // totalVisits is not in group schema PatientProfile, skipping for now
          },
        });
      }

      if (dto.status === AppointmentStatus.confirmed) {
        await tx.notification.create({
          data: {
            user_id: item.user_id,
            appointment_id: item.appointment_id,
            type: 'appointment_confirmed',
            channel: 'in_app',
            title: 'Lịch hẹn đã được xác nhận',
            message: `Lịch ${item.appointment_code} đã được xác nhận`,
          },
        });
      }

      return item;
    });

    return updated;
  }

  async cancel(id: string, dto: CancelAppointmentDto) {
    const appointment = await this.getAppointmentOrThrow(id);

    if (appointment.status === AppointmentStatus.cancelled) {
      throw new BadRequestException('Lịch hẹn đã bị hủy');
    }

    if (
      appointment.status === AppointmentStatus.completed ||
      appointment.status === AppointmentStatus.no_show ||
      appointment.status === AppointmentStatus.in_progress ||
      appointment.status === AppointmentStatus.confirmed
    ) {
      throw new BadRequestException(`Không thể hủy lịch hẹn đang ở trạng thái ${appointment.status}`);
    }

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.appointment.update({
        where: { appointment_id: BigInt(id) },
        data: {
          status: AppointmentStatus.cancelled,
          cancellation_reason: dto.cancelReason,
        },
        include: appointmentInclude,
      });

      if (appointment.status === AppointmentStatus.pending) {
        await tx.schedule.update({
          where: { scheduleId: appointment.schedule_id! },
          data: {
            // Adjust schedule availability
          },
        });
      }

      await tx.notification.create({
        data: {
          user_id: updated.user_id,
          appointment_id: updated.appointment_id,
          type: 'appointment_cancelled',
          channel: 'in_app',
          title: 'Lịch hẹn đã bị hủy',
          message: `Lịch ${updated.appointment_code} đã bị hủy`,
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
      where: { appointment_code: { startsWith: prefix } },
      orderBy: { appointment_code: 'desc' },
      select: { appointment_code: true },
    });

    const nextNumber = latest
      ? Number(latest.appointment_code.slice(-4)) + 1
      : 1;

    return `${prefix}${String(nextNumber).padStart(4, '0')}`;
  }

  private async getAppointmentOrThrow(id: string) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { appointment_id: BigInt(id) },
      include: appointmentInclude,
    });

    if (!appointment) {
      throw new NotFoundException('Khong tim thay lich hen');
    }

    return appointment;
  }
}
