import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
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
  /**
   * POST /appointments
   * Requires JWT (patient). Tạo appointment (đặt lịch)
   * Body: CreateAppointmentDto (patientId, slotId, facilityId, serviceId...)
   */
  async create(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateAppointmentDto,
  ) {
    return this.appointmentsService.createAppointment(userId, dto);
  }

  @Get()
  /**
   * GET /appointments
   * Requires JWT. Trả danh sách appointment của user
   */
  async getUserAppointments(@CurrentUser('sub') userId: string) {
    return this.appointmentsService.getUserAppointments(userId);
  }

  @Get(':id')
  /**
   * GET /appointments/:id
   * Requires JWT. Trả chi tiết appointment nếu thuộc user
   */
  async getById(
    @CurrentUser('sub') userId: string,
    @Param('id') appointmentId: string,
  ) {
    return this.appointmentsService.getAppointmentById(userId, appointmentId);
  }
}

