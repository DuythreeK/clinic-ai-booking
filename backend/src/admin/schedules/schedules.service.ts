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
      doctorId: query.doctorId,
      roomId: query.roomId,
      isAvailable: query.isAvailable,
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
            { doctor: { is: { user: { is: { fullName: { contains: query.search } } } } } },
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
      where: { id },
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
          doctorId: dto.doctorId,
          roomId: dto.roomId,
          workDate: parseDateOnly(dto.workDate),
          startTime: parseTimeOnly(dto.startTime),
          endTime: parseTimeOnly(dto.endTime),
          slotDurationMin: dto.slotDurationMin ?? 30,
          maxSlots: dto.maxSlots,
          isAvailable: dto.isAvailable ?? true,
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
    const nextDoctorId = dto.doctorId ?? schedule.doctorId;
    const nextRoomId =
      dto.roomId === null || dto.roomId === '' ? null : dto.roomId ?? schedule.roomId;
    const nextWorkDate = dto.workDate ?? schedule.workDate.toISOString().slice(0, 10);
    const nextStartTime = dto.startTime ?? schedule.startTime.toISOString().slice(11, 16);
    const nextEndTime = dto.endTime ?? schedule.endTime.toISOString().slice(11, 16);
    const nextMaxSlots = dto.maxSlots ?? schedule.maxSlots;

    if (schedule.bookedSlots > nextMaxSlots) {
      throw new BadRequestException('maxSlots khong duoc nho hon so slot da dat');
    }

    await this.ensureDoctorExists(nextDoctorId);
    await this.ensureRoomExists(nextRoomId ?? undefined);
    this.validateTimeWindow(nextStartTime, nextEndTime);

    try {
      return await this.prisma.schedule.update({
        where: { id },
        data: {
          doctorId: nextDoctorId,
          roomId: nextRoomId,
          workDate: parseDateOnly(nextWorkDate),
          startTime: parseTimeOnly(nextStartTime),
          endTime: parseTimeOnly(nextEndTime),
          slotDurationMin: dto.slotDurationMin,
          maxSlots: nextMaxSlots,
          isAvailable:
            dto.isAvailable ?? schedule.bookedSlots < nextMaxSlots,
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

  private async getScheduleOrThrow(id: string): Promise<Schedule> {
    const schedule = await this.prisma.schedule.findUnique({ where: { id } });
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
    const doctor = await this.prisma.doctor.findUnique({ where: { id } });
    if (!doctor) {
      throw new BadRequestException('Bac si khong ton tai');
    }
  }

  private async ensureRoomExists(id?: string) {
    if (!id) {
      return;
    }

    const room = await this.prisma.room.findUnique({ where: { id } });
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
