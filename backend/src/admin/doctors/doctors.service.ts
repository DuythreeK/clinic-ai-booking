import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '@/prisma/prisma.service';
import { resolvePagination } from '../common/utils/pagination.util';
import { CreateDoctorDto, DoctorListQueryDto, UpdateDoctorDto } from './dto/doctor.dto';

@Injectable()
export class DoctorsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: DoctorListQueryDto) {
    const { skip, take, page, limit } = resolvePagination(query);
    const where: Prisma.DoctorWhereInput = {
      specialtyId: query.specialtyId,
      isActive: query.isActive,
      OR: query.search
        ? [
            { licenseNumber: { contains: query.search } },
            { user: { is: { fullName: { contains: query.search } } } },
            { user: { is: { phone: { contains: query.search } } } },
            { user: { is: { email: { contains: query.search } } } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.doctor.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          user: true,
          specialty: true,
        },
      }),
      this.prisma.doctor.count({ where }),
    ]);

    return { data: items, meta: { page, limit, total } };
  }

  async findOne(id: string) {
    const doctor = await this.prisma.doctor.findUnique({
      where: { id },
      include: {
        user: true,
        specialty: true,
      },
    });

    if (!doctor) {
      throw new NotFoundException('Khong tim thay bac si');
    }

    return doctor;
  }

  async create(dto: CreateDoctorDto) {
    await this.ensureSpecialtyExists(dto.specialtyId);
    await this.ensureDoctorUniqueness(dto.phone, dto.email, dto.licenseNumber);

    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          fullName: dto.fullName,
          phone: dto.phone,
          email: dto.email,
          passwordHash: await bcrypt.hash(dto.password, 10),
          role: UserRole.doctor,
          isActive: dto.isActive ?? true,
        },
      });

      const doctor = await tx.doctor.create({
        data: {
          userId: user.id,
          specialtyId: dto.specialtyId,
          title: dto.title ?? 'BS',
          licenseNumber: dto.licenseNumber,
          bio: dto.bio,
          yearsExperience: dto.yearsExperience ?? 0,
          consultationFee: dto.consultationFee ?? 0,
          isActive: dto.isActive ?? true,
        },
      });

      return tx.doctor.findUniqueOrThrow({
        where: { id: doctor.id },
        include: { user: true, specialty: true },
      });
    });
  }

  async update(id: string, dto: UpdateDoctorDto) {
    const doctor = await this.prisma.doctor.findUnique({
      where: { id },
      include: { user: true },
    });

    if (!doctor) {
      throw new NotFoundException('Khong tim thay bac si');
    }

    if (dto.specialtyId && dto.specialtyId !== doctor.specialtyId) {
      await this.ensureSpecialtyExists(dto.specialtyId);
    }

    if (dto.phone && dto.phone !== doctor.user.phone) {
      const existing = await this.prisma.user.findUnique({ where: { phone: dto.phone } });
      if (existing) {
        throw new BadRequestException('So dien thoai da ton tai');
      }
    }

    if (dto.email && dto.email !== doctor.user.email) {
      const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
      if (existing) {
        throw new BadRequestException('Email da ton tai');
      }
    }

    if (dto.licenseNumber && dto.licenseNumber !== doctor.licenseNumber) {
      const existing = await this.prisma.doctor.findUnique({
        where: { licenseNumber: dto.licenseNumber },
      });
      if (existing) {
        throw new BadRequestException('So chung chi da ton tai');
      }
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: doctor.userId },
        data: {
          fullName: dto.fullName,
          phone: dto.phone,
          email: dto.email,
          isActive: dto.isActive,
          passwordHash: dto.password
            ? await bcrypt.hash(dto.password, 10)
            : undefined,
        },
      });

      await tx.doctor.update({
        where: { id },
        data: {
          specialtyId: dto.specialtyId,
          title: dto.title,
          licenseNumber: dto.licenseNumber,
          bio: dto.bio,
          yearsExperience: dto.yearsExperience,
          consultationFee: dto.consultationFee,
          isActive: dto.isActive,
        },
      });
    });

    return this.findOne(id);
  }

  private async ensureSpecialtyExists(id: string) {
    const specialty = await this.prisma.specialty.findUnique({ where: { id } });
    if (!specialty) {
      throw new BadRequestException('Chuyen khoa khong ton tai');
    }
  }

  private async ensureDoctorUniqueness(
    phone: string,
    email: string | undefined,
    licenseNumber: string,
  ) {
    const [existingPhone, existingEmail, existingLicense] = await Promise.all([
      this.prisma.user.findUnique({ where: { phone } }),
      email ? this.prisma.user.findUnique({ where: { email } }) : null,
      this.prisma.doctor.findUnique({ where: { licenseNumber } }),
    ]);

    if (existingPhone) {
      throw new BadRequestException('So dien thoai da ton tai');
    }

    if (existingEmail) {
      throw new BadRequestException('Email da ton tai');
    }

    if (existingLicense) {
      throw new BadRequestException('So chung chi da ton tai');
    }
  }
}
