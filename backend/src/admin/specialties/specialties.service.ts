import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, Specialty } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { resolvePagination } from '../common/utils/pagination.util';
import {
  CreateSpecialtyDto,
  SpecialtyListQueryDto,
  UpdateSpecialtyDto,
} from './dto/specialty.dto';

@Injectable()
export class SpecialtiesService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: SpecialtyListQueryDto) {
    const { skip, take, page, limit } = resolvePagination(query);
    const where: Prisma.SpecialtyWhereInput = {
      isActive: query.isActive,
      OR: query.search
        ? [
            { name: { contains: query.search } },
            { code: { contains: query.search } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.specialty.findMany({
        where,
        skip,
        take,
        orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
        include: {
          doctors: { include: { user: true } },
        },
      }),
      this.prisma.specialty.count({ where }),
    ]);

    return { data: items, meta: { page, limit, total } };
  }

  async findOne(id: string) {
    const specialty = await this.getById(id);
    return specialty;
  }

  async create(dto: CreateSpecialtyDto) {
    await this.ensureUnique(dto.code, dto.name);

    return this.prisma.specialty.create({
      data: {
        name: dto.name,
        code: dto.code.toUpperCase(),
        description: dto.description,
        sortOrder: dto.sortOrder ?? 0,
      },
    });
  }

  async update(id: string, dto: UpdateSpecialtyDto) {
    const specialty = await this.getById(id);

    if (dto.code && dto.code.toUpperCase() !== specialty.code) {
      const existing = await this.prisma.specialty.findUnique({
        where: { code: dto.code.toUpperCase() },
      });
      if (existing) {
        throw new BadRequestException('Ma chuyen khoa da ton tai');
      }
    }

    if (dto.name && dto.name !== specialty.name) {
      const existing = await this.prisma.specialty.findFirst({
        where: { name: dto.name },
      });
      if (existing) {
        throw new BadRequestException('Ten chuyen khoa da ton tai');
      }
    }

    return this.prisma.specialty.update({
      where: { id },
      data: {
        name: dto.name,
        code: dto.code?.toUpperCase(),
        description: dto.description,
        sortOrder: dto.sortOrder,
        isActive: dto.isActive,
      },
    });
  }

  private async getById(id: string) {
    const specialty = await this.prisma.specialty.findUnique({
      where: { id },
      include: {
        doctors: { include: { user: true } },
      },
    });
    if (!specialty) {
      throw new NotFoundException('Khong tim thay chuyen khoa');
    }

    return specialty;
  }

  private async ensureUnique(code: string, name: string) {
    const [existingCode, existingName] = await Promise.all([
      this.prisma.specialty.findUnique({ where: { code: code.toUpperCase() } }),
      this.prisma.specialty.findFirst({ where: { name } }),
    ]);

    if (existingCode) {
      throw new BadRequestException('Ma chuyen khoa da ton tai');
    }

    if (existingName) {
      throw new BadRequestException('Ten chuyen khoa da ton tai');
    }
  }
}
