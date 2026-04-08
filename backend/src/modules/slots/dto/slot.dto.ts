export class CreateSlotDto {
  doctor_id!: string;
  clinicId!: string;
  startAt!: string; // ISO string
  endAt!: string; // ISO string
  isBlocked?: boolean;
}

export class UpdateSlotDto {
  isBlocked?: boolean;
}

export class CreateBulkSlotsDto {
  doctor_id!: string;
  clinicId!: string;
  startDate!: string; // YYYY-MM-DD
  endDate!: string; // YYYY-MM-DD
  start_time!: string; // HH:mm
  end_time!: string; // HH:mm
  slotDuration!: number; // minutes (30, 60, etc)
  daysOfWeek!: number[]; // 0-6 (0=Sunday)
}
