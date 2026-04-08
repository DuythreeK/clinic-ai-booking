import { IsArray, IsOptional, IsString } from 'class-validator';

export class CreateAppointmentDto {
  @IsString()
  patient_id!: string;

  @IsString()
  facility_id!: string;

  @IsString()
  service_id!: string;

  @IsString()
  slot_id!: string;

  @IsOptional()
  @IsString()
  appointmentType?: string;

  @IsString()
  appointment_date!: string;

  @IsString()
  appointment_time!: string;

  @IsString()
  @IsOptional()
  note?: string;

  @IsOptional()
  @IsString()
  symptomsNote?: string;

  @IsArray()
  @IsOptional()
  attachments?: unknown[];
}

export class UpdateAppointmentDto {
  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsString()
  symptomsNote?: string;
}

export class AppointmentResponseDto {
  appointment_id!: string;
  patient_id!: string;
  doctor_id!: string;
  slot_id!: string;
  status!: string;
  note?: string;
  created_at!: Date;
  updatedAt!: Date;
}
