import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '@/prisma/prisma.service';
import {
  ForgotPasswordRequest,
  LoginRequest,
  RegisterRequest,
  ResetPasswordRequest,
} from './dto/auth.dto';
import { PasswordResetStatus, UserRole, UserStatus } from '@prisma/client';

interface JwtPayload {
  sub: string;
  email: string;
  role: UserRole;
}

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async register(dto: RegisterRequest) {
      const existingUser = await this.prisma.user.findFirst({
        where: {
          OR: [{ email: dto.email }, { phone: dto.phone }],
        },
      });

      if (existingUser) {
        const duplicateField =
          existingUser.email === dto.email ? 'email' : 'phone';
        throw new ConflictException(
          `User with this ${duplicateField} already exists`,
        );
      }

      const hashedPassword = await bcrypt.hash(dto.password, 10);

      // Sử dụng $transaction để đảm bảo tạo User và Profile đồng thời
      const result = await this.prisma.$transaction(async (tx) => {
        // 1. Tạo User
        const user = await tx.user.create({
          data: {
            role: dto.role,
            full_name: dto.full_name,
            email: dto.email,
            phone: dto.phone,
            password_hash: hashedPassword,
            status: UserStatus.active,
          },
        });

        // 2. Nếu role là patient, tạo ngay PatientProfile mặc định
        if (user.role === UserRole.patient) {
          await tx.patientProfile.create({
            data: {
              user_id: user.user_id,
              full_name: user.full_name,
              phone_number: user.phone,
              email: user.email,
              relationship_to_user: 'Bản thân',
              is_primary: 1, // Đánh dấu là hồ sơ chính
            },
          });
        }

        return user;
      });

      return {
        success: true,
        data: {
          user_id: result.user_id.toString(),
          email: result.email,
          full_name: result.full_name,
          role: result.role,
          status: result.status,
        },
      };
    }

  async login(dto: LoginRequest) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },

      /* select: {
              user_id: true,
              email: true,
              password_hash: true,
              role: true,
              status: true,
      }, */
    });

    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }

    if (user.status !== UserStatus.active) {
      throw new UnauthorizedException('Account is not active');
    }

    const passwordMatch = await bcrypt.compare(dto.password, user.password_hash);
    if (!passwordMatch) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const tokens = await this.generateTokens(user.user_id, user.email, user.role);

    return {
      success: true,
      data: {
        user_id: user.user_id.toString(),
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        token_type: 'Bearer',
        expires_in: this.getAccessTokenTtlSeconds(),
      },
    };
  }

  async refresh(refreshToken: string) {
    let payload: JwtPayload;

    try {
      payload = await this.jwtService.verifyAsync<JwtPayload>(refreshToken, {
        secret: process.env.JWT_REFRESH_SECRET,
      });
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const user_id = this.toBigIntId(payload.sub);

    const tokenRecord = await this.prisma.refreshToken.findFirst({
      where: {
        token: refreshToken,
        user_id: user_id,
        is_revoked: 0,
      },
    });

    if (!tokenRecord) {
      throw new UnauthorizedException('Token revoked or invalid');
    }

    if (tokenRecord.expires_at <= new Date()) {
      await this.prisma.refreshToken.update({
        where: { id: tokenRecord.id },
        data: { is_revoked: 1 },
      });
      throw new UnauthorizedException('Refresh token has expired');
    }

    const user = await this.prisma.user.findUnique({
      where: { user_id: user_id },
      select: {
        user_id: true,
        email: true,
        role: true,
        status: true,
      },
    });

    if (!user || user.status !== UserStatus.active) {
      throw new UnauthorizedException('User not found or inactive');
    }

    await this.prisma.refreshToken.update({
      where: { id: tokenRecord.id },
      data: { is_revoked: 1 },
    });

    const newTokens = await this.generateTokens(user.user_id, user.email, user.role);

    return {
      success: true,
      data: {
        access_token: newTokens.access_token,
        refresh_token: newTokens.refresh_token,
        expires_in: this.getAccessTokenTtlSeconds(),
      },
    };
  }

  async forgotPassword(dto: ForgotPasswordRequest) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
      select: {
        user_id: true,
        email: true,
      },
    });

    if (!user) {
      throw new NotFoundException('Email not found');
    }

    const resetToken = this.createPasswordResetToken();
    const expires_at = new Date(Date.now() + 15 * 60 * 1000);

    await this.prisma.passwordResetToken.create({
      data: {
        user_id: user.user_id,
        token: resetToken,
        status: PasswordResetStatus.PENDING,
        expires_at: expires_at,
      },
    });

    return {
      success: true,
      message: 'OTP sent to registered email/phone',
      data: {
        masked_email: this.maskEmail(user.email),
        retry_after: 60,
      },
    };
  }

  async resetPassword(dto: ResetPasswordRequest) {
    const tokenRecord = await this.prisma.passwordResetToken.findUnique({
      where: { token: dto.token },
      include: {
        user: {
          select: {
            user_id: true,
          },
        },
      },
    });

    if (!tokenRecord) {
      throw new NotFoundException('Token not found');
    }

    if (tokenRecord.status !== PasswordResetStatus.PENDING) {
      throw new UnauthorizedException('Invalid or expired token');
    }

    if (tokenRecord.expires_at <= new Date()) {
      await this.prisma.passwordResetToken.update({
        where: { id: tokenRecord.id },
        data: { status: PasswordResetStatus.EXPIRED },
      });
      throw new UnauthorizedException('Invalid or expired token');
    }

    const passwordHash = await bcrypt.hash(dto.new_password, 10);

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { user_id: tokenRecord.user.user_id },
        data: { password_hash: passwordHash },
      }),
      this.prisma.passwordResetToken.update({
        where: { id: tokenRecord.id },
        data: {
          status: PasswordResetStatus.USED,
          used_at: new Date(),
        },
      }),
    ]);

    return {
      success: true,
      message: 'Password reset successfully',
    };
  }

  async logout(user_id: string) {
    const parseduser_id = this.toBigIntId(user_id);

    await this.prisma.refreshToken.updateMany({
      where: {
        user_id: parseduser_id,
        is_revoked: 0,
      },
      data: {
        is_revoked: 1,
      },
    });

    return { success: true, message: 'Logout successful' };
  }

  private async generateTokens(
    user_id: bigint,
    email: string,
    role: UserRole,
  ) {
    const payload: JwtPayload = {
      sub: user_id.toString(),
      email,
      role,
    };

    const access_token = this.jwtService.sign(payload, {
      secret: process.env.JWT_SECRET,
      expiresIn: this.getAccessTokenTtlSeconds(),
    });

    const refresh_token = this.jwtService.sign(payload, {
      secret: process.env.JWT_REFRESH_SECRET,
      expiresIn: this.durationToSeconds(process.env.JWT_REFRESH_EXPIRES_IN || '7d'),
    });

    const expires_at = new Date(Date.now() + this.getRefreshTokenTtlMs());

    await this.prisma.refreshToken.create({
      data: {
        user_id: user_id,
        token: refresh_token,
        expires_at,
        is_revoked: 0,
      },
    });

    return {
      access_token,
      refresh_token,
    };
  }

  private createPasswordResetToken(): string {
    // Numeric OTP-like token for simple manual verification workflows.
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  private maskEmail(email: string): string {
    const [name, domain] = email.split('@');
    if (!name || !domain) {
      return email;
    }
    if (name.length <= 2) {
      return `${name[0] || '*'}***@${domain}`;
    }
    return `${name.slice(0, 2)}***@${domain}`;
  }

  private toBigIntId(user_id: string): bigint {
    try {
      return BigInt(user_id);
    } catch {
      throw new BadRequestException('Invalid user id format');
    }
  }

  private getAccessTokenTtlSeconds(): number {
    return this.durationToSeconds(process.env.JWT_EXPIRES_IN || '15m');
  }

  private getRefreshTokenTtlMs(): number {
    return this.durationToSeconds(process.env.JWT_REFRESH_EXPIRES_IN || '7d') * 1000;
  }

  private durationToSeconds(value: string): number {
    const match = value.trim().match(/^(\d+)([smhd]?)$/i);
    if (!match) {
      return 900;
    }

    const amount = Number(match[1]);
    const unit = (match[2] || 's').toLowerCase();

    if (unit === 's') {
      return amount;
    }
    if (unit === 'm') {
      return amount * 60;
    }
    if (unit === 'h') {
      return amount * 3600;
    }
    if (unit === 'd') {
      return amount * 86400;
    }

    return 900;
  }
}
