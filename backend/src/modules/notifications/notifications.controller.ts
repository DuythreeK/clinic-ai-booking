import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { SaveFcmTokenDto } from './dto/notification.dto';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { CurrentUser } from '@/common/decorators/current-user.decorator';

@Controller('notifications')
@UseGuards(JwtGuard)
export class NotificationsController {
  constructor(private notificationsService: NotificationsService) {}

  @Post('fcm-token')
  async saveFcmToken(
    @CurrentUser('sub') userId: string,
    @Body() dto: SaveFcmTokenDto,
  ) {
    return this.notificationsService.saveFcmToken(userId, dto);
  }
}
