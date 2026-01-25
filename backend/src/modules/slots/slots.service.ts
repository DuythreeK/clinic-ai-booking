import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateSlotDto, UpdateSlotDto, CreateBulkSlotsDto } from './dto/slot.dto';

@Injectable()
export class SlotsService {
  constructor(private prisma: PrismaService) {}

  async createSlot(dto: CreateSlotDto) {
    const startAt = new Date(dto.startAt);
    const endAt = new Date(dto.endAt);

    if (startAt >= endAt) {
      throw new BadRequestException('Start time must be before end time');
    }

    const conflictingSlot = await this.prisma.slot.findFirst({
      where: {
        doctorId: dto.doctorId,
        clinicId: dto.clinicId,
        OR: [
          {
            startAt: { lt: endAt },
            endAt: { gt: startAt },
          },
        ],
      },
    });

    if (conflictingSlot) {
      throw new BadRequestException('Slot conflicts with existing slot');
    }

    return this.prisma.slot.create({
      data: {
        doctorId: dto.doctorId,
        clinicId: dto.clinicId,
        startAt,
        endAt,
        isBlocked: dto.isBlocked || false,
      },
      include: {
        doctor: { include: { user: true } },
        clinic: true,
      },
    });
  }

  async createBulkSlots(dto: CreateBulkSlotsDto) {
    const slots = [];
    const startDate = new Date(dto.startDate);
    const endDate = new Date(dto.endDate);
    const [startHour, startMinute] = dto.startTime.split(':').map(Number);
    const [endHour, endMinute] = dto.endTime.split(':').map(Number);

    let currentDate = new Date(startDate);
    currentDate.setHours(startHour, startMinute, 0, 0);

    while (currentDate < endDate) {
      if (dto.daysOfWeek.includes(currentDate.getDay())) {
        let slotStart = new Date(currentDate);
        let slotEnd = new Date(slotStart.getTime() + dto.slotDuration * 60000);

        while (slotEnd <= new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate(), endHour, endMinute, 0)) {
          slots.push({
            doctorId: dto.doctorId,
            clinicId: dto.clinicId,
            startAt: new Date(slotStart),
            endAt: new Date(slotEnd),
            isBlocked: false,
          });

          slotStart = new Date(slotEnd);
          slotEnd = new Date(slotStart.getTime() + dto.slotDuration * 60000);
        }
      }

      currentDate.setDate(currentDate.getDate() + 1);
      currentDate.setHours(startHour, startMinute, 0, 0);
    }

    const createdSlots = await this.prisma.slot.createMany({
      data: slots,
    });

    return { created: createdSlots.count, slots };
  }

  async getSlots(doctorId?: string, clinicId?: string, fromDate?: string, toDate?: string) {
    const where: any = {};

    if (doctorId) where.doctorId = doctorId;
    if (clinicId) where.clinicId = clinicId;

    if (fromDate || toDate) {
      where.startAt = {};
      if (fromDate) where.startAt.gte = new Date(fromDate);
      if (toDate) where.startAt.lte = new Date(toDate);
    }

    return this.prisma.slot.findMany({
      where,
      include: {
        doctor: { include: { user: true } },
        clinic: true,
        appointments: { select: { id: true, status: true } },
      },
      orderBy: { startAt: 'asc' },
    });
  }

  async getSlotById(id: string) {
    const slot = await this.prisma.slot.findUnique({
      where: { id },
      include: {
        doctor: { include: { user: true } },
        clinic: true,
        appointments: true,
      },
    });

    if (!slot) throw new NotFoundException('Slot not found');
    return slot;
  }

  async updateSlot(id: string, dto: UpdateSlotDto) {
    await this.getSlotById(id);

    return this.prisma.slot.update({
      where: { id },
      data: dto,
      include: {
        doctor: { include: { user: true } },
        clinic: true,
      },
    });
  }

  async deleteSlot(id: string) {
    const slot = await this.getSlotById(id);

    if (slot.appointments.length > 0) {
      throw new BadRequestException('Cannot delete slot with appointments');
    }

    return this.prisma.slot.delete({
      where: { id },
    });
  }

  async getAvailableSlots(doctorId: string, clinicId: string, fromDate: string, toDate: string) {
    return this.prisma.slot.findMany({
      where: {
        doctorId,
        clinicId,
        isBlocked: false,
        startAt: { gte: new Date(fromDate) },
        endAt: { lte: new Date(toDate) },
        appointments: { none: {} },
      },
      include: {
        doctor: { include: { user: true } },
        clinic: true,
      },
      orderBy: { startAt: 'asc' },
    });
  }
}
