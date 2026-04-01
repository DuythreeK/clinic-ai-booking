import { IsArray, IsOptional, IsString } from 'class-validator';

export class CreateAppointmentDto {
  @IsString()
  patientId!: string;

  @IsString()
  facilityId!: string;

  @IsString()
  serviceId!: string;

  @IsString()
  slotId!: string;

  @IsOptional()
  @IsString()
  appointmentType?: string;

  @IsString()
  appointmentDate!: string;

  @IsString()
  appointmentTime!: string;

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
  appointmentId!: string;
  patientId!: string;
  doctorId!: string;
  slotId!: string;
  status!: string;
  note?: string;
  createdAt!: Date;
  updatedAt!: Date;
}
