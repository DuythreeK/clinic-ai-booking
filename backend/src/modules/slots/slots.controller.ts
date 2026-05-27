/**
 * SlotsController
 * - Cung cấp các API quản lý slot: CRUD, tra cứu còn trống, xem log capacity.
 * - Các API ghi dữ liệu đều cần JWT + phân quyền phù hợp.
 * - Controller chỉ giữ vai trò nhận request và gọi service.
 */
import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { SlotsService } from './slots.service';
import {
  CreateSlotDto,
  UpdateSlotDto,
  CreateBulkSlotsDto,
  UpdateSlotCapacityDto,
} from './dto/slot.dto';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';

@Controller('slots')
export class SlotsController {
  constructor(private slotsService: SlotsService) {}

  // Lấy danh sách slot theo bộ lọc bác sĩ, cơ sở và khoảng ngày.
  @Get()
  async getSlots(
    @Query('doctor_id') doctor_id?: string,
    @Query('clinicId') clinicId?: string,
    @Query('fromDate') fromDate?: string,
    @Query('toDate') toDate?: string,
  ) {
    return this.slotsService.getSlots(doctor_id, clinicId, fromDate, toDate);
  }

  // API kiểm tra slot còn trống cho luồng đặt lịch.
  @Get('available')
  async getAvailableSlots(
    @Query('doctor_id') doctor_id: string,
    @Query('clinicId') clinicId: string,
    @Query('fromDate') fromDate: string,
    @Query('toDate') toDate: string,
  ) {
    return this.slotsService.getAvailableSlots(doctor_id, clinicId, fromDate, toDate);
  }

  // Lấy một slot theo id.
  @Get(':id')
  async getSlotById(@Param('id') id: string) {
    return this.slotsService.getSlotById(id);
  }

  // Log thay đổi capacity, chỉ admin dùng.
  @Get(':id/capacity-logs')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin)
  async getSlotCapacityLogs(
    @Param('id') id: string,
    @Query('limit') limit?: string,
  ) {
    return this.slotsService.getSlotCapacityLogs(
      id,
      limit ? Number(limit) : 50,
    );
  }

  // Tạo một slot cho lịch làm việc của bác sĩ.
  @Post()
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.doctor)
  async createSlot(@Body() dto: CreateSlotDto) {
    return this.slotsService.createSlot(dto);
  }

  // API tạo nhiều slot cùng lúc, đang để sẵn cho luồng sinh lịch sau này.
  @Post('bulk')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.doctor)
  async createBulkSlots(@Body() dto: CreateBulkSlotsDto) {
    return this.slotsService.createBulkSlots(dto);
  }

  // Bật/tắt slot mà không xoá bản ghi.
  @Patch(':id')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.doctor)
  async updateSlot(
    @Param('id') id: string,
    @Body() dto: UpdateSlotDto,
  ) {
    return this.slotsService.updateSlot(id, dto);
  }

  // Điều chỉnh capacity còn lại và ghi log audit.
  @Patch(':id/capacity')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin)
  async updateSlotCapacity(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateSlotCapacityDto,
  ) {
    return this.slotsService.updateSlotCapacity(userId, id, dto);
  }

  // Xoá hẳn một slot.
  @Delete(':id')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.doctor)
  async deleteSlot(@Param('id') id: string) {
    return this.slotsService.deleteSlot(id);
  }
}
