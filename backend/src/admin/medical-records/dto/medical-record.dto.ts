import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsObject,
  IsOptional,
  IsString,
} from 'class-validator';
import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';

export class MedicalRecordListQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsString()
  patientId?: string;

  @IsOptional()
  @IsString()
  doctorId?: string;

  @IsOptional()
  @IsString()
  appointmentId?: string;

  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isLocked?: boolean;
}

export class CreateMedicalRecordDto {
  @IsString()
  appointmentId!: string;

  @IsString()
  diagnosis!: string;

  @IsOptional()
  @IsArray()
  icd10Codes?: string[];

  @IsOptional()
  @IsObject()
  vitalSigns?: Record<string, unknown>;

  @IsOptional()
  @IsString()
  treatmentPlan?: string;

  @IsOptional()
  @IsArray()
  prescription?: Record<string, unknown>[];

  @IsOptional()
  @IsString()
  followUpDate?: string;

  @IsOptional()
  @IsArray()
  attachments?: Record<string, unknown>[];
}

export class UpdateMedicalRecordDto {
  @IsOptional()
  @IsString()
  diagnosis?: string;

  @IsOptional()
  @IsArray()
  icd10Codes?: string[];

  @IsOptional()
  @IsObject()
  vitalSigns?: Record<string, unknown>;

  @IsOptional()
  @IsString()
  treatmentPlan?: string;

  @IsOptional()
  @IsArray()
  prescription?: Record<string, unknown>[];

  @IsOptional()
  @IsString()
  followUpDate?: string;

  @IsOptional()
  @IsArray()
  attachments?: Record<string, unknown>[];

  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isLocked?: boolean;
}
