import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '@/common/decorators/roles.decorator';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { DashboardOverviewQueryDto } from './dto/stats.dto';
import { StatsService } from './stats.service';

@Controller('admin/stats')
@UseGuards(JwtGuard, RolesGuard)
export class StatsController {
  constructor(private readonly statsService: StatsService) {}

  @Get('overview')
  @Roles(UserRole.admin, UserRole.receptionist, UserRole.doctor)
  getOverview(@Query() query: DashboardOverviewQueryDto) {
    return this.statsService.getOverview(query);
  }
}
