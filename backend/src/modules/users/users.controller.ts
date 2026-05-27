/**
 * UsersController
 * - Cung cấp các API cho user đã đăng nhập xem và cập nhật hồ sơ.
 * - Tất cả route đều được bảo vệ bằng `JwtGuard` ở cấp controller.
 */
import {
  Body,
  Controller,
  Get,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { UpdateUserDto } from './dto/user.dto';
import { UpdateMobileProfileDto } from './dto/mobile-profile.dto';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { CurrentUser } from '@/common/decorators/current-user.decorator';

@Controller('users')
@UseGuards(JwtGuard)
export class UsersController {
  constructor(private usersService: UsersService) {}

  // Lấy hồ sơ cơ bản của user đang đăng nhập.
  @Get('me')
  async getMyProfile(@CurrentUser('sub') user_id: string) {
    return this.usersService.getUserById(user_id);
  }

  // Lấy hồ sơ mobile đầy đủ hơn.
  @Get('me/profile')
  async getMyMobileProfile(@CurrentUser('sub') user_id: string) {
    return this.usersService.getMobileProfile(user_id);
  }

  // Cập nhật hồ sơ cơ bản.
  @Patch('me')
  async updateMyProfile(
    @CurrentUser('sub') user_id: string,
    @Body() dto: UpdateUserDto,
  ) {
    return this.usersService.updateUser(user_id, dto);
  }

  // Cập nhật hồ sơ mobile, gồm cả thông tin bệnh nhân.
  @Patch('me/profile')
  async updateMyMobileProfile(
    @CurrentUser('sub') user_id: string,
    @Body() dto: UpdateMobileProfileDto,
  ) {
    return this.usersService.updateMobileProfile(user_id, dto);
  }
}
