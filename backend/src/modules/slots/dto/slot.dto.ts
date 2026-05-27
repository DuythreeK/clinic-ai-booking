import { IsInt, Min, IsOptional, IsString, MaxLength } from 'class-validator';

// DTOs for slots API
// - CreateSlotDto: used for single slot creation (expects ISO timestamps)
// - UpdateSlotDto: minimal payload to mark blocked/unblocked
// - CreateBulkSlotsDto: input for bulk generation (not yet implemented fully)
// - UpdateSlotCapacityDto: payload validated for capacity changes (integer >= 0)
export class CreateSlotDto {
  doctor_id!: string;
  clinicId!: string;
  // ISO datetime strings expected (e.g. 2026-05-28T09:00:00Z)
  startAt!: string;
  endAt!: string;
  isBlocked?: boolean;
}

export class UpdateSlotDto {
  // If true => slot is inactive/blocked
  isBlocked?: boolean;
}

export class CreateBulkSlotsDto {
  // bulk creation inputs (service currently returns 'not implemented')
  doctor_id!: string;
  clinicId!: string;
  startDate!: string; // YYYY-MM-DD
  endDate!: string; // YYYY-MM-DD
  start_time!: string; // HH:mm
  end_time!: string; // HH:mm
  slotDuration!: number; // minutes
  daysOfWeek!: number[]; // 0-6 (0=Sunday)
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