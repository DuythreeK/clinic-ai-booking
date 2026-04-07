import { IsOptional, IsString, IsInt, IsDateString, IsObject } from 'class-validator';
import { Type } from 'class-transformer';

export class UpsertMedicalRecordDto {
  @IsOptional()
  @IsString()
  symptoms?: string;

  @IsOptional()
  @IsString()
  diagnosis?: string;

  @IsOptional()
  @IsString()
  icd10_codes?: string;

  @IsOptional()
  @IsObject()
  vital_signs?: Record<string, any>;

  @IsOptional()
  @IsString()
  treatment_plan?: string;

  @IsOptional()
  @IsObject()
  prescription?: Record<string, any>;

  @IsOptional()
  @IsDateString()
  follow_up_date?: string;

  @IsOptional()
  @IsObject()
  attachments?: Record<string, any>;
}
