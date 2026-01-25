import { IsArray, IsString, IsOptional, IsObject } from 'class-validator';

export class TriageRequestDto {
  @IsArray()
  symptoms: string[];

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
  recommended_specialties: string[];
  urgency_level: 'THUONG' | 'NEN_DI_SOM' | 'KHAN';
  follow_up_questions: string[];
  disclaimer: string;
}

export class PrevisitSummaryRequestDto {
  @IsObject()
  patientData: Record<string, any>;

  @IsString()
  @IsOptional()
  appointmentId?: string;

  @IsOptional()
  @IsArray()
  previousAppointments?: any[];
}

export class PrevisitSummaryResultDto {
  summary: string[];
  keyPoints: string[];
  recommendations: string[];
}
