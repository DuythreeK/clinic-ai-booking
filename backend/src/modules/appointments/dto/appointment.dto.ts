import { IsString, IsOptional, IsArray } from 'class-validator';

export class CreateAppointmentDto {
  @IsString()
  slot_id!: string;

  @IsString()
  @IsOptional()
  patient_id?: string;

  @IsString()
  @IsOptional()
  note?: string;

  @IsArray()
  @IsOptional()
  attachments?: unknown[];
}

export class UpdateAppointmentDto {
  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsString()
  symptoms_note?: string;
}

export class AppointmentResponseDto {
  appointment_id!: string;
  patient_id!: string;
  doctor_id!: string;
  slot_id!: string;
  status!: string;
  note?: string;
  created_at!: Date;
  updated_at!: Date;
}
