import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AppointmentStatus, Prisma } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { parseDateOnly } from '../common/utils/date.util';
import { resolvePagination } from '../common/utils/pagination.util';
import {
  CreateMedicalRecordDto,
  MedicalRecordListQueryDto,
  UpdateMedicalRecordDto,
} from './dto/medical-record.dto';

const medicalRecordInclude = {
  appointment: true,
  patient: true,
  doctor: {
    include: {
      user: true,
      specialty: true,
    },
  },
} satisfies Prisma.MedicalRecordInclude;

@Injectable()
export class MedicalRecordsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: MedicalRecordListQueryDto) {
    const { skip, take, page, limit } = resolvePagination(query);
    const where: Prisma.MedicalRecordWhereInput = {
      patient_id: query.patientId ? BigInt(query.patientId) : undefined,
      doctor_id: query.doctorId ? BigInt(query.doctorId) : undefined,
      appointment_id: query.appointmentId ? BigInt(query.appointmentId) : undefined,
      is_locked: query.isLocked !== undefined ? (query.isLocked ? 1 : 0) : undefined,
      OR: query.search
        ? [
            { diagnosis: { contains: query.search } },
            { appointment: { is: { appointment_code: { contains: query.search } } } },
            { patient: { is: { full_name: { contains: query.search } } } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.medicalRecord.findMany({
        where,
        skip,
        take,
        include: medicalRecordInclude,
        orderBy: { created_at: 'desc' },
      }),
      this.prisma.medicalRecord.count({ where }),
    ]);

    return { data: items, meta: { page, limit, total } };
  }

  async findOne(id: string) {
    const record = await this.prisma.medicalRecord.findUnique({
      where: { record_id: BigInt(id) },
      include: medicalRecordInclude,
    });

    if (!record) {
      throw new NotFoundException('Khong tim thay ho so benh an');
    }

    return record;
  }

  async create(dto: CreateMedicalRecordDto) {
    return this.prisma.$transaction(async (tx) => {
      const appointment = await tx.appointment.findUnique({
        where: { appointment_id: BigInt(dto.appointmentId) },
      });

      if (!appointment) {
        throw new NotFoundException('Khong tim thay lich hen');
      }

      if (appointment.status === AppointmentStatus.cancelled) {
        throw new BadRequestException('Khong the tao benh an cho lich da huy');
      }

      const existing = await tx.medicalRecord.findUnique({
        where: { appointment_id: BigInt(dto.appointmentId) },
      });
      if (existing) {
        throw new BadRequestException('Lich hen nay da co benh an');
      }

      const record = await tx.medicalRecord.create({
        data: {
          appointment_id: appointment.appointment_id,
          patient_id: appointment.patient_id,
          doctor_id: appointment.doctor_id ?? BigInt(0), // Fallback or check needed
          diagnosis: dto.diagnosis,
          icd10_codes: (dto.icd10Codes ?? []).join(', '),
          vital_signs: dto.vitalSigns as Prisma.InputJsonValue | undefined,
          treatment_plan: dto.treatmentPlan,
          prescription: dto.prescription as Prisma.InputJsonValue | undefined,
          follow_up_date: dto.followUpDate
            ? parseDateOnly(dto.followUpDate)
            : undefined,
          attachments: (dto.attachments ?? []) as Prisma.InputJsonValue,
        },
      });

      if (appointment.status !== AppointmentStatus.completed) {
        await tx.appointment.update({
          where: { appointment_id: appointment.appointment_id },
          data: {
            status: AppointmentStatus.completed,
          },
        });
      }

      return tx.medicalRecord.findUniqueOrThrow({
        where: { record_id: record.record_id },
        include: medicalRecordInclude,
      });
    });
  }

  async update(id: string, dto: UpdateMedicalRecordDto) {
    const record = await this.findOne(id);
    if ((record as any).is_locked) {
      throw new BadRequestException('Benh an da khoa');
    }

    return this.prisma.medicalRecord.update({
      where: { record_id: BigInt(id) },
      data: {
        diagnosis: dto.diagnosis,
        icd10_codes: (dto.icd10Codes ?? []).join(', '),
        vital_signs: dto.vitalSigns as Prisma.InputJsonValue | undefined,
        treatment_plan: dto.treatmentPlan,
        prescription: dto.prescription as Prisma.InputJsonValue | undefined,
        follow_up_date: dto.followUpDate
          ? parseDateOnly(dto.followUpDate)
          : undefined,
        attachments: dto.attachments as Prisma.InputJsonValue | undefined,
        is_locked: dto.isLocked !== undefined ? (dto.isLocked ? 1 : 0) : undefined,
      },
      include: medicalRecordInclude,
    });
  }

  async lock(id: string) {
    const record = await this.findOne(id);
    if ((record as any).is_locked) {
      return record;
    }

    return this.prisma.medicalRecord.update({
      where: { record_id: BigInt(id) },
      data: { is_locked: 1 },
      include: medicalRecordInclude,
    });
  }
}
