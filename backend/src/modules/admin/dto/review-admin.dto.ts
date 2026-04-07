import { IsOptional, IsString, IsInt, Min, Max } from 'class-validator';

export class AdminReplyDto {
  @IsString()
  admin_reply: string;
}

export class ReviewVisibilityDto {
  @IsInt()
  @Min(0)
  @Max(1)
  is_visible: number;
}

export class ReviewListQueryDto {
  @IsOptional()
  @IsString()
  doctor_id?: string;

  @IsOptional()
  @IsString()
  is_visible?: string;

  @IsOptional()
  @IsString()
  page?: string;

  @IsOptional()
  @IsString()
  limit?: string;
}
