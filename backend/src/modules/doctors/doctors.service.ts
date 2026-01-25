import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateDoctorDto, UpdateDoctorDto, ApproveDoctorDto } from './dto/doctor.dto';

@Injectable()
export class DoctorsService {
  constructor(private prisma: PrismaService) {}

  async createDoctor(userId: string, dto: CreateDoctorDto) {
    const existingLicense = await this.prisma.doctor.findUnique({
      where: { licenseNumber: dto.licenseNumber },
    });
    if (existingLicense) {
      throw new BadRequestException('License number already in use');
    }

    return this.prisma.doctor.create({
      data: {
        userId,
        licenseNumber: dto.licenseNumber,
        specialtyId: dto.specialtyId,
        bio: dto.bio,
        yearsExperience: dto.yearsExperience || 0,
      },
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
        specialty: true,
        doctorClinics: {
          include: { clinic: true },
        },
      },
    });
  }

  async getDoctors(specialtyId?: string, isApproved?: boolean) {
    const where: any = {};
    if (specialtyId) where.specialtyId = specialtyId;
    if (isApproved !== undefined) where.isApproved = isApproved;

    return this.prisma.doctor.findMany({
      where,
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
        specialty: true,
        doctorClinics: {
          include: { clinic: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getDoctorById(id: string) {
    const doctor = await this.prisma.doctor.findUnique({
      where: { id },
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
        specialty: true,
        doctorClinics: {
          include: { clinic: true },
        },
        slots: true,
      },
    });

    if (!doctor) throw new NotFoundException('Doctor not found');
    return doctor;
  }

  async getDoctorByUserId(userId: string) {
    const doctor = await this.prisma.doctor.findUnique({
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
        specialty: true,
        doctorClinics: {
          include: { clinic: true },
        },
      },
    });

    if (!doctor) throw new NotFoundException('Doctor profile not found');
    return doctor;
  }

  async updateDoctor(id: string, dto: UpdateDoctorDto) {
    const doctor = await this.getDoctorById(id);

    if (dto.licenseNumber && dto.licenseNumber !== doctor.licenseNumber) {
      const existingLicense = await this.prisma.doctor.findUnique({
        where: { licenseNumber: dto.licenseNumber },
      });
      if (existingLicense) {
        throw new BadRequestException('License number already in use');
      }
    }

    return this.prisma.doctor.update({
      where: { id },
      data: {
        licenseNumber: dto.licenseNumber,
        specialtyId: dto.specialtyId,
        bio: dto.bio,
        yearsExperience: dto.yearsExperience,
      },
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
        specialty: true,
        doctorClinics: {
          include: { clinic: true },
        },
      },
    });
  }

  async approveDoctor(id: string, dto: ApproveDoctorDto) {
    const doctor = await this.getDoctorById(id);

    return this.prisma.doctor.update({
      where: { id },
      data: { isApproved: dto.isApproved },
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
        specialty: true,
      },
    });
  }

  async deleteDoctor(id: string) {
    await this.getDoctorById(id);
    return this.prisma.doctor.delete({
      where: { id },
    });
  }

  async getDoctorsByClinic(clinicId: string) {
    return this.prisma.doctor.findMany({
      where: {
        doctorClinics: {
          some: { clinicId },
        },
      },
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
        specialty: true,
      },
    });
  }
}
