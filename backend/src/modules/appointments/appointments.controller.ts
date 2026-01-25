import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
} from '@nestjs/common';
import { AppointmentsService } from './appointments.service';
import {
  CreateAppointmentDto,
  UpdateAppointmentDto,
  UpdateAppointmentStatusDto,
  AddDoctorNotesDto,
  RescheduleAppointmentDto,
  AppointmentFilterDto,
} from './dto/appointment.dto';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';

@Controller('appointments')
@UseGuards(JwtGuard, RolesGuard)
export class AppointmentsController {
  constructor(private appointmentsService: AppointmentsService) {}

  @Get()
  @Roles(UserRole.ADMIN, UserRole.DOCTOR)
  async getAppointments(
    @Query('patientId') patientId?: string,
    @Query('doctorId') doctorId?: string,
    @Query('status') status?: string,
    @Query('fromDate') fromDate?: string,
    @Query('toDate') toDate?: string,
  ) {
    const filter: AppointmentFilterDto = {
      patientId,
      doctorId,
      status,
      fromDate,
      toDate,
    };
    return this.appointmentsService.getAppointments(filter);
  }

  @Get('patient/my-appointments')
  @Roles(UserRole.PATIENT)
  async getMyAppointments(
    @CurrentUser('sub') userId: string,
    @Query('status') status?: string,
  ) {
    return this.appointmentsService.getPatientAppointments(userId, status);
  }

  @Get('doctor/my-appointments')
  @Roles(UserRole.DOCTOR)
  async getMyDoctorAppointments(
    @CurrentUser('sub') userId: string,
    @Query('status') status?: string,
  ) {
    return this.appointmentsService.getDoctorAppointments(userId, status);
  }

  @Get(':id')
  async getAppointmentById(@Param('id') id: string) {
    return this.appointmentsService.getAppointmentById(id);
  }

  @Post()
  @Roles(UserRole.PATIENT)
  async createAppointment(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateAppointmentDto,
  ) {
    return this.appointmentsService.createAppointment(dto.patientId, dto);
  }

  @Patch(':id')
  @Roles(UserRole.PATIENT)
  async updateAppointment(
    @Param('id') id: string,
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
  @Roles(UserRole.ADMIN)
  async deleteAppointment(@Param('id') id: string) {
    return this.appointmentsService.deleteAppointment(id);
  }
}

