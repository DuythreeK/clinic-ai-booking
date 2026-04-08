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
    const slot_date = new Date(startAt);
    slot_date.setHours(0, 0, 0, 0);

    const durationMinutes = Math.max(
      1,
      Math.round((endAt.getTime() - startAt.getTime()) / 60000),
    );

    return this.prisma.slot.create({
      data: {
        doctor_id: this.toBigIntId(dto.doctor_id),
        facility_id: this.toBigIntId(dto.clinicId),
        slot_date: slot_date,
        start_time: startAt,
        end_time: endAt,
        duration_minutes: durationMinutes,
        status: dto.isBlocked ? 'INACTIVE' : 'AVAILABLE',
        is_active: dto.isBlocked ? 0 : 1,
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

  async getSlots(doctor_id?: string, clinicId?: string, fromDate?: string, toDate?: string) {
    const where: any = {};

    if (doctor_id) where.doctor_id = this.toBigIntId(doctor_id);
    if (clinicId) where.facility_id = this.toBigIntId(clinicId);

    if (fromDate || toDate) {
      where.slot_date = {};
      if (fromDate) where.slot_date.gte = new Date(fromDate);
      if (toDate) where.slot_date.lte = new Date(toDate);
    }

    return this.prisma.slot.findMany({
      where,
      orderBy: [{ slot_date: 'asc' }, { start_time: 'asc' }],
    });
  }

  async getSlotById(id: string) {
    const slot = await this.prisma.slot.findUnique({
      where: { slot_id: this.toBigIntId(id) },
    });

    if (!slot) throw new NotFoundException('Slot not found');
    return slot;
  }

  async updateSlot(id: string, dto: UpdateSlotDto) {
    await this.getSlotById(id);

    return this.prisma.slot.update({
      where: { slot_id: this.toBigIntId(id) },
      data: {
        is_active: dto.isBlocked === undefined ? undefined : dto.isBlocked ? 0 : 1,
        status: dto.isBlocked === undefined ? undefined : dto.isBlocked ? 'INACTIVE' : 'AVAILABLE',
      },
    });
  }

  async deleteSlot(id: string) {
    return this.prisma.slot.delete({
      where: { slot_id: this.toBigIntId(id) },
    });
  }

  async getAvailableSlots(doctor_id: string, clinicId: string, fromDate: string, toDate: string) {
    return this.prisma.slot.findMany({
      where: {
        doctor_id: this.toBigIntId(doctor_id),
        facility_id: this.toBigIntId(clinicId),


        slot_date: {
          gte: new Date(fromDate),
          lte: new Date(toDate),
        },
      },
      include: {
        appointment: true, // Lôi dữ liệu lịch hẹn ra để Flutter check
      },
      orderBy: [{ slot_date: 'asc' }, { start_time: 'asc' }],
    });
  }
}
