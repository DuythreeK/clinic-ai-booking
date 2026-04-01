import { IsNumber, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateDoctorDto {
  @IsString()
  @MaxLength(150)
  fullName!: string;

  @IsString()
  specialtyId!: string;

  @IsString()
  facilityId!: string;

  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsString()
  bio?: string;

  @IsOptional()
  @IsNumber()
  yearsExperience?: number;
}

export class UpdateDoctorDto {
  @IsOptional()
  @IsString()
  fullName?: string;

  @IsOptional()
  @IsString()
  specialtyId?: string;

  @IsOptional()
  @IsString()
  facilityId?: string;

  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsString()
  bio?: string;

  @IsOptional()
  @IsNumber()
  yearsExperience?: number;
}
