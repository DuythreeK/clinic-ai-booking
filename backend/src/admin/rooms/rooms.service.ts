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
      specialty_id: query.specialtyId ? BigInt(query.specialtyId) : undefined,
      is_active: query.isActive !== undefined ? (query.isActive ? 1 : 0) : undefined,
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
        orderBy: { created_at: 'desc' },
      }),
      this.prisma.room.count({ where }),
    ]);

    const mappedItems = items.map((item) => ({
      ...item,
      id: item.room_id.toString(),
    }));

    return { data: mappedItems, meta: { page, limit, total } };
  }

  async findOne(id: string) {
    const room = await this.prisma.room.findUnique({
      where: { room_id: BigInt(id) },
      include: { specialty: true },
    });
    if (!room) {
      throw new NotFoundException('Khong tim thay phong');
    }

    return {
      ...room,
      id: room.room_id.toString(),
    };
  }

  async create(dto: CreateRoomDto) {
    await this.ensureRoomUniqueness(dto.code);
    await this.ensureSpecialtyExists(dto.specialtyId);

    return this.prisma.room.create({
      data: {
        name: dto.name,
        code: dto.code.toUpperCase(),
        specialty_id: dto.specialtyId ? BigInt(dto.specialtyId) : null,
        floor: dto.floor,
        is_active: dto.isActive !== false ? 1 : 0,
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
      where: { room_id: BigInt(id) },
      data: {
        name: dto.name,
        code: dto.code?.toUpperCase(),
        specialty_id:
          dto.specialtyId === null || dto.specialtyId === ''
            ? null
            : dto.specialtyId ? BigInt(dto.specialtyId) : undefined,
        floor: dto.floor,
        is_active: dto.isActive !== undefined ? (dto.isActive ? 1 : 0) : undefined,
      },
      include: { specialty: true },
    });
  }

  private async getRoomOrThrow(id: string): Promise<any> {
    const room = await this.prisma.room.findUnique({ where: { room_id: BigInt(id) } });
    if (!room) {
      throw new NotFoundException('Khong tim thay phong');
    }

    return room;
  }

  private async ensureSpecialtyExists(id?: string) {
    if (!id) {
      return;
    }

    const specialty = await this.prisma.specialty.findUnique({ where: { specialty_id: BigInt(id) } });
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
