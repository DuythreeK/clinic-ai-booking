import {
  IsString,
  IsOptional,
  IsInt,
  Min,
  Max,
  IsEnum,
  IsEmail,
  IsBoolean,
} from 'class-validator';
import { Type } from 'class-transformer';

// ─── Specialty ───────────────────────────────────────────────
export class CreateSpecialtyDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;
}

export class UpdateSpecialtyDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(1)
  is_active?: number;
}

// ─── Facility ─────────────────────────────────────────────────
export enum FacilityTypeEnum {
  hospital = 'hospital',
  clinic = 'clinic',
  vaccination_center = 'vaccination_center',
}

export class CreateFacilityDto {
  @IsString()
  name: string;

  @IsEnum(FacilityTypeEnum)
  facility_type: FacilityTypeEnum;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsString()
  address_detail: string;

  @IsOptional()
  @IsString()
  province?: string;

  @IsOptional()
  @IsString()
  district?: string;

  @IsOptional()
  @IsString()
  ward?: string;

  @IsOptional()
  @IsString()
  opening_hours?: string;
}

export class UpdateFacilityDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsEnum(FacilityTypeEnum)
  facility_type?: FacilityTypeEnum;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  address_detail?: string;

  @IsOptional()
  @IsString()
  province?: string;

  @IsOptional()
  @IsString()
  district?: string;

  @IsOptional()
  @IsString()
  ward?: string;

  @IsOptional()
  @IsString()
  opening_hours?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(1)
  is_active?: number;
}
