import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { UpdateUserDto } from './dto/user.dto';
import { okResponse } from '@/common/utils/api-response';
import { toNumberId } from '@/common/utils/formatters';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  private toBigIntId(id: string): bigint {
    return BigInt(id);
  }

  private toCurrentUserResponse(user: any) {
    return {
      id: toNumberId(user.userId),
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatar_url,
      status: user.status,
    };
  }

  async getUserById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { userId: this.toBigIntId(id) },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return okResponse('Get current user successfully', this.toCurrentUserResponse(user));
  }

  async updateUser(id: string, dto: UpdateUserDto) {
    const existing = await this.prisma.user.findUnique({
      where: { userId: this.toBigIntId(id) },
    });

    if (!existing) {
      throw new NotFoundException('User not found');
    }

    const user = await this.prisma.user.update({
      where: { userId: this.toBigIntId(id) },
      data: {
        fullName: dto.fullName,
        phone: dto.phone,
        avatar_url: dto.avatarUrl,
      },
    });

    return okResponse('Update profile successfully', {
      id: toNumberId(user.userId),
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatar_url,
    });
  }
}
