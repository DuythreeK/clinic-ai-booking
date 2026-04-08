import { IsArray, IsBoolean, IsDateString, IsInt, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CreateSlotDto {
  @IsString()
  doctorId!: string;

  @IsString()
  clinicId!: string;

  @IsDateString()
  startAt!: string; // ISO string

  @IsDateString()
  endAt!: string; // ISO string

  @IsOptional()
  @IsBoolean()
  isBlocked?: boolean;
}

export class UpdateSlotDto {
  @IsOptional()
  @IsBoolean()
  isBlocked?: boolean;
}

export class UpdateSlotCapacityDto {
  @IsInt()
  @Min(0)
  newCapacity!: number;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  reason?: string;
}

export class CreateBulkSlotsDto {
  @IsString()
  doctorId!: string;

  @IsString()
  clinicId!: string;

  @IsDateString()
  startDate!: string; // YYYY-MM-DD

  @IsDateString()
  endDate!: string; // YYYY-MM-DD

  @IsString()
  startTime!: string; // HH:mm

  @IsString()
  endTime!: string; // HH:mm

  @IsInt()
  @Min(1)
  slotDuration!: number; // minutes (30, 60, etc)

  @IsArray()
  daysOfWeek!: number[]; // 0-6 (0=Sunday)
}
