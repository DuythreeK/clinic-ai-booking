import {
  BadRequestException,
  Controller,
  Post,
  Body,
  HttpCode,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import {
  ForgotPasswordRequest,
  LoginRequest,
  RefreshTokenRequest,
  RegisterRequest,
  ResetPasswordRequest,
} from './dto/auth.dto';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { CurrentUser } from '@/common/decorators/current-user.decorator';

@Controller('auth')
@ApiTags('Auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('register')
  async register(@Body() registerDto: RegisterRequest) {
    return this.authService.register(registerDto);
  }

  @Post('login')
  @HttpCode(200)
  async login(@Body() loginDto: LoginRequest) {
    return this.authService.login(loginDto);
  }

  @Post('refresh')
  @HttpCode(200)
  async refresh(@Body() dto: RefreshTokenRequest) {
    if (!dto.refresh_token) {
      throw new BadRequestException('Refresh token is required');
    }
    return this.authService.refresh(dto.refresh_token);
  }

  @Post('forgot-password')
  @HttpCode(200)
  async forgotPassword(@Body() dto: ForgotPasswordRequest) {
    return this.authService.forgotPassword(dto);
  }

  @Post('reset-password')
  @HttpCode(200)
  async resetPassword(@Body() dto: ResetPasswordRequest) {
    return this.authService.resetPassword(dto);
  }

  @Post('logout')
  @UseGuards(JwtGuard)
  @HttpCode(200)
  async logout(@CurrentUser('sub') user_id: string) {
    return this.authService.logout(user_id);
  }
}
