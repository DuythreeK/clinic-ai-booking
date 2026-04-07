import {
  IsString,
  IsOptional,
  IsInt,
  IsDateString,
  IsEnum,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateDoctorProfileDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsString()
  bio?: string;

  @IsOptional()
  @IsInt()
  experience_years?: number;

  @IsOptional()
  @IsString()
  avatar_url?: string;

  @IsOptional()
  consultation_fee?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  is_active?: number;
}

export class CreateSlotDto {
  @IsInt()
  @Type(() => Number)
  facility_id: number;

  @IsDateString()
  slot_date: string;

  @IsString()
  start_time: string; // HH:mm

  @IsString()
  end_time: string;   // HH:mm

  @IsOptional()
  @IsInt()
  @Min(1)
  duration_minutes?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  available_count?: number;
}

export class DoctorListQueryDto {
  @IsOptional()
  @IsString()
  specialty_id?: string;

  @IsOptional()
  @IsString()
  facility_id?: string;

  @IsOptional()
  @IsString()
  is_active?: string;

  @IsOptional()
  @IsString()
  page?: string;

  @IsOptional()
  @IsString()
  limit?: string;
}

export class SlotListQueryDto {
  @IsOptional()
  @IsDateString()
  from?: string;

  @IsOptional()
  @IsDateString()
  to?: string;
}
