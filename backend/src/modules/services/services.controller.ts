import { Controller, Get, Param, Query } from '@nestjs/common';
import { ServicesService } from './services.service';

@Controller('services')
export class ServicesController {
  constructor(private servicesService: ServicesService) {}

  @Get()
  /**
   * GET /services
   * Query: page, limit, facilityId, search
   * Trả danh sách service/gói (paginated)
   */
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

  @Get('mobile/vaccination-packages')
  /**
   * GET /services/mobile/vaccination-packages
   * Trả các gói tiêm chủng để hiển thị trên mobile
   */
  async getVaccinationPackages(
    @Query('search') search?: string,
    @Query('facilityId') facilityId?: string,
  ) {
    return this.servicesService.getVaccinationPackages(search, facilityId);
  }

  @Get(':id')
  /**
   * GET /services/:id
   * Trả chi tiết service theo id
   */
  async getServiceById(@Param('id') id: string) {
    return this.servicesService.getServiceById(id);
  }

  @Get(':id/mobile-vaccination-detail')
  /**
   * GET /services/:id/mobile-vaccination-detail
   * Query: date/fromDate/toDate
   * Trả chi tiết booking (service info + grouped slots) cho mobile
   */
  async getVaccinationBookingDetail(
    @Param('id') id: string,
    @Query('date') date?: string,
    @Query('fromDate') fromDate?: string,
    @Query('toDate') toDate?: string,
  ) {
    return this.servicesService.getVaccinationBookingDetail(
      id,
      date,
      fromDate,
      toDate,
    );
  }

  @Get(':id/available-slots')
  /**
   * GET /services/:id/available-slots
   * Trả slot khả dụng cho service
   */
  async getAvailableSlots(
    @Param('id') id: string,
    @Query('date') date?: string,
    @Query('fromDate') fromDate?: string,
    @Query('toDate') toDate?: string,
  ) {
    return this.servicesService.getAvailableSlots(id, date, fromDate, toDate);
  }
}
