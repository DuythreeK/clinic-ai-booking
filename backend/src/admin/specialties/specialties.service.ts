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
      isActive: query.isActive !== undefined ? (query.isActive ? 1 : 0) : undefined,
      OR: query.search
        ? [
            { name: { contains: query.search } },
            { description: { contains: query.search } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.specialty.findMany({
        where,
        skip,
        take,
        orderBy: [{ name: 'asc' }],
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
    return this.prisma.specialty.create({
      data: {
        name: dto.name,
        description: dto.description,
        isActive: 1,
      },
    });
  }

  async update(id: string, dto: UpdateSpecialtyDto) {
    const specialty = await this.getById(id);

    if (dto.name && dto.name !== specialty.name) {
      const existing = await this.prisma.specialty.findFirst({
        where: { name: dto.name },
      });
      if (existing) {
        throw new BadRequestException('Ten chuyen khoa da ton tai');
      }
    }

    return this.prisma.specialty.update({
      where: { specialty_id: BigInt(id) },
      data: {
        name: dto.name,
        description: dto.description,
        isActive: dto.isActive !== undefined ? (dto.isActive ? 1 : 0) : undefined,
      },
    });
  }

  private async getById(id: string) {
    const specialty = await this.prisma.specialty.findUnique({
      where: { specialty_id: BigInt(id) },
      include: {
        doctors: { include: { user: true } },
      },
    });
    if (!specialty) {
      throw new NotFoundException('Khong tim thay chuyen khoa');
    }

    return specialty;
  }
}
