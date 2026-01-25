import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateSpecialtyDto, UpdateSpecialtyDto } from './dto/specialty.dto';

@Injectable()
export class SpecialtiesService {
  constructor(private prisma: PrismaService) {}

  async createSpecialty(dto: CreateSpecialtyDto) {
    const existingSpecialty = await this.prisma.specialty.findUnique({
      where: { name: dto.name },
    });

    if (existingSpecialty) {
      throw new BadRequestException('Specialty with this name already exists');
    }

    return this.prisma.specialty.create({
      data: dto,
      include: { doctors: true },
    });
  }

  async getSpecialties() {
    return this.prisma.specialty.findMany({
      include: {
        doctors: {
          select: {
            id: true,
            user: {
              select: {
                firstName: true,
                lastName: true,
              },
            },
          },
        },
      },
      orderBy: { name: 'asc' },
    });
  }

  async getSpecialtyById(id: string) {
    const specialty = await this.prisma.specialty.findUnique({
      where: { id },
      include: {
        doctors: {
          include: {
            user: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                email: true,
              },
            },
          },
        },
      },
    });

    if (!specialty) throw new NotFoundException('Specialty not found');
    return specialty;
  }

  async updateSpecialty(id: string, dto: UpdateSpecialtyDto) {
    await this.getSpecialtyById(id);

    if (dto.name) {
      const existingSpecialty = await this.prisma.specialty.findUnique({
        where: { name: dto.name },
      });
      if (existingSpecialty && existingSpecialty.id !== id) {
        throw new BadRequestException('Specialty with this name already exists');
      }
    }

    return this.prisma.specialty.update({
      where: { id },
      data: dto,
      include: { doctors: true },
    });
  }

  async deleteSpecialty(id: string) {
    await this.getSpecialtyById(id);

    return this.prisma.specialty.delete({
      where: { id },
    });
  }
}
