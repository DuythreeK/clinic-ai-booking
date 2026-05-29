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

  @Get()
  /**
   * GET /slots
   * Query: doctorId, clinicId, fromDate, toDate
   * Trả danh sách slot đã map booked_count và total_capacity
   */
  async getSlots(
    @Query('doctorId') doctorId?: string,
    @Query('clinicId') clinicId?: string,
    @Query('fromDate') fromDate?: string,
    @Query('toDate') toDate?: string,
  ) {
    return this.slotsService.getSlots(doctorId, clinicId, fromDate, toDate);
  }

  @Get('available')
  /**
   * GET /slots/available
   * Query: doctorId, clinicId, fromDate, toDate
   * Trả các slot có status AVAILABLE trong khoảng ngày
   */
  async getAvailableSlots(
    @Query('doctorId') doctorId: string,
    @Query('clinicId') clinicId: string,
    @Query('fromDate') fromDate: string,
    @Query('toDate') toDate: string,
  ) {
    return this.slotsService.getAvailableSlots(doctorId, clinicId, fromDate, toDate);
  }

  @Get(':id')
  /**
   * GET /slots/:id
   * Trả chi tiết slot theo id, kèm booked_count và total_capacity
   */
  async getSlotById(@Param('id') id: string) {
    return this.slotsService.getSlotById(id);
  }

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

  @Post()
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.doctor)
  /**
   * POST /slots
   * Requires JWT and role admin/doctor. Tạo slot mới
   */
  async createSlot(@Body() dto: CreateSlotDto) {
    return this.slotsService.createSlot(dto);
  }

  @Post('bulk')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.doctor)
  /**
   * POST /slots/bulk
   * Requires JWT and role admin/doctor. Tạo nhiều slot (bulk)
   */
  async createBulkSlots(@Body() dto: CreateBulkSlotsDto) {
    return this.slotsService.createBulkSlots(dto);
  }

  @Patch(':id')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.doctor)
  /**
   * PATCH /slots/:id
   * Requires JWT and role admin/doctor. Cập nhật trạng thái slot (block/unblock)
   */
  async updateSlot(
    @Param('id') id: string,
    @Body() dto: UpdateSlotDto,
  ) {
    return this.slotsService.updateSlot(id, dto);
  }

  @Patch(':id/capacity')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin)
  /**
   * PATCH /slots/:id/capacity
   * Requires JWT and role admin. Cập nhật sức chứa slot (updateSlotCapacity)
   */
  async updateSlotCapacity(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateSlotCapacityDto,
  ) {
    return this.slotsService.updateSlotCapacity(userId, id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.doctor)
  /**
   * DELETE /slots/:id
   * Requires JWT and role admin/doctor. Xóa slot theo id
   */
  async deleteSlot(@Param('id') id: string) {
    return this.slotsService.deleteSlot(id);
  }
}
