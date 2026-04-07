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
      id: toNumberId(user.user_id),
      fullName: user.full_name,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatar_url,
      status: user.status,
    };
  }

  async getUserById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { user_id: this.toBigIntId(id) },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return okResponse('Get current user successfully', this.toCurrentUserResponse(user));
  }

  async updateUser(id: string, dto: UpdateUserDto) {
    const existing = await this.prisma.user.findUnique({
      where: { user_id: this.toBigIntId(id) },
    });

    if (!existing) {
      throw new NotFoundException('User not found');
    }

    const user = await this.prisma.user.update({
      where: { user_id: this.toBigIntId(id) },
      data: {
        full_name: dto.fullName,
        phone: dto.phone,
        avatar_url: dto.avatarUrl,
      },
    });

    return okResponse('Update profile successfully', {
      id: toNumberId(user.user_id),
      fullName: user.full_name,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatar_url,
    });
  }
}
