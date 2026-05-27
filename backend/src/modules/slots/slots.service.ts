/**
 * SlotsService
 * - Xử lý logic nghiệp vụ cho slot: tạo, cập nhật, danh sách, xoá.
 * - Quản lý thay đổi capacity và ghi log audit.
 * - Dùng Prisma transaction khi cần đảm bảo tính nguyên tử.
 */
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateSlotDto, UpdateSlotDto, CreateBulkSlotsDto, UpdateSlotCapacityDto, } from './dto/slot.dto';
import { AppointmentStatus } from '@prisma/client';
import { okResponse } from '@/common/utils/api-response';

@Injectable()
export class SlotsService {
  constructor(private prisma: PrismaService) {}

  // Đổi id dạng chuỗi từ controller sang BigInt của Prisma.
  private toBigIntId(id: string): bigint {
    return BigInt(id);
  }

  // Tạo một slot từ khoảng thời gian đầu/cuối.
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

  // API tạo nhiều slot cùng lúc, hiện mới trả placeholder.
  async createBulkSlots(dto: CreateBulkSlotsDto) {
    return {
      created: 0,
      slots: [],
      note: 'Bulk slot creation is not implemented yet.',
    };
  }

  // Lấy danh sách slot theo bộ lọc tuỳ chọn.
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

  // Lấy một slot theo id, không có thì báo lỗi ngay.
  async getSlotById(id: string) {
    const slot = await this.prisma.slot.findUnique({
      where: { slot_id: this.toBigIntId(id) },
    });

    if (!slot) throw new NotFoundException('Slot not found');
    return slot;
  }

  // Bật/tắt trạng thái slot mà không xoá bản ghi.
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

  // Xoá slot khỏi hệ thống.
  async deleteSlot(id: string) {
    return this.prisma.slot.delete({
      where: { slot_id: this.toBigIntId(id) },
    });
  }

  // Lấy danh sách slot còn trống cho màn đặt lịch.
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
        appointments: true, // Lấy kèm lịch hẹn để client kiểm tra
      },
      orderBy: [{ slot_date: 'asc' }, { start_time: 'asc' }],
    });
  }

  // Trả log thay đổi capacity cho màn audit của admin.
  async getSlotCapacityLogs(id: string, limit = 50) {
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

    // Cập nhật capacity theo transaction và ghi một dòng audit log.
    async updateSlotCapacity(userId: string, id: string, dto: UpdateSlotCapacityDto) {
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

}
