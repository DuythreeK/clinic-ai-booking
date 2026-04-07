import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '@/prisma/prisma.service';
import { LoginDto } from './dto/auth.dto';
import { sanitizeUser } from '../common/utils/auth.util';

interface JwtPayload {
  sub: string;
  role: UserRole;
  fullName: string;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { email: dto.identifier },
          { phone: dto.identifier },
        ],
      },
    });

    if (!user || !user.isActive) {
      throw new UnauthorizedException('Sai tai khoan hoac mat khau');
    }

    const passwordMatched = await bcrypt.compare(dto.password, user.passwordHash);
    if (!passwordMatched) {
      throw new UnauthorizedException('Sai tai khoan hoac mat khau');
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    const accessToken = await this.jwtService.signAsync(
      {
        sub: user.id,
        role: user.role,
        fullName: user.fullName,
      } satisfies JwtPayload,
      {
        secret: process.env.JWT_SECRET,
        expiresIn: (process.env.JWT_EXPIRES_IN || '1d') as any,
      },
    );

    return {
      accessToken,
      user: sanitizeUser({ ...user, lastLoginAt: new Date() }),
    };
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new UnauthorizedException('Tai khoan khong ton tai');
    }

    return sanitizeUser(user);
  }
}
