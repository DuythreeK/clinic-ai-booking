import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateDoctorReviewDto {
  @IsString()
  doctorId!: string;

  @IsOptional()
  @IsString()
  appointmentId?: string;

  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsOptional()
  @IsString()
  comment?: string;
}
