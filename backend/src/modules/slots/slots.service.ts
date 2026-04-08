import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateSlotDto, UpdateSlotDto, CreateBulkSlotsDto } from './dto/slot.dto';

@Injectable()
export class SlotsService {
  constructor(private prisma: PrismaService) {}

  private toBigIntId(id: string): bigint {
    return BigInt(id);
  }

  async createSlot(dto: CreateSlotDto) {
    const startAt = new Date(dto.startAt);
    const endAt = new Date(dto.endAt);
    const slotDate = new Date(startAt);
    slotDate.setHours(0, 0, 0, 0);

    const durationMinutes = Math.max(
      1,
      Math.round((endAt.getTime() - startAt.getTime()) / 60000),
    );

    return this.prisma.slot.create({
      data: {
        doctorId: this.toBigIntId(dto.doctorId),
        facilityId: this.toBigIntId(dto.clinicId),
        slotDate: slotDate,
        startTime: startAt,
        endTime: endAt,
        duration_minutes: durationMinutes,
        status: dto.isBlocked ? 'INACTIVE' : 'AVAILABLE',
        isActive: dto.isBlocked ? 0 : 1,
      },
    });
  }

  async createBulkSlots(dto: CreateBulkSlotsDto) {
    return {
      created: 0,
      slots: [],
      note: 'Bulk slot creation is not implemented yet.',
    };
  }

  async getSlots(doctorId?: string, clinicId?: string, fromDate?: string, toDate?: string) {
    const where: any = {};

    if (doctorId) where.doctorId = this.toBigIntId(doctorId);
    if (clinicId) where.facilityId = this.toBigIntId(clinicId);

    if (fromDate || toDate) {
      where.slotDate = {};
      if (fromDate) where.slotDate.gte = new Date(fromDate);
      if (toDate) where.slotDate.lte = new Date(toDate);
    }

    return this.prisma.slot.findMany({
      where,
      orderBy: [{ slotDate: 'asc' }, { startTime: 'asc' }],
    });
  }

  async getSlotById(id: string) {
    const slot = await this.prisma.slot.findUnique({
      where: { slotId: this.toBigIntId(id) },
    });

    if (!slot) throw new NotFoundException('Slot not found');
    return slot;
  }

  async updateSlot(id: string, dto: UpdateSlotDto) {
    await this.getSlotById(id);

    return this.prisma.slot.update({
      where: { slotId: this.toBigIntId(id) },
      data: {
        isActive: dto.isBlocked === undefined ? undefined : dto.isBlocked ? 0 : 1,
        status: dto.isBlocked === undefined ? undefined : dto.isBlocked ? 'INACTIVE' : 'AVAILABLE',
      },
    });
  }

  async deleteSlot(id: string) {
    return this.prisma.slot.delete({
      where: { slotId: this.toBigIntId(id) },
    });
  }

  async getAvailableSlots(doctorId: string, clinicId: string, fromDate: string, toDate: string) {
    return this.prisma.slot.findMany({
      where: {
        doctorId: this.toBigIntId(doctorId),
        facilityId: this.toBigIntId(clinicId),


        slotDate: {
          gte: new Date(fromDate),
          lte: new Date(toDate),
        },
      },
      include: {
        appointment: true, // Lôi dữ liệu lịch hẹn ra để Flutter check
      },
      orderBy: [{ slotDate: 'asc' }, { startTime: 'asc' }],
    });
  }
}
