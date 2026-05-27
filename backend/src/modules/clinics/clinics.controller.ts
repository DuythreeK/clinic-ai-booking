/**
 * ClinicsController
 * - Cung cấp API cơ sở y tế/phòng khám cho mobile và web.
 * - Controller chỉ nhận request, phần lọc và phân trang để service xử lý.
 */
import { Controller, Get, Param, Query } from '@nestjs/common';
import { ClinicsService } from './clinics.service';

@Controller('facilities')
export class ClinicsController {
  constructor(private clinicsService: ClinicsService) {}

  // Danh sách phòng khám có phân trang cho màn danh mục.
  @Get()
  async getClinics(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('search') search?: string,
    @Query('facilityType') facilityType?: string,
  ) {
    return this.clinicsService.getClinics(
      Number(page || 1),
      Number(limit || 10),
      search,
      facilityType,
    );
  }

  // Danh sách rút gọn cho mobile.
  @Get('mobile')
  async getMobileFacilities(
    @Query('search') search?: string,
    @Query('facilityType') facilityType?: string,
  ) {
    return this.clinicsService.getMobileFacilities(search, facilityType);
  }

  // Lấy chi tiết phòng khám theo id.
  @Get(':id')
  async getClinicById(@Param('id') id: string) {
    return this.clinicsService.getClinicById(id);
  }
}
