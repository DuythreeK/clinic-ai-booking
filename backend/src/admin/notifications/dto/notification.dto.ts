import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
} from 'class-validator';
import { NotifType } from '@prisma/client';
import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';
import { toBoolean } from '../../common/dto/transformers';

export class NotificationListQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsString()
  patientId?: string;

  @IsOptional()
  @IsString()
  appointmentId?: string;

  @IsOptional()
  @IsEnum(NotifType)
  type?: NotifType;

  @IsOptional()
  @Transform(({ value }) => toBoolean(value))
  @IsBoolean()
  isRead?: boolean;

  @IsOptional()
  @Transform(({ value }) => toBoolean(value))
  @IsBoolean()
  isSent?: boolean;
}

export class CreateNotificationDto {
  @IsString()
  patientId!: string;

  @IsOptional()
  @IsString()
  appointmentId?: string;

  @IsOptional()
  @IsEnum(NotifType)
  type?: NotifType;

  @IsString()
  title!: string;

  @IsString()
  message!: string;

  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isSent?: boolean;
}

export class UpdateNotificationDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsString()
  message?: string;

  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isRead?: boolean;

  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isSent?: boolean;
}
