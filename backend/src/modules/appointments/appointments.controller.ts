import {
  Controller,
  Post,
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
    return this.appointmentsService.updateAppointment(id, dto);
  }

  @Patch(':id/status')
  @Roles(UserRole.ADMIN, UserRole.DOCTOR)
  async updateAppointmentStatus(
    @Param('id') id: string,
    @Body() dto: UpdateAppointmentStatusDto,
  ) {
    return this.appointmentsService.updateAppointmentStatus(id, dto);
  }

  @Patch(':id/notes')
  @Roles(UserRole.DOCTOR)
  async addDoctorNotes(
    @Param('id') id: string,
    @Body() dto: AddDoctorNotesDto,
  ) {
    return this.appointmentsService.addDoctorNotes(id, dto);
  }

  @Patch(':id/reschedule')
  @Roles(UserRole.PATIENT, UserRole.DOCTOR)
  async rescheduleAppointment(
    @Param('id') id: string,
    @Body() dto: RescheduleAppointmentDto,
  ) {
    return this.appointmentsService.rescheduleAppointment(id, dto);
  }

  @Patch(':id/cancel')
  @Roles(UserRole.PATIENT, UserRole.DOCTOR, UserRole.ADMIN)
  @HttpCode(200)
  async cancelAppointment(@Param('id') id: string) {
    return this.appointmentsService.cancelAppointment(id);
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

