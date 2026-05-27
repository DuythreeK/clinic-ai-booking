import { IsOptional, IsString, MaxLength } from 'class-validator';

// DTO dùng khi user cập nhật profile cơ bản từ mobile/web.
export class UpdateUserDto {
  @IsOptional()
  @IsString()
  @MaxLength(150)
  full_name?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  avatarUrl?: string;
}
