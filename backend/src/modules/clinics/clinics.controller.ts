import { Controller, Get, Param, Query } from '@nestjs/common';
import { ClinicsService } from './clinics.service';

@Controller('facilities')
export class ClinicsController {
  constructor(private clinicsService: ClinicsService) {}

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

  @Get('mobile')
  async getMobileFacilities(
    @Query('search') search?: string,
    @Query('facilityType') facilityType?: string,
  ) {
    return this.clinicsService.getMobileFacilities(search, facilityType);
  }

  @Get(':id')
  async getClinicById(@Param('id') id: string) {
    return this.clinicsService.getClinicById(id);
  }
}
