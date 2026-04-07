import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, Min } from 'class-validator';

export class UpdateNotificationSettingsDto {
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  pushEnabled?: boolean;

  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  soundEnabled?: boolean;

  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  appointmentReminder?: boolean;

  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  statusUpdates?: boolean;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  reminderLeadMinutes?: number;
}
