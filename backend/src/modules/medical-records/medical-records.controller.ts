import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { MedicalRecordsService } from './medical-records.service';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { CurrentUser } from '@/common/decorators/current-user.decorator';

@Controller('medical-records')
@UseGuards(JwtGuard)
export class MedicalRecordsController {
  constructor(private medicalRecordsService: MedicalRecordsService) {}

  @Get()
  async getMine(@CurrentUser('sub') userId: string) {
    return this.medicalRecordsService.getMyMedicalRecords(userId);
  }

  @Get(':id')
  async getById(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
  ) {
    return this.medicalRecordsService.getMedicalRecordById(userId, id);
  }
}
