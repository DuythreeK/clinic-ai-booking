import { IsDateString, IsEnum, IsOptional, IsNumberString } from 'class-validator';

export enum StatPeriod {
  day = 'day',
  month = 'month',
  year = 'year',
}

export class StatsQueryDto {
  @IsOptional()
  @IsEnum(StatPeriod)
  period?: StatPeriod = StatPeriod.month;

  @IsOptional()
  @IsDateString()
  from?: string;

  @IsOptional()
  @IsDateString()
  to?: string;
}

export class SlotFillQueryDto extends StatsQueryDto {
  @IsOptional()
  @IsNumberString()
  facility_id?: string;
}
