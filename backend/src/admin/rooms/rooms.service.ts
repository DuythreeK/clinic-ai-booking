import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, Room } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { resolvePagination } from '../common/utils/pagination.util';
import { CreateRoomDto, RoomListQueryDto, UpdateRoomDto } from './dto/room.dto';

@Injectable()
export class RoomsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: RoomListQueryDto) {
    const { skip, take, page, limit } = resolvePagination(query);
    const where: Prisma.RoomWhereInput = {
      specialtyId: query.specialtyId,
      isActive: query.isActive,
      OR: query.search
        ? [
            { name: { contains: query.search } },
            { code: { contains: query.search } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.room.findMany({
        where,
        skip,
        take,
        include: { specialty: true },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.room.count({ where }),
    ]);

    return { data: items, meta: { page, limit, total } };
  }

  async findOne(id: string) {
    const room = await this.prisma.room.findUnique({
      where: { id },
      include: { specialty: true },
    });
    if (!room) {
      throw new NotFoundException('Khong tim thay phong');
    }

    return room;
  }

  async create(dto: CreateRoomDto) {
    await this.ensureRoomUniqueness(dto.code);
    await this.ensureSpecialtyExists(dto.specialtyId);

    return this.prisma.room.create({
      data: {
        name: dto.name,
        code: dto.code.toUpperCase(),
        specialtyId: dto.specialtyId,
        floor: dto.floor,
        isActive: dto.isActive ?? true,
      },
      include: { specialty: true },
    });
  }

  async update(id: string, dto: UpdateRoomDto) {
    const room = await this.getRoomOrThrow(id);
    if (dto.code && dto.code.toUpperCase() !== room.code) {
      await this.ensureRoomUniqueness(dto.code);
    }

    if (dto.specialtyId !== undefined) {
      await this.ensureSpecialtyExists(dto.specialtyId || undefined);
    }

    return this.prisma.room.update({
      where: { id },
      data: {
        name: dto.name,
        code: dto.code?.toUpperCase(),
        specialtyId:
          dto.specialtyId === null || dto.specialtyId === ''
            ? null
            : dto.specialtyId,
        floor: dto.floor,
        isActive: dto.isActive,
      },
      include: { specialty: true },
    });
  }

  private async getRoomOrThrow(id: string): Promise<Room> {
    const room = await this.prisma.room.findUnique({ where: { id } });
    if (!room) {
      throw new NotFoundException('Khong tim thay phong');
    }

    return room;
  }

  private async ensureSpecialtyExists(id?: string) {
    if (!id) {
      return;
    }

    const specialty = await this.prisma.specialty.findUnique({ where: { id } });
    if (!specialty) {
      throw new BadRequestException('Chuyen khoa khong ton tai');
    }
  }

  private async ensureRoomUniqueness(code: string) {
    const existing = await this.prisma.room.findUnique({
      where: { code: code.toUpperCase() },
    });
    if (existing) {
      throw new BadRequestException('Ma phong da ton tai');
    }
  }
}
