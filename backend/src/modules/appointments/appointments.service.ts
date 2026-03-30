import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateAppointmentDto, UpdateAppointmentDto } from './dto/appointment.dto';
import { AppointmentStatus, UserRole } from '@prisma/client';

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

  async createAppointment(
    patientId: string,
    dto: CreateAppointmentDto,
  ) {
    const userId = this.toBigIntId(patientId, 'user id');
    const slotId = this.toBigIntId(dto.slot_id, 'slot_id');

    // Validate slot exists and is available.
    const slot = await this.prisma.slot.findUnique({
      where: { slot_id: slotId },
      include: { doctor: true },
    });

    if (!slot) {
      throw new NotFoundException('Slot not found');
    }

    if (slot.status !== 'AVAILABLE' || slot.is_active !== 1 || slot.available_count <= 0) {
      throw new BadRequestException('Slot is not available');
    }

    // One appointment per slot because slot_id is unique in Appointment.
    const existingAppointment = await this.prisma.appointment.findUnique({
      where: { slot_id: slotId },
    });

    if (existingAppointment) {
      throw new BadRequestException('Slot already booked');
    }

    // Resolve patient profile for patient role, fallback to dto.patient_id when provided.
    let patientProfileId: bigint | null = null;
    if (dto.patient_id) {
      patientProfileId = this.toBigIntId(dto.patient_id, 'patient_id');
    } else {
      const primaryProfile = await this.prisma.patientProfile.findFirst({
        where: {
          user_id: userId,
          is_primary: 1,
        },
        select: { patient_id: true },
      });
      if (!primaryProfile) {
        throw new BadRequestException('No primary patient profile found for this user');
      }
      patientProfileId = primaryProfile.patient_id;
    }

    const appointmentDate = new Date(slot.slot_date);
    const appointmentTime = new Date(slot.start_time);

    const appointment = await this.prisma.$transaction(async (tx) => {
      // Double-check within transaction.
      const check = await tx.appointment.findUnique({
        where: { slot_id: slotId },
      });
      if (check) {
        throw new BadRequestException('Slot was just booked');
      }

      return tx.appointment.create({
        data: {
          appointment_code: `APT-${Date.now()}`,
          user_id: userId,
          patient_id: patientProfileId,
          facility_id: slot.facility_id,
          doctor_id: slot.doctor_id,
          slot_id: slotId,
          appointment_type: 'consultation',
          appointment_date: appointmentDate,
          appointment_time: appointmentTime,
          status: AppointmentStatus.pending,
          symptoms_note: dto.attachments ? JSON.stringify(dto.attachments) : null,
          note: dto.note,
          total_amount: slot.doctor.consultation_fee ?? 0,
        },
        include: {
          slot: { include: { facility: true } },
          doctor: true,
          patient: true,
        },
      });
    });

    return appointment;
  }

  async getMyAppointments(patientId: string) {
    const userId = this.toBigIntId(patientId, 'user id');

    return this.prisma.appointment.findMany({
      where: { user_id: userId },
      include: {
        slot: { include: { facility: true } },
        doctor: { include: { user: true } },
      },
      orderBy: { created_at: 'desc' },
    });
  }

  async getDoctorAppointments(doctorId: string) {
    const userId = this.toBigIntId(doctorId, 'user id');

    // Get doctor by linked user_id first.
    const doctor = await this.prisma.doctor.findUnique({
      where: { user_id: userId },
    });

    if (!doctor) {
      throw new NotFoundException('Doctor profile not found');
    }

    return this.prisma.appointment.findMany({
      where: { doctor_id: doctor.doctor_id },
      include: {
        slot: { include: { facility: true } },
        patient: { include: { user: true } },
      },
      orderBy: { created_at: 'desc' },
    });
  }

  async updateAppointment(
    appointmentId: string,
    userId: string,
    userRole: UserRole,
    dto: UpdateAppointmentDto,
  ) {
    const parsedAppointmentId = this.toBigIntId(appointmentId, 'appointment id');
    const parsedUserId = this.toBigIntId(userId, 'user id');

    const appointment = await this.prisma.appointment.findUnique({
      where: { appointment_id: parsedAppointmentId },
      include: { doctor: true, patient: true },
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    // Authorization check.
    if (userRole === UserRole.doctor && appointment.doctor?.user_id !== parsedUserId) {
      throw new ForbiddenException(
        'Only the assigned doctor can update this appointment',
      );
    }

    if (userRole === UserRole.patient && appointment.patient.user_id !== parsedUserId) {
      throw new ForbiddenException(
        'Only the patient can update this appointment',
      );
    }

    return this.prisma.appointment.update({
      where: { appointment_id: parsedAppointmentId },
      data: {
        status: dto.status ? (dto.status as AppointmentStatus) : undefined,
        note: dto.note,
        symptoms_note: dto.symptoms_note,
      },
      include: {
        slot: { include: { facility: true } },
        doctor: { include: { user: true } },
        patient: { include: { user: true } },
      },
    });
  }

  async cancelAppointment(
    appointmentId: string,
    userId: string,
    userRole: UserRole,
  ) {
    const parsedAppointmentId = this.toBigIntId(appointmentId, 'appointment id');
    const parsedUserId = this.toBigIntId(userId, 'user id');

    const appointment = await this.prisma.appointment.findUnique({
      where: { appointment_id: parsedAppointmentId },
      include: { doctor: true, patient: true },
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    // Check authorization
    if (
      userRole === UserRole.patient &&
      appointment.patient.user_id !== parsedUserId
    ) {
      throw new ForbiddenException('Only the patient can cancel');
    }

    if (
      userRole === UserRole.doctor &&
      appointment.doctor?.user_id !== parsedUserId
    ) {
      throw new ForbiddenException('Not authorized');
    }

    if (
      appointment.status === AppointmentStatus.completed ||
      appointment.status === AppointmentStatus.cancelled
    ) {
      throw new BadRequestException(
        'Cannot cancel completed or already cancelled appointment',
      );
    }

    return this.prisma.appointment.update({
      where: { appointment_id: parsedAppointmentId },
      data: { status: AppointmentStatus.cancelled },
    });
  }
}
