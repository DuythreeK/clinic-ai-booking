import { IsArray, IsIn, IsObject, IsOptional, IsString, MinLength } from 'class-validator';

export class TriageRequestDto {
  @IsString()
  @MinLength(3)
  symptoms!: string;

  @IsString()
  @IsOptional()
  duration?: string;

  @IsString()
  @IsOptional()
  severity?: string;

  @IsObject()
  @IsOptional()
  additionalInfo?: Record<string, any>;
}

export class TriageResultDto {
  @IsString()
  @IsIn(['Emergency', 'Urgent', 'Routine'])
  urgency!: 'Emergency' | 'Urgent' | 'Routine';

  @IsString()
  specialty!: string;

  @IsString()
  reasoning!: string;
}

export class PrevisitSummaryRequestDto {
  @IsObject()
  patientData!: Record<string, any>;

  @IsString()
  @IsOptional()
  appointmentId?: string;

  @IsOptional()
  @IsArray()
  previousAppointments?: any[];
}

export class PrevisitSummaryResultDto {
  summary!: string[];
  keyPoints!: string[];
  recommendations!: string[];
}
