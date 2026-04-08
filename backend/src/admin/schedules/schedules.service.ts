import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, Schedule } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import {
  isTimeAfter,
  parseDateOnly,
  parseTimeOnly,
} from '../common/utils/date.util';
import { resolvePagination } from '../common/utils/pagination.util';
import {
  CreateScheduleDto,
  ScheduleListQueryDto,
  UpdateScheduleDto,
} from './dto/schedule.dto';

@Injectable()
export class SchedulesService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: ScheduleListQueryDto) {
    const { skip, take, page, limit } = resolvePagination(query);
    const where: Prisma.ScheduleWhereInput = {
      doctor_id: query.doctorId ? BigInt(query.doctorId) : undefined,
      room_id: query.roomId ? BigInt(query.roomId) : undefined,
      is_active: query.isAvailable !== undefined ? (query.isAvailable ? 1 : 0) : undefined,
      workDate: query.workDate
        ? parseDateOnly(query.workDate)
        : query.fromDate || query.toDate
          ? {
              gte: query.fromDate ? parseDateOnly(query.fromDate) : undefined,
              lte: query.toDate ? parseDateOnly(query.toDate) : undefined,
            }
          : undefined,
      OR: query.search
        ? [
            { doctor: { is: { user: { is: { full_name: { contains: query.search } } } } } },
            { room: { is: { name: { contains: query.search } } } },
            { room: { is: { code: { contains: query.search } } } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.schedule.findMany({
        where,
        skip,
        take,
        include: {
          doctor: { include: { user: true, specialty: true } },
          room: true,
        },
        orderBy: [{ workDate: 'asc' }, { startTime: 'asc' }],
      }),
      this.prisma.schedule.count({ where }),
    ]);

    return { data: items, meta: { page, limit, total } };
  }

  async findOne(id: string) {
    const schedule = await this.prisma.schedule.findUnique({
      where: { scheduleId: BigInt(id) },
      include: {
        doctor: { include: { user: true, specialty: true } },
        room: true,
      },
    });
    if (!schedule) {
      throw new NotFoundException('Khong tim thay lich lam viec');
    }

    return schedule;
  }

  async create(dto: CreateScheduleDto) {
    await this.ensureDoctorExists(dto.doctorId);
    await this.ensureRoomExists(dto.roomId);
    this.validateTimeWindow(dto.startTime, dto.endTime);

    try {
      return await this.prisma.schedule.create({
        data: {
          doctor_id: BigInt(dto.doctorId),
          room_id: dto.roomId ? BigInt(dto.roomId) : null,
          workDate: parseDateOnly(dto.workDate),
          startTime: parseTimeOnly(dto.startTime),
          endTime: parseTimeOnly(dto.endTime),
          slotDuration: dto.slotDurationMin ?? 30,
          maxSlots: dto.maxSlots,
          is_active: dto.isAvailable !== false ? 1 : 0,
        },
        include: {
          doctor: { include: { user: true, specialty: true } },
          room: true,
        },
      });
    } catch (error) {
      this.handleScheduleConstraintError(error, dto.workDate);
    }
  }

  async update(id: string, dto: UpdateScheduleDto) {
    const schedule = await this.getScheduleOrThrow(id);
    const nextDoctorId = dto.doctorId ?? schedule.doctor_id.toString();
    const nextRoomId =
      dto.roomId === null || dto.roomId === '' ? null : dto.roomId ?? schedule.room_id?.toString();
    const nextWorkDate = dto.workDate ?? schedule.workDate.toISOString().slice(0, 10);
    const nextStartTime = dto.startTime ?? schedule.startTime.toISOString().slice(11, 16);
    const nextEndTime = dto.endTime ?? schedule.endTime.toISOString().slice(11, 16);
    const nextMaxSlots = dto.maxSlots ?? schedule.maxSlots;

    const bookedSlots = (schedule as any).bookedSlots || 0;
    if (bookedSlots > nextMaxSlots) {
      throw new BadRequestException('maxSlots khong duoc nho hon so slot da dat');
    }

    await this.ensureDoctorExists(nextDoctorId);
    await this.ensureRoomExists(nextRoomId ?? undefined);
    this.validateTimeWindow(nextStartTime, nextEndTime);

    try {
      return await this.prisma.schedule.update({
        where: { scheduleId: BigInt(id) },
        data: {
          doctor_id: BigInt(nextDoctorId),
          room_id: nextRoomId ? BigInt(nextRoomId) : null,
          workDate: parseDateOnly(nextWorkDate),
          startTime: parseTimeOnly(nextStartTime),
          endTime: parseTimeOnly(nextEndTime),
          slotDuration: dto.slotDurationMin,
          maxSlots: nextMaxSlots,
          is_active:
            dto.isAvailable !== undefined ? (dto.isAvailable ? 1 : 0) : ((schedule as any).bookedSlots < nextMaxSlots ? 1 : 0),
        },
        include: {
          doctor: { include: { user: true, specialty: true } },
          room: true,
        },
      });
    } catch (error) {
      this.handleScheduleConstraintError(error, nextWorkDate);
    }
  }

  private async getScheduleOrThrow(id: string): Promise<any> {
    const schedule = await this.prisma.schedule.findUnique({ where: { scheduleId: BigInt(id) } });
    if (!schedule) {
      throw new NotFoundException('Khong tim thay lich lam viec');
    }

    return schedule;
  }

  private validateTimeWindow(startTime: string, endTime: string) {
    if (!isTimeAfter(startTime, endTime)) {
      throw new BadRequestException('endTime phai lon hon startTime');
    }
  }

  private async ensureDoctorExists(id: string) {
    const doctor = await this.prisma.doctor.findUnique({ where: { doctor_id: BigInt(id) } });
    if (!doctor) {
      throw new BadRequestException('Bac si khong ton tai');
    }
  }

  private async ensureRoomExists(id?: string) {
    if (!id) {
      return;
    }

    const room = await this.prisma.room.findUnique({ where: { room_id: BigInt(id) } });
    if (!room) {
      throw new BadRequestException('Phong khong ton tai');
    }
  }

  private handleScheduleConstraintError(error: unknown, workDate: string): never {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      throw new BadRequestException(
        `Lich lam viec ngay ${workDate} da ton tai cho bac si nay`,
      );
    }

    throw error;
  }
}
