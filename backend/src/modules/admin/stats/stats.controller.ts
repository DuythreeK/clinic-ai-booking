import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { StatsService } from './stats.service';
import { StatsQueryDto, SlotFillQueryDto } from '../dto/stats.dto';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { AdminRolesGuard } from '../guards/admin-roles.guard';

@UseGuards(JwtGuard, AdminRolesGuard)
@Controller('admin/stats')
export class StatsController {
  constructor(private readonly statsService: StatsService) {}

  /** GET /admin/stats/overview */
  @Get('overview')
  getOverview(@Query() query: StatsQueryDto) {
    return this.statsService.getOverview(query);
  }

  /** GET /admin/stats/revenue?period=month&from=2026-01-01&to=2026-03-31 */
  @Get('revenue')
  getRevenue(@Query() query: StatsQueryDto) {
    return this.statsService.getRevenue(query);
  }

  /** GET /admin/stats/doctor-performance */
  @Get('doctor-performance')
  getDoctorPerformance(@Query() query: StatsQueryDto) {
    return this.statsService.getDoctorPerformance(query);
  }

  /** GET /admin/stats/slot-fill-rate?facility_id=1 */
  @Get('slot-fill-rate')
  getSlotFillRate(@Query() query: SlotFillQueryDto) {
    return this.statsService.getSlotFillRate(query);
  }

  /** GET /admin/stats/patient-analysis */
  @Get('patient-analysis')
  getPatientAnalysis(@Query() query: StatsQueryDto) {
    return this.statsService.getPatientAnalysis(query);
  }
}
