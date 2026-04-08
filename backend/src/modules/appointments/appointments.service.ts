import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateAppointmentDto, UpdateAppointmentDto } from './dto/appointment.dto';
import { AppointmentStatus, AppointmentType } from '@prisma/client';
import { okResponse } from '@/common/utils/api-response';
import { formatDateOnly, formatTimeOnly, toNumberId } from '@/common/utils/formatters';

@Injectable()
export class AppointmentsService {
  constructor(private prisma: PrismaService) {}

  private toBigIntId(id: string, fieldName: string): bigint {
    try {
      return BigInt(id);
    } catch {
      throw new BadRequestException(`Invalid ${fieldName}`);
    }
  }

  async createAppointment(userId: string, dto: CreateAppointmentDto) {
    const patientId = this.toBigIntId(dto.patientId, 'patientId');
    const slotId = this.toBigIntId(dto.slotId, 'slotId');
    const facilityId = this.toBigIntId(dto.facilityId, 'facilityId');

    const patient = await this.prisma.patientProfile.findUnique({
      where: { patient_id: patientId },
    });

    if (!patient || patient.user_id !== this.toBigIntId(userId, 'userId')) {
      throw new NotFoundException('Patient profile not found');
    }

    const slot = await this.prisma.slot.findUnique({
      where: { slot_id: slotId },
      include: { doctor: true },
    });

    if (!slot || slot.is_active !== 1) {
      throw new NotFoundException('Slot not found');
    }

    if (slot.facility_id !== facilityId) {
      throw new BadRequestException('Slot does not belong to facility');
    }

    if (slot.status !== 'AVAILABLE' || slot.available_count <= 0) {
      throw new BadRequestException('Slot is not available');
    }

    const existingAppointment = await this.prisma.appointment.findUnique({
      where: { slot_id: slotId },
    });

    if (existingAppointment) {
      throw new BadRequestException('Slot is already booked');
    }

    const service = dto.serviceId
      ? await this.prisma.service.findUnique({
          where: { service_id: this.toBigIntId(dto.serviceId, 'serviceId') },
        })
      : null;

    const appointment = await this.prisma.$transaction(async (tx) => {
      const check = await tx.appointment.findUnique({
        where: { slot_id: slotId },
      });
      if (check) {
        throw new BadRequestException('Slot was just booked');
      }

      const createdAppointment = await tx.appointment.create({
        data: {
          appointment_code: `APT-${Date.now()}`,
          user_id: this.toBigIntId(userId, 'userId'),
          patient_id: patientId,
          facility_id: slot.facility_id,
          doctor_id: slot.doctor_id,
          slot_id: slotId,
          service_id: service?.service_id,
          appointment_type:
            dto.appointmentType === 'consultation'
              ? AppointmentType.consultation
              : AppointmentType.vaccination,
          appointment_date: slot.slot_date,
          appointment_time: slot.start_time,
          status: AppointmentStatus.pending,
          symptoms_note: dto.symptomsNote,
          note: dto.note,
          total_amount: slot.doctor?.consultation_fee ?? service?.price ?? 0,
        },
      });

      await tx.slot.update({
        where: { slot_id: slotId },
        data: {
          available_count: { decrement: 1 },
          status: slot.available_count - 1 <= 0 ? 'FULL' : undefined,
        },
      });

      return tx.appointment.findUniqueOrThrow({
        where: { appointment_id: createdAppointment.appointment_id },
        include: {
          patient: true,
          doctor: true,
          facility: true,
          service: true,
          slot: true,
        },
      });
    });

    return okResponse('Create appointment successfully', {
      id: toNumberId(appointment.appointment_id),
      appointmentCode: appointment.appointment_code,
      userId: toNumberId(appointment.user_id),
      patientId: toNumberId(appointment.patient_id),
      facilityId: toNumberId(appointment.facility_id),
      serviceId: appointment.service_id ? toNumberId(appointment.service_id) : null,
      slotId: toNumberId(appointment.slot_id),
      appointmentType: appointment.appointment_type,
      appointmentDate: formatDateOnly(appointment.appointment_date),
      appointmentTime: formatTimeOnly(appointment.appointment_time),
      status: appointment.status,
      paymentStatus: 'pending',
      totalAmount: Number(appointment.total_amount),
      note: appointment.note,
      createdAt: appointment.created_at,
    });
  }

  async getAppointmentById(userId: string, appointmentId: string) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { appointment_id: this.toBigIntId(appointmentId, 'appointmentId') },
      include: {
        patient: true,
        doctor: true,
        facility: true,
        service: true,
        slot: true,
      },
    });

    if (!appointment || appointment.user_id !== this.toBigIntId(userId, 'userId')) {
      throw new NotFoundException('Appointment not found');
    }

    return okResponse('Get appointment detail successfully', {
      id: toNumberId(appointment.appointment_id),
      appointmentCode: appointment.appointment_code,
      appointmentType: appointment.appointment_type,
      appointmentDate: formatDateOnly(appointment.appointment_date),
      appointmentTime: formatTimeOnly(appointment.appointment_time),
      status: appointment.status,
      note: appointment.note,
      totalAmount: Number(appointment.total_amount),
      patient: appointment.patient
        ? {
            id: toNumberId(appointment.patient.patient_id),
            fullName: appointment.patient.full_name,
          }
        : null,
      facility: appointment.facility
        ? {
            id: toNumberId(appointment.facility.facility_id),
            name: appointment.facility.name,
          }
        : null,
      service: appointment.service
        ? {
            id: toNumberId(appointment.service.service_id),
            name: appointment.service.name,
            price: Number(appointment.service.price),
          }
        : null,
    });
  }
  async getUserAppointments(userId: string) {
    const appointments = await this.prisma.appointment.findMany({
      where: { user_id: this.toBigIntId(userId, 'userId') },
      include: {
        patient: true,
        doctor: {
          include: { specialty: true },
        },
        facility: true,
        service: true,
        slot: true,
      },
      orderBy: [
        { appointment_date: 'desc' },
        { appointment_time: 'desc' },
      ],
    });

    return okResponse('Get user appointments successfully', appointments.map(apt => ({
      id: toNumberId(apt.appointment_id),
      appointmentCode: apt.appointment_code,
      appointmentType: apt.appointment_type,
      appointmentDate: formatDateOnly(apt.appointment_date),
      appointmentTime: formatTimeOnly(apt.appointment_time),
      status: apt.status,
      note: apt.note,
      symptomsNote: apt.symptoms_note,
      totalAmount: Number(apt.total_amount),
      doctor: apt.doctor
        ? {
            id: toNumberId(apt.doctor.doctor_id),
            name: apt.doctor.full_name,
            specialty: apt.doctor.specialty?.name,
            imageUrl: apt.doctor.avatar_url,
          }
        : null,
      patient: apt.patient
        ? {
            id: toNumberId(apt.patient.patient_id),
            fullName: apt.patient.full_name,
          }
        : null,
      service: apt.service
        ? {
            id: toNumberId(apt.service.service_id),
            name: apt.service.name,
          }
        : null,
    })));
  }
}
