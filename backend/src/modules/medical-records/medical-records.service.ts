import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { okResponse, paginatedResponse } from '@/common/utils/api-response';
import { formatDateOnly, toNumberId } from '@/common/utils/formatters';

@Injectable()
export class MedicalRecordsService {
  constructor(private prisma: PrismaService) {}

  private toBigIntId(id: string): bigint {
    return BigInt(id);
  }

  async getMyMedicalRecords(userId: string) {
    const records = await this.prisma.medicalRecord.findMany({
      where: {
        patient: {
          userId: this.toBigIntId(userId),
        },
      },
      include: {
        doctor: true,
        appointment: {
          include: {
            facility: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const items = records.map((record) => ({
      recordId: toNumberId(record.record_id),
      appointmentId: toNumberId(record.appointmentId),
      appointmentCode: record.appointment.appointmentCode,
      appointmentDate: formatDateOnly(record.appointment.appointmentDate),
      doctor: {
        id: toNumberId(record.doctorId),
        fullName: record.doctor.fullName,
      },
      facility: {
        id: toNumberId(record.appointment.facilityId),
        name: record.appointment.facility.name,
      },
      diagnosis: record.diagnosis,
    }));

    return paginatedResponse('Get medical records successfully', items, 1, 10, items.length);
  }

  async getMedicalRecordById(userId: string, id: string) {
    const record = await this.prisma.medicalRecord.findUnique({
      where: { record_id: this.toBigIntId(id) },
      include: {
        patient: true,
        doctor: true,
        appointment: {
          include: {
            facility: true,
          },
        },
      },
    });

    if (!record || record.patient.userId !== this.toBigIntId(userId)) {
      throw new NotFoundException('Medical record not found');
    }

    return okResponse('Get medical record detail successfully', {
      recordId: toNumberId(record.record_id),
      appointmentId: toNumberId(record.appointmentId),
      patient: {
        id: toNumberId(record.patientId),
        fullName: record.patient.fullName,
      },
      doctor: {
        id: toNumberId(record.doctorId),
        fullName: record.doctor.fullName,
      },
      symptoms: record.symptoms,
      diagnosis: record.diagnosis,
      treatmentPlan: record.treatment_plan,
      prescription: Array.isArray(record.prescription) ? record.prescription : [],
      followUpDate: formatDateOnly(record.follow_up_date),
      attachments: Array.isArray(record.attachments) ? record.attachments : [],
      createdAt: record.createdAt,
    });
  }
}
