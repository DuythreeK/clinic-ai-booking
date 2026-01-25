import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { UpdatePatientProfileDto } from './dto/patient.dto';

@Injectable()
export class PatientsService {
  constructor(private prisma: PrismaService) {}

  async createPatientProfile(userId: string) {
    return this.prisma.patientProfile.create({
      data: { userId },
      include: { user: true },
    });
  }

  async getPatientProfile(userId: string) {
    const profile = await this.prisma.patientProfile.findUnique({
      where: { userId },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            phone: true,
            avatar: true,
          },
        },
        appointments: {
          include: {
            doctor: {
              include: { user: true },
            },
          },
        },
      },
    });

    if (!profile) throw new NotFoundException('Patient profile not found');
    return profile;
  }

  async updatePatientProfile(userId: string, dto: UpdatePatientProfileDto) {
    return this.prisma.patientProfile.update({
      where: { userId },
      data: dto,
      include: {
        user: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            phone: true,
            avatar: true,
          },
        },
      },
    });
  }

  async deletePatientProfile(userId: string) {
    return this.prisma.patientProfile.delete({
      where: { userId },
    });
  }

  async getPatientById(id: string) {
    const profile = await this.prisma.patientProfile.findUnique({
      where: { id },
      include: {
        user: true,
        appointments: true,
      },
    });

    if (!profile) throw new NotFoundException('Patient not found');
    return profile;
  }

  async getAllPatients() {
    return this.prisma.patientProfile.findMany({
      include: {
        user: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            phone: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
