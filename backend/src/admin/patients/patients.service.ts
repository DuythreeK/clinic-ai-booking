import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, Patient } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { parseDateOnly } from '../common/utils/date.util';
import { resolvePagination } from '../common/utils/pagination.util';
import { CreatePatientDto, PatientListQueryDto, UpdatePatientDto } from './dto/patient.dto';

@Injectable()
export class PatientsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: PatientListQueryDto) {
    const { skip, take, page, limit } = resolvePagination(query);
    const where: Prisma.PatientWhereInput = {
      isActive: query.isActive,
      OR: query.search
        ? [
            { fullName: { contains: query.search } },
            { phone: { contains: query.search } },
            { email: { contains: query.search } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.patient.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.patient.count({ where }),
    ]);

    return { data: items, meta: { page, limit, total } };
  }

  async findOne(id: string) {
    const patient = await this.prisma.patient.findUnique({ where: { id } });
    if (!patient) {
      throw new NotFoundException('Khong tim thay benh nhan');
    }

    return patient;
  }

  async create(dto: CreatePatientDto) {
    await this.ensurePatientUniqueness(dto.phone, dto.email);

    return this.prisma.patient.create({
      data: {
        fullName: dto.fullName,
        phone: dto.phone,
        email: dto.email,
        dob: dto.dob ? parseDateOnly(dto.dob) : undefined,
        gender: dto.gender,
        address: dto.address,
        bloodType: dto.bloodType,
        insuranceNumber: dto.insuranceNumber,
        allergies: dto.allergies,
        isActive: dto.isActive ?? true,
      },
    });
  }

  async update(id: string, dto: UpdatePatientDto) {
    const patient = await this.getPatientOrThrow(id);

    if (dto.phone && dto.phone !== patient.phone) {
      const existing = await this.prisma.patient.findUnique({ where: { phone: dto.phone } });
      if (existing) {
        throw new BadRequestException('So dien thoai da ton tai');
      }
    }

    if (dto.email && dto.email !== patient.email) {
      const existing = await this.prisma.patient.findUnique({ where: { email: dto.email } });
      if (existing) {
        throw new BadRequestException('Email da ton tai');
      }
    }

    return this.prisma.patient.update({
      where: { id },
      data: {
        fullName: dto.fullName,
        phone: dto.phone,
        email: dto.email,
        dob: dto.dob ? parseDateOnly(dto.dob) : undefined,
        gender: dto.gender,
        address: dto.address,
        bloodType: dto.bloodType,
        insuranceNumber: dto.insuranceNumber,
        allergies: dto.allergies,
        isActive: dto.isActive,
      },
    });
  }

  private async getPatientOrThrow(id: string): Promise<Patient> {
    const patient = await this.prisma.patient.findUnique({ where: { id } });
    if (!patient) {
      throw new NotFoundException('Khong tim thay benh nhan');
    }

    return patient;
  }

  private async ensurePatientUniqueness(phone: string, email?: string) {
    const [existingPhone, existingEmail] = await Promise.all([
      this.prisma.patient.findUnique({ where: { phone } }),
      email ? this.prisma.patient.findUnique({ where: { email } }) : null,
    ]);

    if (existingPhone) {
      throw new BadRequestException('So dien thoai da ton tai');
    }

    if (existingEmail) {
      throw new BadRequestException('Email da ton tai');
    }
  }
}
