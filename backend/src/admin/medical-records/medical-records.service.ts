import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ApptStatus, Prisma } from '@prisma/client';
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
      patientId: query.patientId,
      doctorId: query.doctorId,
      appointmentId: query.appointmentId,
      isLocked: query.isLocked,
      OR: query.search
        ? [
            { diagnosis: { contains: query.search } },
            { appointment: { is: { refCode: { contains: query.search } } } },
            { patient: { is: { fullName: { contains: query.search } } } },
          ]
        : undefined,
    };

    const [items, total] = await Promise.all([
      this.prisma.medicalRecord.findMany({
        where,
        skip,
        take,
        include: medicalRecordInclude,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.medicalRecord.count({ where }),
    ]);

    return { data: items, meta: { page, limit, total } };
  }

  async findOne(id: string) {
    const record = await this.prisma.medicalRecord.findUnique({
      where: { id },
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
        where: { id: dto.appointmentId },
      });

      if (!appointment) {
        throw new NotFoundException('Khong tim thay lich hen');
      }

      if (appointment.status === ApptStatus.cancelled) {
        throw new BadRequestException('Khong the tao benh an cho lich da huy');
      }

      const existing = await tx.medicalRecord.findUnique({
        where: { appointmentId: dto.appointmentId },
      });
      if (existing) {
        throw new BadRequestException('Lich hen nay da co benh an');
      }

      const record = await tx.medicalRecord.create({
        data: {
          appointmentId: appointment.id,
          patientId: appointment.patientId,
          doctorId: appointment.doctorId,
          diagnosis: dto.diagnosis,
          icd10Codes: (dto.icd10Codes ?? []) as Prisma.InputJsonValue,
          vitalSigns: dto.vitalSigns as Prisma.InputJsonValue | undefined,
          treatmentPlan: dto.treatmentPlan,
          prescription: (dto.prescription ?? []) as Prisma.InputJsonValue,
          followUpDate: dto.followUpDate
            ? parseDateOnly(dto.followUpDate)
            : undefined,
          attachments: (dto.attachments ?? []) as Prisma.InputJsonValue,
        },
      });

      if (appointment.status !== ApptStatus.completed) {
        await tx.appointment.update({
          where: { id: appointment.id },
          data: {
            status: ApptStatus.completed,
            completedAt: new Date(),
          },
        });
      }

      return tx.medicalRecord.findUniqueOrThrow({
        where: { id: record.id },
        include: medicalRecordInclude,
      });
    });
  }

  async update(id: string, dto: UpdateMedicalRecordDto) {
    const record = await this.findOne(id);
    if (record.isLocked) {
      throw new BadRequestException('Benh an da khoa');
    }

    return this.prisma.medicalRecord.update({
      where: { id },
      data: {
        diagnosis: dto.diagnosis,
        icd10Codes: dto.icd10Codes as Prisma.InputJsonValue | undefined,
        vitalSigns: dto.vitalSigns as Prisma.InputJsonValue | undefined,
        treatmentPlan: dto.treatmentPlan,
        prescription: dto.prescription as Prisma.InputJsonValue | undefined,
        followUpDate: dto.followUpDate
          ? parseDateOnly(dto.followUpDate)
          : undefined,
        attachments: dto.attachments as Prisma.InputJsonValue | undefined,
        isLocked: dto.isLocked,
      },
      include: medicalRecordInclude,
    });
  }

  async lock(id: string) {
    const record = await this.findOne(id);
    if (record.isLocked) {
      return record;
    }

    return this.prisma.medicalRecord.update({
      where: { id },
      data: { isLocked: true },
      include: medicalRecordInclude,
    });
  }
}
