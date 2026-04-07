import { Controller, Get, Param, Query } from '@nestjs/common';
import { ServicesService } from './services.service';

@Controller('services')
export class ServicesController {
  constructor(private servicesService: ServicesService) {}

  @Get()
  async getServices(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('facilityId') facilityId?: string,
    @Query('search') search?: string,
  ) {
    return this.servicesService.getServices(
      Number(page || 1),
      Number(limit || 10),
      facilityId,
      search,
    );
  }

  @Get(':id')
  async getServiceById(@Param('id') id: string) {
    return this.servicesService.getServiceById(id);
  }

  @Get(':id/available-slots')
  async getAvailableSlots(
    @Param('id') id: string,
    @Query('date') date?: string,
    @Query('fromDate') fromDate?: string,
    @Query('toDate') toDate?: string,
  ) {
    return this.servicesService.getAvailableSlots(id, date, fromDate, toDate);
  }
}
