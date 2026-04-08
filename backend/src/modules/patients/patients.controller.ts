import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { PatientsService } from './patients.service';
import { CreatePatientProfileDto } from './dto/patient.dto';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { CurrentUser } from '@/common/decorators/current-user.decorator';

@Controller('patient-profiles')
@UseGuards(JwtGuard)
export class PatientsController {
  constructor(private patientsService: PatientsService) {}

  @Post()
  async createPatientProfile(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreatePatientProfileDto,
  ) {
    return this.patientsService.createPatientProfile(userId, dto);
  }

  @Get()
  async getMyProfiles(@CurrentUser('sub') userId: string) {
    return this.patientsService.getPatientProfiles(userId);
  }

  @Get('mobile')
  async getMyMobileProfiles(@CurrentUser('sub') userId: string) {
    return this.patientsService.getMobilePatientProfiles(userId);
  }
}
