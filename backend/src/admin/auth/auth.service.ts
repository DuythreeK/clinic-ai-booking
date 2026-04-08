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

    if (!user || user.status !== 'active') {
      throw new UnauthorizedException('Sai tai khoan hoac mat khau');
    }

    const passwordMatched = await bcrypt.compare(dto.password, user.password_hash);
    if (!passwordMatched) {
      throw new UnauthorizedException('Sai tai khoan hoac mat khau');
    }

    // lastLoginAt not in group schema, skipping update

    const accessToken = await this.jwtService.signAsync(
      {
        sub: user.user_id.toString(),
        role: user.role,
        fullName: user.full_name,
      } satisfies JwtPayload,
      {
        secret: process.env.JWT_SECRET,
        expiresIn: (process.env.JWT_EXPIRES_IN || '1d') as any,
      },
    );

    return {
      accessToken,
      user: sanitizeUser(user),
    };
  }

  async getProfile(userId: string) {
    try {
      const user = await this.prisma.user.findUnique({ where: { user_id: BigInt(userId) } });
      if (!user) {
        throw new UnauthorizedException('Tai khoan khong ton tai');
      }

      return sanitizeUser(user);
    } catch (error) {
      if (error instanceof SyntaxError) {
        throw new UnauthorizedException('Token khong hop le (vui long dang nhap lai)');
      }
      throw error;
    }
  }
}
