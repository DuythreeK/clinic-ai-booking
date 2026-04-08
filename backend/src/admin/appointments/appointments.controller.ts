import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '@/common/decorators/roles.decorator';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import {
  AppointmentListQueryDto,
  CancelAppointmentDto,
  CreateBookingDto,
  UpdateAppointmentStatusDto,
} from './dto/appointment.dto';
import { AppointmentsService } from './appointments.service';

@Controller('admin/appointments')
@UseGuards(JwtGuard, RolesGuard)
export class AppointmentsController {
  constructor(private readonly appointmentsService: AppointmentsService) {}

  @Get()
  @Roles(UserRole.admin, UserRole.doctor)
  findAll(@Query() query: AppointmentListQueryDto) {
    return this.appointmentsService.findAll(query);
  }

  @Get(':id')
  @Roles(UserRole.admin, UserRole.doctor)
  findOne(@Param('id') id: string) {
    return this.appointmentsService.findOne(id);
  }

  @Post()
  @Roles(UserRole.admin, )
  create(@Body() dto: CreateBookingDto) {
    return this.appointmentsService.createBooking(dto);
  }

  @Patch(':id/status')
  @Roles(UserRole.admin, )
  updateStatus(
    @Param('id') id: string,
    @Body() dto: UpdateAppointmentStatusDto,
  ) {
    return this.appointmentsService.updateStatus(id, dto);
  }

  @Patch(':id/cancel')
  @Roles(UserRole.admin, )
  cancel(@Param('id') id: string, @Body() dto: CancelAppointmentDto) {
    return this.appointmentsService.cancel(id, dto);
  }
}
