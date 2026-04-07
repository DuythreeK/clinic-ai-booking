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
          user_id: this.toBigIntId(userId),
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
      orderBy: { created_at: 'desc' },
    });

    const items = records.map((record) => ({
      recordId: toNumberId(record.record_id),
      appointmentId: toNumberId(record.appointment_id),
      appointmentCode: record.appointment.appointment_code,
      appointmentDate: formatDateOnly(record.appointment.appointment_date),
      doctor: {
        id: toNumberId(record.doctor_id),
        fullName: record.doctor.full_name,
      },
      facility: {
        id: toNumberId(record.appointment.facility_id),
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

    if (!record || record.patient.user_id !== this.toBigIntId(userId)) {
      throw new NotFoundException('Medical record not found');
    }

    return okResponse('Get medical record detail successfully', {
      recordId: toNumberId(record.record_id),
      appointmentId: toNumberId(record.appointment_id),
      patient: {
        id: toNumberId(record.patient_id),
        fullName: record.patient.full_name,
      },
      doctor: {
        id: toNumberId(record.doctor_id),
        fullName: record.doctor.full_name,
      },
      symptoms: record.symptoms,
      diagnosis: record.diagnosis,
      treatmentPlan: record.treatment_plan,
      prescription: Array.isArray(record.prescription) ? record.prescription : [],
      followUpDate: formatDateOnly(record.follow_up_date),
      attachments: Array.isArray(record.attachments) ? record.attachments : [],
      createdAt: record.created_at,
    });
  }
}
