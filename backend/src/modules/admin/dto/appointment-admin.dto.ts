import { IsEnum, IsOptional, IsString, IsDateString, IsNumberString } from 'class-validator';

export enum AppointmentStatusEnum {
  pending = 'pending',
  confirmed = 'confirmed',
  completed = 'completed',
  cancelled = 'cancelled',
  no_show = 'no_show',
}

export enum ChangerRoleEnum {
  admin = 'admin',
  receptionist = 'receptionist',
  doctor = 'doctor',
  patient = 'patient',
}

export class UpdateAppointmentStatusDto {
  @IsEnum(AppointmentStatusEnum)
  status: AppointmentStatusEnum;

  @IsOptional()
  @IsEnum(ChangerRoleEnum)
  changed_by_role?: ChangerRoleEnum = ChangerRoleEnum.admin;

  @IsOptional()
  @IsString()
  reason?: string;
}

export class AppointmentListQueryDto {
  @IsOptional()
  @IsDateString()
  date?: string;

  @IsOptional()
  @IsEnum(AppointmentStatusEnum)
  status?: AppointmentStatusEnum;

  @IsOptional()
  @IsNumberString()
  doctor_id?: string;

  @IsOptional()
  @IsNumberString()
  facility_id?: string;

  @IsOptional()
  @IsNumberString()
  page?: string;

  @IsOptional()
  @IsNumberString()
  limit?: string;
}
