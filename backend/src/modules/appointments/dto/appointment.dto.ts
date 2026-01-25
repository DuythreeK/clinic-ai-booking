import { IsString, IsOptional, IsArray } from 'class-validator';

export class CreateAppointmentDto {
  @IsString()
  slotId: string;

  @IsString()
  @IsOptional()
  reason?: string;

  @IsArray()
  @IsOptional()
  attachments?: string[];
}

export class UpdateAppointmentDto {
  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  doctorNotes?: string;

  @IsOptional()
  @IsString()
  doctorAdvice?: string;
}

export class AppointmentResponseDto {
  id: string;
  patientId: string;
  doctorId: string;
  slotId: string;
  status: string;
  reason?: string;
  createdAt: Date;
  updatedAt: Date;
}
