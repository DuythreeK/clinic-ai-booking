import { IsDateString, IsOptional } from 'class-validator';

export class DashboardOverviewQueryDto {
  @IsOptional()
  @IsDateString()
  from?: string;

  @IsOptional()
  @IsDateString()
  to?: string;
}
