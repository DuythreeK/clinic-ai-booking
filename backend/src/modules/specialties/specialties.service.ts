import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateSpecialtyDto, UpdateSpecialtyDto } from './dto/specialty.dto';

@Injectable()
export class SpecialtiesService {
  constructor(private prisma: PrismaService) {}

  private toBigIntId(id: string): bigint {
    return BigInt(id);
  }

  async createSpecialty(dto: CreateSpecialtyDto) {
    const existingSpecialty = await this.prisma.specialty.findUnique({
      where: { name: dto.name },
    });

    if (existingSpecialty) {
      throw new BadRequestException('Specialty with this name already exists');
    }

    return this.prisma.specialty.create({
      data: {
        name: dto.name,
        description: dto.description,
      },
    });
  }

  async getSpecialties() {
    return this.prisma.specialty.findMany({
      where: { is_active: 1 },
      orderBy: { name: 'asc' },
    });
  }

  async getSpecialtyById(id: string) {
    const specialty = await this.prisma.specialty.findUnique({
      where: { specialty_id: this.toBigIntId(id) },
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
      if (
        existingSpecialty &&
        existingSpecialty.specialty_id !== this.toBigIntId(id)
      ) {
        throw new BadRequestException('Specialty with this name already exists');
      }
    }

    return this.prisma.specialty.update({
      where: { specialty_id: this.toBigIntId(id) },
      data: {
        name: dto.name,
        description: dto.description,
      },
    });
  }

  async deleteSpecialty(id: string) {
    await this.getSpecialtyById(id);

    return this.prisma.specialty.delete({
      where: { specialty_id: this.toBigIntId(id) },
    });
  }
}
