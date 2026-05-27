import { IsDateString, IsOptional, IsString, MaxLength } from 'class-validator';

// DTOs for mobile profile view/update. MobileProfileDto is a shaped response
// object (not used for validation), UpdateMobileProfileDto is validated input.
export class MobileProfileDto {
  user_id!: number;
  profileId!: number | null;
  ecoreId!: string;
  username!: string;
  full_name!: string;
  firstName!: string;
  lastName!: string;
  email!: string;
  phone!: string;
  dateOfBirth!: string | null;
  gender!: string | null;
  city!: string | null;
  district!: string | null;
  ward!: string | null;
  address!: string | null;
  occupation!: string | null;
  emergencyContact!: string | null;
  citizenId!: string | null;
  nationality!: string | null;
  ethnicity!: string | null;
  relationshipToUser!: string | null;
  avatarUrl!: string | null;
}

export class UpdateMobileProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(150)
  full_name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  phone?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  avatarUrl?: string;

  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;

  @IsOptional()
  @IsString()
  gender?: string;

  @IsOptional()
  @IsString()
  occupation?: string;

  @IsOptional()
  @IsString()
  nationality?: string;

  @IsOptional()
  @IsString()
  ethnicity?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  district?: string;

  @IsOptional()
  @IsString()
  ward?: string;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsString()
  emergencyContact?: string;

  @IsOptional()
  @IsString()
  relationshipToUser?: string;
}
