import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateClinicDto, UpdateClinicDto } from './dto/clinic.dto';

@Injectable()
export class ClinicsService {
  constructor(private prisma: PrismaService) {}

  async createClinic(dto: CreateClinicDto) {
    return this.prisma.clinic.create({
      data: dto,
      include: {
        doctors: {
          include: { doctor: true },
        },
        slots: true,
      },
    });
  }

  async getClinics() {
    return this.prisma.clinic.findMany({
      include: {
        doctors: {
          include: { doctor: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getClinicById(id: string) {
    const clinic = await this.prisma.clinic.findUnique({
      where: { id },
      include: {
        doctors: {
          include: { doctor: true },
        },
        slots: true,
      },
    });

    if (!clinic) throw new NotFoundException('Clinic not found');
    return clinic;
  }

  async updateClinic(id: string, dto: UpdateClinicDto) {
    await this.getClinicById(id);

    return this.prisma.clinic.update({
      where: { id },
      data: dto,
      include: {
        doctors: {
          include: { doctor: true },
        },
      },
    });
  }

  async deleteClinic(id: string) {
    await this.getClinicById(id);

    return this.prisma.clinic.delete({
      where: { id },
    });
  }
}
