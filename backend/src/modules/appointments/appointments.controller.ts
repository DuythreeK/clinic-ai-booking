import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  HttpCode,
} from '@nestjs/common';
import { AppointmentsService } from './appointments.service';
import { CreateAppointmentDto, UpdateAppointmentDto } from './dto/appointment.dto';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';

@Controller('appointments')
@UseGuards(JwtGuard, RolesGuard)
export class AppointmentsController {
  constructor(private appointmentsService: AppointmentsService) {}

  @Post()
  @Roles(UserRole.patient)
  async create(
    @CurrentUser('sub') patientId: string,
    @Body() dto: CreateAppointmentDto,
  ) {
    return this.appointmentsService.createAppointment(patientId, dto);
  }

  @Get('my')
  @Roles(UserRole.patient)
  async getMyAppointments(@CurrentUser('sub') patientId: string) {
    return this.appointmentsService.getMyAppointments(patientId);
  }

  @Get('doctor')
  @Roles(UserRole.doctor)
  async getDoctorAppointments(@CurrentUser('sub') doctorId: string) {
    return this.appointmentsService.getDoctorAppointments(doctorId);
  }

  @Patch(':id')
  @Roles(UserRole.patient, UserRole.doctor)
  async update(
    @Param('id') appointmentId: string,
    @CurrentUser('sub') userId: string,
    @CurrentUser('role') role: UserRole,
    @Body() dto: UpdateAppointmentDto,
  ) {
    return this.appointmentsService.updateAppointment(
      appointmentId,
      userId,
      role,
      dto,
    );
  }

  @Delete(':id')
  @HttpCode(200)
  @Roles(UserRole.patient, UserRole.doctor)
  async cancel(
    @Param('id') appointmentId: string,
    @CurrentUser('sub') userId: string,
    @CurrentUser('role') role: UserRole,
  ) {
    return this.appointmentsService.cancelAppointment(
      appointmentId,
      userId,
      role,
    );
  }
}
