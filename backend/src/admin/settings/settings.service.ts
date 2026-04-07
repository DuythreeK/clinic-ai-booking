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
      where: { userId },
      update: {},
      create: { userId },
    });

    return this.toResponse(settings);
  }

  async updateNotificationSettings(
    userId: string,
    dto: UpdateNotificationSettingsDto,
  ) {
    const settings = await this.prisma.adminNotificationSetting.upsert({
      where: { userId },
      update: {
        pushEnabled: dto.pushEnabled,
        soundEnabled: dto.soundEnabled,
        appointmentReminder: dto.appointmentReminder,
        statusUpdates: dto.statusUpdates,
        reminderLeadMinutes: dto.reminderLeadMinutes,
      },
      create: {
        userId,
        pushEnabled: dto.pushEnabled ?? true,
        soundEnabled: dto.soundEnabled ?? true,
        appointmentReminder: dto.appointmentReminder ?? false,
        statusUpdates: dto.statusUpdates ?? true,
        reminderLeadMinutes: dto.reminderLeadMinutes ?? 30,
      },
    });

    return this.toResponse(settings);
  }

  private toResponse(settings: NotificationSettingsRecord) {
    return {
      pushEnabled: settings.pushEnabled,
      soundEnabled: settings.soundEnabled,
      appointmentReminder: settings.appointmentReminder,
      statusUpdates: settings.statusUpdates,
      reminderLeadMinutes: settings.reminderLeadMinutes,
    };
  }
}
