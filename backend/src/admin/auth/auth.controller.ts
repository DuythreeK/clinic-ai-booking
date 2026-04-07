import { Body, Controller, Get, HttpCode, Post, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { Roles } from '@/common/decorators/roles.decorator';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/auth.dto';

@Controller('admin/auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @HttpCode(200)
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Get('me')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.receptionist, UserRole.doctor)
  getMe(@CurrentUser('sub') userId: string) {
    return this.authService.getProfile(userId);
  }

  @Post('logout')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.receptionist, UserRole.doctor)
  @HttpCode(200)
  logout() {
    return { message: 'Dang xuat thanh cong' };
  }
}
