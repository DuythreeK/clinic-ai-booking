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
import { CreateSlotDto, UpdateSlotDto, CreateBulkSlotsDto } from './dto/slot.dto';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@Controller('slots')
export class SlotsController {
  constructor(private slotsService: SlotsService) {}

  @Get()
  async getSlots(
    @Query('doctor_id') doctor_id?: string,
    @Query('clinicId') clinicId?: string,
    @Query('fromDate') fromDate?: string,
    @Query('toDate') toDate?: string,
  ) {
    return this.slotsService.getSlots(doctor_id, clinicId, fromDate, toDate);
  }

  @Get('available')
  async getAvailableSlots(
    @Query('doctor_id') doctor_id: string,
    @Query('clinicId') clinicId: string,
    @Query('fromDate') fromDate: string,
    @Query('toDate') toDate: string,
  ) {
    return this.slotsService.getAvailableSlots(doctor_id, clinicId, fromDate, toDate);
  }

  @Get(':id')
  async getSlotById(@Param('id') id: string) {
    return this.slotsService.getSlotById(id);
  }

  @Post()
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.doctor)
  async createSlot(@Body() dto: CreateSlotDto) {
    return this.slotsService.createSlot(dto);
  }

  @Post('bulk')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.doctor)
  async createBulkSlots(@Body() dto: CreateBulkSlotsDto) {
    return this.slotsService.createBulkSlots(dto);
  }

  @Patch(':id')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.doctor)
  async updateSlot(
    @Param('id') id: string,
    @Body() dto: UpdateSlotDto,
  ) {
    return this.slotsService.updateSlot(id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.doctor)
  async deleteSlot(@Param('id') id: string) {
    return this.slotsService.deleteSlot(id);
  }
}
