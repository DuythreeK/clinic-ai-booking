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
    @CurrentUser('sub') user_id: string,
    @Body() dto: CreatePatientProfileDto,
  ) {
    return this.patientsService.createPatientProfile(user_id, dto);
  }

  @Get()
  async getMyProfiles(@CurrentUser('sub') user_id: string) {
    return this.patientsService.getPatientProfiles(user_id);
  }

  @Get('mobile')
  async getMyMobileProfiles(@CurrentUser('sub') user_id: string) {
    return this.patientsService.getMobilePatientProfiles(user_id);
  }
}
