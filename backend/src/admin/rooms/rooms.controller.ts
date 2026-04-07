import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '@/common/decorators/roles.decorator';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { CreateRoomDto, RoomListQueryDto, UpdateRoomDto } from './dto/room.dto';
import { RoomsService } from './rooms.service';

@Controller('admin/rooms')
@UseGuards(JwtGuard, RolesGuard)
export class RoomsController {
  constructor(private readonly roomsService: RoomsService) {}

  @Get()
  @Roles(UserRole.admin, UserRole.receptionist, UserRole.doctor)
  findAll(@Query() query: RoomListQueryDto) {
    return this.roomsService.findAll(query);
  }

  @Get(':id')
  @Roles(UserRole.admin, UserRole.receptionist, UserRole.doctor)
  findOne(@Param('id') id: string) {
    return this.roomsService.findOne(id);
  }

  @Post()
  @Roles(UserRole.admin)
  create(@Body() dto: CreateRoomDto) {
    return this.roomsService.create(dto);
  }

  @Patch(':id')
  @Roles(UserRole.admin)
  update(@Param('id') id: string, @Body() dto: UpdateRoomDto) {
    return this.roomsService.update(id, dto);
  }
}
