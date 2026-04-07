import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { Roles } from '@/common/decorators/roles.decorator';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { UpdateNotificationSettingsDto } from './dto/notification-settings.dto';
import { SettingsService } from './settings.service';

@Controller('admin/settings')
@UseGuards(JwtGuard, RolesGuard)
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  @Get('notifications')
  @Roles(UserRole.admin, UserRole.receptionist, UserRole.doctor)
  getNotificationSettings(@CurrentUser('sub') userId: string) {
    return this.settingsService.getNotificationSettings(userId);
  }

  @Patch('notifications')
  @Roles(UserRole.admin, UserRole.receptionist, UserRole.doctor)
  updateNotificationSettings(
    @CurrentUser('sub') userId: string,
    @Body() dto: UpdateNotificationSettingsDto,
  ) {
    return this.settingsService.updateNotificationSettings(userId, dto);
  }
}
