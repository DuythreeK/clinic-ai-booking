import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import {
  CreateSlotDto,
  UpdateSlotDto,
  CreateBulkSlotsDto,
  UpdateSlotCapacityDto,
} from './dto/slot.dto';
import { AppointmentStatus } from '@prisma/client';
import { okResponse } from '@/common/utils/api-response';

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
        doctor_id: this.toBigIntId(dto.doctorId),
        facility_id: this.toBigIntId(dto.clinicId),
        slot_date: slotDate,
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

  async getSlots(doctorId?: string, clinicId?: string, fromDate?: string, toDate?: string) {
    /**
     * Lấy danh sách slot theo điều kiện (doctorId, clinicId, từ ngày -> đến ngày)
     * Trả về các slot kèm booked_count và total_capacity
     */
    const where: any = {};

    if (doctorId) where.doctor_id = this.toBigIntId(doctorId);
    if (clinicId) where.facility_id = this.toBigIntId(clinicId);

    if (fromDate || toDate) {
      where.slot_date = {};
      if (fromDate) where.slot_date.gte = new Date(fromDate);
      if (toDate) where.slot_date.lte = new Date(toDate);
    }

    const slots = await this.prisma.slot.findMany({
      where,
      orderBy: [{ slot_date: 'asc' }, { start_time: 'asc' }],
      include: {
        appointments: {
          select: {
            status: true,
          },
        },
      },
    });

    return slots.map((slot) => {
      const bookedCount = slot.appointments.filter(
        (appointment) => appointment.status !== AppointmentStatus.cancelled,
      ).length;

      const { appointments, ...rest } = slot;
      return {
        ...rest,
        booked_count: bookedCount,
        total_capacity: Number(slot.available_count) + bookedCount,
      };
    });
  }

  async getSlotById(id: string) {
    /**
     * Lấy chi tiết slot theo id kèm booked_count và total_capacity
     * Throws NotFoundException nếu slot không tồn tại
     */
    const slot = await this.prisma.slot.findUnique({
      where: { slot_id: this.toBigIntId(id) },
      include: {
        appointments: {
          select: {
            status: true,
          },
        },
      },
    });

    if (!slot) throw new NotFoundException('Slot not found');
    const bookedCount = slot.appointments.filter(
      (appointment) => appointment.status !== AppointmentStatus.cancelled,
    ).length;
    const { appointments, ...rest } = slot;
    return {
      ...rest,
      booked_count: bookedCount,
      total_capacity: Number(slot.available_count) + bookedCount,
    };
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

  async getSlotCapacityLogs(id: string, limit = 50) {
    /**
     * Lấy nhật ký thay đổi sức chứa cho slot (slotCapacityLog)
     * - Kiểm tra slot tồn tại
     * - Trả về list log đã format kèm thông tin user cập nhật
     */
    const slotId = this.toBigIntId(id);
    const safeLimit = Math.min(Math.max(limit, 1), 200);

    const slot = await this.prisma.slot.findUnique({
      where: { slot_id: slotId },
      select: { slot_id: true },
    });
    if (!slot) {
      throw new NotFoundException('Slot not found');
    }

    const logs = await this.prisma.slotCapacityLog.findMany({
      where: { slot_id: slotId },
      orderBy: { created_at: 'desc' },
      take: safeLimit,
      include: {
        user: {
          select: {
            user_id: true,
            full_name: true,
            email: true,
          },
        },
      },
    });

    return okResponse('Get slot capacity logs successfully', logs.map((log) => ({
      id: Number(log.id),
      slotId: Number(log.slot_id),
      updatedBy: Number(log.updated_by),
      updatedByName: log.user?.full_name ?? null,
      updatedByEmail: log.user?.email ?? null,
      oldCapacity: log.old_available_count,
      newCapacity: log.new_available_count,
      reason: log.reason,
      createdAt: log.created_at,
    })));
  }

  async updateSlotCapacity(userId: string, id: string, dto: UpdateSlotCapacityDto) {
    /**
     * Cập nhật sức chứa slot (admin)
     * Quy trình:
     *  - Kiểm tra valid newCapacity và slot tồn tại
     *  - Tính bookedCount hiện tại, đảm bảo newCapacity >= bookedCount
     *  - Trong transaction update slot.available_count và tạo SlotCapacityLog
     *  - Trả về summary với old/new capacity và status
     */
    const slotId = this.toBigIntId(id);
    const adminUserId = this.toBigIntId(userId);
    const requestedCapacity = Number(dto.newCapacity);

    if (!Number.isFinite(requestedCapacity) || requestedCapacity < 0) {
      throw new BadRequestException('newCapacity must be a non-negative number');
    }
    if (!Number.isInteger(requestedCapacity)) {
      throw new BadRequestException('newCapacity must be an integer');
    }

    const slot = await this.prisma.slot.findUnique({
      where: { slot_id: slotId },
      select: {
        slot_id: true,
        facility_id: true,
        doctor_id: true,
        available_count: true,
        status: true,
        is_active: true,
      },
    });

    if (!slot || slot.is_active !== 1) {
      throw new NotFoundException('Slot not found');
    }

    const bookedCount = await this.prisma.appointment.count({
      where: {
        slot_id: slotId,
        status: {
          not: AppointmentStatus.cancelled,
        },
      },
    });

    if (requestedCapacity < bookedCount) {
      throw new BadRequestException(
        `newCapacity cannot be less than booked count (${bookedCount})`,
      );
    }

    const oldCapacity = Number(slot.available_count) + bookedCount;
    const newAvailableCount = requestedCapacity - bookedCount;
    const nextStatus = newAvailableCount > 0 ? 'AVAILABLE' : 'FULL';

    await this.prisma.$transaction(async (tx) => {
      await tx.slot.update({
        where: { slot_id: slotId },
        data: {
          available_count: newAvailableCount,
          status: nextStatus,
        },
      });

      await tx.slotCapacityLog.create({
        data: {
          slot_id: slotId,
          updated_by: adminUserId,
          old_available_count: oldCapacity,
          new_available_count: requestedCapacity,
          reason: dto.reason?.trim(),
        },
      });
    });

    return okResponse('Update slot capacity successfully', {
      slotId: Number(slot.slot_id),
      oldCapacity,
      newCapacity: requestedCapacity,
      bookedCount,
      availableCount: newAvailableCount,
      status: nextStatus,
    });
  }

  async getAvailableSlots(doctorId: string, clinicId: string, fromDate: string, toDate: string) {
    /**
     * Lấy các slot AVAILABLE cho doctor+clinic trong range ngày
     * Trả về danh sách slot thô (dùng nội bộ hoặc API khác map sang DTO)
     */
    return this.prisma.slot.findMany({
      where: {
        doctor_id: this.toBigIntId(doctorId),
        facility_id: this.toBigIntId(clinicId),
        status: 'AVAILABLE',
        is_active: 1,
        slot_date: {
          gte: new Date(fromDate),
          lte: new Date(toDate),
        },
      },
      orderBy: [{ slot_date: 'asc' }, { start_time: 'asc' }],
    });
  }
}
