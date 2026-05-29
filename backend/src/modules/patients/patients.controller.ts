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
  /**
   * POST /patient-profiles
   * Requires JWT. Tạo hồ sơ bệnh nhân cho user
   */
  async createPatientProfile(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreatePatientProfileDto,
  ) {
    return this.patientsService.createPatientProfile(userId, dto);
  }

  @Patch(':id')
  /**
   * PATCH /patient-profiles/:id
   * Requires JWT. Cập nhật hồ sơ bệnh nhân (kiểm tra quyền sở hữu)
   */
  async updatePatientProfile(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdatePatientProfileDto,
  ) {
    return this.patientsService.updatePatientProfile(userId, id, dto);
  }

  @Delete(':id')
  /**
   * DELETE /patient-profiles/:id
   * Requires JWT. Xóa hồ sơ bệnh nhân (nếu là primary sẽ promote hồ sơ khác)
   */
  async deletePatientProfile(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
  ) {
    return this.patientsService.deletePatientProfile(userId, id);
  }

  @Get()
  /**
   * GET /patient-profiles
   * Requires JWT. Lấy danh sách hồ sơ bệnh nhân của user
   */
  async getMyProfiles(@CurrentUser('sub') userId: string) {
    return this.patientsService.getPatientProfiles(userId);
  }

  @Get('mobile')
  /**
   * GET /patient-profiles/mobile
   * Requires JWT. Phiên bản format-friendly cho mobile
   */
  async getMyMobileProfiles(@CurrentUser('sub') userId: string) {
    return this.patientsService.getMobilePatientProfiles(userId);
  }
}
