import {
  Controller,
  Get,
  Patch,
  Delete,
  Body,
  UseGuards,
  Param,
} from '@nestjs/common';
import { PatientsService } from './patients.service';
import { UpdatePatientProfileDto } from './dto/patient.dto';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';

@Controller('patients')
@UseGuards(JwtGuard)
export class PatientsController {
  constructor(private patientsService: PatientsService) {}

  @Get('profile')
  @Roles(UserRole.PATIENT)
  async getMyProfile(@CurrentUser('sub') userId: string) {
    return this.patientsService.getPatientProfile(userId);
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  async getAllPatients() {
    return this.patientsService.getAllPatients();
  }

  @Get(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  async getPatientById(@Param('id') id: string) {
    return this.patientsService.getPatientById(id);
  }

  @Patch('profile')
  @Roles(UserRole.PATIENT)
  async updateMyProfile(
    @CurrentUser('sub') userId: string,
    @Body() dto: UpdatePatientProfileDto,
  ) {
    return this.patientsService.updatePatientProfile(userId, dto);
  }

  @Delete('profile')
  @Roles(UserRole.PATIENT)
  async deleteMyProfile(@CurrentUser('sub') userId: string) {
    return this.patientsService.deletePatientProfile(userId);
  }
}
