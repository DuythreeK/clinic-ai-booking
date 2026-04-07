import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '@/prisma/prisma.service';
import { sanitizeUser } from '../common/utils/auth.util';
import { resolvePagination } from '../common/utils/pagination.util';
import { CreateUserDto, UpdateUserDto, UserListQueryDto } from './dto/user.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: UserListQueryDto) {
    const { skip, take, page, limit } = resolvePagination(query);
    const where: Prisma.UserWhereInput = {
      role: query.role,
      isActive: query.isActive,
      OR: query.search
        ? [
            { fullName: { contains: query.search } },
            { phone: { contains: query.search } },
            { email: { contains: query.search } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      data: items.map(sanitizeUser),
      meta: { page, limit, total },
    };
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new NotFoundException('Khong tim thay nguoi dung');
    }

    return sanitizeUser(user);
  }

  async create(dto: CreateUserDto) {
    if (dto.role === UserRole.doctor) {
      throw new BadRequestException('Tao bac si qua module doctors');
    }

    await this.ensureEmailPhoneAvailable(dto.email, dto.phone);

    const user = await this.prisma.user.create({
      data: {
        fullName: dto.fullName,
        phone: dto.phone,
        email: dto.email,
        passwordHash: await bcrypt.hash(dto.password, 10),
        role: dto.role,
        isActive: dto.isActive ?? true,
      },
    });

    return sanitizeUser(user);
  }

  async update(id: string, dto: UpdateUserDto) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new NotFoundException('Khong tim thay nguoi dung');
    }

    if (dto.role === UserRole.doctor) {
      throw new BadRequestException('Khong doi role sang doctor o module users');
    }

    if (dto.email && dto.email !== user.email) {
      const existingEmail = await this.prisma.user.findUnique({
        where: { email: dto.email },
      });
      if (existingEmail) {
        throw new BadRequestException('Email da ton tai');
      }
    }

    if (dto.phone && dto.phone !== user.phone) {
      const existingPhone = await this.prisma.user.findUnique({
        where: { phone: dto.phone },
      });
      if (existingPhone) {
        throw new BadRequestException('So dien thoai da ton tai');
      }
    }

    const updated = await this.prisma.user.update({
      where: { id },
      data: {
        fullName: dto.fullName,
        phone: dto.phone,
        email: dto.email,
        role: dto.role,
        isActive: dto.isActive,
        passwordHash: dto.password
          ? await bcrypt.hash(dto.password, 10)
          : undefined,
      },
    });

    return sanitizeUser(updated);
  }

  private async ensureEmailPhoneAvailable(
    email: string | undefined,
    phone: string,
  ) {
    const [existingPhone, existingEmail] = await Promise.all([
      this.prisma.user.findUnique({ where: { phone } }),
      email ? this.prisma.user.findUnique({ where: { email } }) : null,
    ]);

    if (existingPhone) {
      throw new BadRequestException('So dien thoai da ton tai');
    }

    if (existingEmail) {
      throw new BadRequestException('Email da ton tai');
    }
  }
}
