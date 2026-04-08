import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateDoctorReviewDto {
  @IsString()
  doctor_id!: string;

  @IsOptional()
  @IsString()
  appointment_id?: string;

  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsOptional()
  @IsString()
  comment?: string;
}
