import { IsNumber, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateDoctorDto {
  @IsString()
  @MaxLength(150)
  full_name!: string;

  @IsString()
  specialtyId!: string;

  @IsString()
  facility_id!: string;

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
  full_name?: string;

  @IsOptional()
  @IsString()
  specialtyId?: string;

  @IsOptional()
  @IsString()
  facility_id?: string;

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
