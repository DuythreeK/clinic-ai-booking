import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '@/common/decorators/roles.decorator';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import {
  CreateNotificationDto,
  NotificationListQueryDto,
  UpdateNotificationDto,
} from './dto/notification.dto';
import { NotificationsService } from './notifications.service';

@Controller('admin/notifications')
@UseGuards(JwtGuard, RolesGuard)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  @Roles(UserRole.admin, UserRole.receptionist, UserRole.doctor)
  findAll(@Query() query: NotificationListQueryDto) {
    return this.notificationsService.findAll(query);
  }

  @Get(':id')
  @Roles(UserRole.admin, UserRole.receptionist, UserRole.doctor)
  findOne(@Param('id') id: string) {
    return this.notificationsService.findOne(id);
  }

  @Post()
  @Roles(UserRole.admin, UserRole.receptionist)
  create(@Body() dto: CreateNotificationDto) {
    return this.notificationsService.create(dto);
  }

  @Patch(':id')
  @Roles(UserRole.admin, UserRole.receptionist)
  update(@Param('id') id: string, @Body() dto: UpdateNotificationDto) {
    return this.notificationsService.update(id, dto);
  }
}
