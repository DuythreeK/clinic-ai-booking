import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { PatientsService } from './patients.service';
import { CreatePatientProfileDto, UpdatePatientProfileDto } from './dto/patient.dto';
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

  @Patch(':id')
  async updatePatientProfile(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdatePatientProfileDto,
  ) {
    return this.patientsService.updatePatientProfile(userId, id, dto);
  }

  @Delete(':id')
  async deletePatientProfile(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
  ) {
    return this.patientsService.deletePatientProfile(userId, id);
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
