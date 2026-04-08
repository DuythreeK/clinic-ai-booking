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
      specialty_id: query.specialtyId ? BigInt(query.specialtyId) : undefined,
      is_active: query.isActive !== undefined ? (query.isActive ? 1 : 0) : undefined,
      OR: query.search
        ? [
            { user: { is: { full_name: { contains: query.search } } } },
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
        orderBy: { created_at: 'desc' },
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
      where: { doctor_id: BigInt(id) },
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
          full_name: dto.fullName,
          phone: dto.phone,
          email: dto.email || `${dto.phone}@clinic.com`, // Fallback since schema requires email
          password_hash: await bcrypt.hash(dto.password, 10),
          role: UserRole.doctor,
          status: dto.isActive === false ? 'inactive' : 'active',
        },
      });

      const doctor = await tx.doctor.create({
        data: {
          user_id: user.user_id,
          full_name: dto.fullName,
          specialty_id: BigInt(dto.specialtyId),
          facility_id: BigInt(1), // TODO: Get actual facility_id
          title: dto.title ?? 'BS',
          bio: dto.bio,
          experience_years: dto.yearsExperience ?? 0,
          license_number: dto.licenseNumber,
          consultation_fee: new Prisma.Decimal(dto.consultationFee ?? 0),
          is_active: dto.isActive === false ? 0 : 1,
        },
      });

      return tx.doctor.findUniqueOrThrow({
        where: { doctor_id: doctor.doctor_id },
        include: { user: true, specialty: true },
      });
    });
  }

  async update(id: string, dto: UpdateDoctorDto) {
    const doctor = await this.prisma.doctor.findUnique({
      where: { doctor_id: BigInt(id) },
      include: { user: true },
    });

    if (!doctor) {
      throw new NotFoundException('Khong tim thay bac si');
    }

    if (dto.specialtyId && BigInt(dto.specialtyId) !== doctor.specialty_id) {
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

    if (dto.licenseNumber && dto.licenseNumber !== (doctor as any).license_number) {
      const existing = await this.prisma.doctor.findUnique({
        where: { license_number: dto.licenseNumber },
      });
      if (existing) {
        throw new BadRequestException('So chung chi da ton tai');
      }
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { user_id: doctor.user_id },
        data: {
          full_name: dto.fullName || undefined,
          phone: dto.phone || undefined,
          email: dto.email || undefined,
          status: dto.isActive !== undefined ? (dto.isActive ? 'active' : 'inactive') : undefined,
          password_hash: dto.password
            ? await bcrypt.hash(dto.password, 10)
            : undefined,
        },
      });

      await tx.doctor.update({
        where: { doctor_id: BigInt(id) },
        data: {
          specialty_id: dto.specialtyId ? BigInt(dto.specialtyId) : undefined,
          full_name: dto.fullName || undefined,
          title: dto.title || undefined,
          license_number: dto.licenseNumber || undefined,
          bio: dto.bio || undefined,
          experience_years: dto.yearsExperience !== undefined ? dto.yearsExperience : undefined,
          consultation_fee: dto.consultationFee !== undefined ? new Prisma.Decimal(dto.consultationFee) : undefined,
          is_active: dto.isActive !== undefined ? (dto.isActive ? 1 : 0) : undefined,
        },
      });
    });

    return this.findOne(id);
  }

  private async ensureSpecialtyExists(id: string) {
    const specialty = await this.prisma.specialty.findUnique({ where: { specialty_id: BigInt(id) } });
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
      this.prisma.doctor.findUnique({ where: { license_number: licenseNumber } }),
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
