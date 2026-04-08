import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, PatientProfile } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { parseDateOnly } from '../common/utils/date.util';
import { resolvePagination } from '../common/utils/pagination.util';
import { CreatePatientDto, PatientListQueryDto, UpdatePatientDto } from './dto/patient.dto';

@Injectable()
export class PatientsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: PatientListQueryDto) {
    const { skip, take, page, limit } = resolvePagination(query);
    const where: Prisma.PatientProfileWhereInput = {
      is_primary: query.isActive !== undefined ? (query.isActive ? 1 : 0) : undefined, // Mapping isActive to is_primary or similar if needed, adjusting based on Group schema
      OR: query.search
        ? [
            { full_name: { contains: query.search } },
            { phone_number: { contains: query.search } },
            { email: { contains: query.search } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.patientProfile.findMany({
        where,
        skip,
        take,
        orderBy: { created_at: 'desc' },
      }),
      this.prisma.patientProfile.count({ where }),
    ]);

    return { data: items, meta: { page, limit, total } };
  }

  async findOne(id: string) {
    const patient = await this.prisma.patientProfile.findUnique({ where: { patient_id: BigInt(id) } });
    if (!patient) {
      throw new NotFoundException('Khong tim thay benh nhan');
    }

    return patient;
  }

  async create(dto: CreatePatientDto) {
    // Note: In Group schema, patient_profile requires user_id. 
    // This logic might need adjustment if creating a patient without a user.
    // Assuming for now we use a dummy user_id or provided one if available.
    
    return this.prisma.patientProfile.create({
      data: {
        user_id: BigInt(1), // TODO: Get actual user_id
        full_name: dto.fullName,
        phone_number: dto.phone,
        email: dto.email,
        date_of_birth: dto.dob ? parseDateOnly(dto.dob) : undefined,
        gender: dto.gender,
        address_detail: dto.address,
        blood_type: dto.bloodType,
        insurance_number: dto.insuranceNumber,
        allergies: dto.allergies,
        is_primary: dto.isActive ? 1 : 0,
      },
    });
  }

  async update(id: string, dto: UpdatePatientDto) {
    const patient = await this.getPatientOrThrow(id);

    return this.prisma.patientProfile.update({
      where: { patient_id: BigInt(id) },
      data: {
        full_name: dto.fullName,
        phone_number: dto.phone,
        email: dto.email,
        date_of_birth: dto.dob ? parseDateOnly(dto.dob) : undefined,
        gender: dto.gender,
        address_detail: dto.address,
        blood_type: dto.bloodType,
        insurance_number: dto.insuranceNumber,
        allergies: dto.allergies,
        is_primary: dto.isActive !== undefined ? (dto.isActive ? 1 : 0) : undefined,
      },
    });
  }

  private async getPatientOrThrow(id: string): Promise<PatientProfile> {
    const patient = await this.prisma.patientProfile.findUnique({ where: { patient_id: BigInt(id) } });
    if (!patient) {
      throw new NotFoundException('Khong tim thay benh nhan');
    }

    return patient;
  }

  private async ensurePatientUniqueness(phone: string, email?: string) {
    const [existingPhone, existingEmail] = await Promise.all([
      this.prisma.patientProfile.findUnique({ where: { phone_number: phone } }),
      email ? this.prisma.patientProfile.findFirst({ where: { email } }) : null,
    ]);

    if (existingPhone) {
      throw new BadRequestException('So dien thoai da ton tai');
    }

    if (existingEmail) {
      throw new BadRequestException('Email da ton tai');
    }
  }
}
