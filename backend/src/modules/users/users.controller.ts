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

  @Get('me')
  async getMyProfile(@CurrentUser('sub') userId: string) {
    return this.usersService.getUserById(userId);
  }

  @Get('me/profile')
  async getMyMobileProfile(@CurrentUser('sub') userId: string) {
    return this.usersService.getMobileProfile(userId);
  }

  @Patch('me')
  async updateMyProfile(
    @CurrentUser('sub') userId: string,
    @Body() dto: UpdateUserDto,
  ) {
    return this.usersService.updateUser(userId, dto);
  }

  @Patch('me/profile')
  async updateMyMobileProfile(
    @CurrentUser('sub') userId: string,
    @Body() dto: UpdateMobileProfileDto,
  ) {
    return this.usersService.updateMobileProfile(userId, dto);
  }
}
