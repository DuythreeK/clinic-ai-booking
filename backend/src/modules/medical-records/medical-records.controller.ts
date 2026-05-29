import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { MedicalRecordsService } from './medical-records.service';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { CurrentUser } from '@/common/decorators/current-user.decorator';

@Controller('medical-records')
@UseGuards(JwtGuard)
export class MedicalRecordsController {
  constructor(private medicalRecordsService: MedicalRecordsService) {}

  @Get()
  /**
   * GET /medical-records
   * Requires JWT. Trả danh sách medical records (history) của user
   */
  async getMine(@CurrentUser('sub') userId: string) {
    return this.medicalRecordsService.getMyMedicalRecords(userId);
  }

  @Get(':id')
  /**
   * GET /medical-records/:id
   * Requires JWT. Trả chi tiết medical record nếu thuộc user
   */
  async getById(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
  ) {
    return this.medicalRecordsService.getMedicalRecordById(userId, id);
  }
}
