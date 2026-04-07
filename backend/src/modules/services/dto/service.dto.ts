import { IsDateString, IsOptional, IsString } from 'class-validator';

export class GetAvailableServiceSlotsDto {
  @IsOptional()
  @IsDateString()
  date?: string;

  @IsOptional()
  @IsDateString()
  fromDate?: string;

  @IsOptional()
  @IsDateString()
  toDate?: string;
}
