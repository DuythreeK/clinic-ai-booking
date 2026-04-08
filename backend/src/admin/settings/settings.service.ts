import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { UpdateNotificationSettingsDto } from './dto/notification-settings.dto';

interface NotificationSettingsRecord {
  pushEnabled: boolean;
  soundEnabled: boolean;
  appointmentReminder: boolean;
  statusUpdates: boolean;
  reminderLeadMinutes: number;
}

@Injectable()
export class SettingsService {
  constructor(private readonly prisma: PrismaService) {}

  async getNotificationSettings(userId: string) {
    const settings = await this.prisma.adminNotificationSetting.upsert({
      where: { userId: BigInt(userId) },
      update: {},
      create: { userId: BigInt(userId) },
    });

    return this.toResponse(settings);
  }

  async updateNotificationSettings(
    userId: string,
    dto: UpdateNotificationSettingsDto,
  ) {
    const settings = await this.prisma.adminNotificationSetting.upsert({
      where: { userId: BigInt(userId) },
      update: {
        pushEnabled: dto.pushEnabled !== undefined ? (dto.pushEnabled ? 1 : 0) : undefined,
        soundEnabled: dto.soundEnabled !== undefined ? (dto.soundEnabled ? 1 : 0) : undefined,
        appointmentReminder: dto.appointmentReminder !== undefined ? (dto.appointmentReminder ? 1 : 0) : undefined,
        statusUpdates: dto.statusUpdates !== undefined ? (dto.statusUpdates ? 1 : 0) : undefined,
        reminderLeadMinutes: dto.reminderLeadMinutes,
      },
      create: {
        userId: BigInt(userId),
        pushEnabled: dto.pushEnabled ? 1 : 1, // Fallback to 1
        soundEnabled: dto.soundEnabled ? 1 : 1,
        appointmentReminder: dto.appointmentReminder ? 1 : 0,
        statusUpdates: dto.statusUpdates ? 1 : 1,
        reminderLeadMinutes: dto.reminderLeadMinutes ?? 30,
      },
    });

    return this.toResponse(settings as any);
  }

  private toResponse(settings: any) {
    return {
      pushEnabled: settings.pushEnabled === 1,
      soundEnabled: settings.soundEnabled === 1,
      appointmentReminder: settings.appointmentReminder === 1,
      statusUpdates: settings.statusUpdates === 1,
      reminderLeadMinutes: settings.reminderLeadMinutes,
    };
  }
}
