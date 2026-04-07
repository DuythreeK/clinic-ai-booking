import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsOptional,
  IsString,
} from 'class-validator';
import { ApptStatus } from '@prisma/client';
import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';

export class AppointmentListQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsEnum(ApptStatus)
  status?: ApptStatus;

  @IsOptional()
  @IsString()
  patientId?: string;

  @IsOptional()
  @IsString()
  doctorId?: string;

  @IsOptional()
  @IsString()
  scheduleId?: string;

  @IsOptional()
  @IsString()
  fromDate?: string;

  @IsOptional()
  @IsString()
  toDate?: string;
}

export class CreateBookingDto {
  @IsString()
  patientId!: string;

  @IsString()
  scheduleId!: string;

  @IsOptional()
  @IsString()
  reason?: string;

  @IsOptional()
  @IsString()
  symptoms?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateAppointmentStatusDto {
  @IsEnum(ApptStatus)
  status!: ApptStatus;
}

export class CancelAppointmentDto {
  @IsString()
  cancelReason!: string;
}
