import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { MedicalRecordsService } from './medical-records.service';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { CurrentUser } from '@/common/decorators/current-user.decorator';

@Controller('medical-records')
@UseGuards(JwtGuard)
export class MedicalRecordsController {
  constructor(private medicalRecordsService: MedicalRecordsService) {}

  @Get()
  async getMine(@CurrentUser('sub') user_id: string) {
    return this.medicalRecordsService.getMyMedicalRecords(user_id);
  }

  @Get(':id')
  async getById(
    @CurrentUser('sub') user_id: string,
    @Param('id') id: string,
  ) {
    return this.medicalRecordsService.getMedicalRecordById(user_id, id);
  }
}
