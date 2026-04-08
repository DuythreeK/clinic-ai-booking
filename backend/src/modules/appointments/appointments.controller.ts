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
  async create(
    @CurrentUser('sub') user_id: string,
    @Body() dto: CreateAppointmentDto,
  ) {
    return this.appointmentsService.createAppointment(user_id, dto);
  }

  @Get()
  async getUserAppointments(@CurrentUser('sub') user_id: string) {
    return this.appointmentsService.getUserAppointments(user_id);
  }

  @Get(':id')
  async getById(
    @CurrentUser('sub') user_id: string,
    @Param('id') appointment_id: string,
  ) {
    return this.appointmentsService.getAppointmentById(user_id, appointment_id);
  }
}

