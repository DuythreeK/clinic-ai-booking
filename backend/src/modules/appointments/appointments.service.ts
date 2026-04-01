import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import {
  CreateAppointmentDto,
  UpdateAppointmentDto,
  UpdateAppointmentStatusDto,
  AddDoctorNotesDto,
  RescheduleAppointmentDto,
  AppointmentFilterDto,
} from './dto/appointment.dto';
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
    // Validate slot exists and is available
    const slot = await this.prisma.slot.findUnique({
      where: { id: dto.slotId },
      include: { doctor: true },
    });

    if (!slot) throw new NotFoundException('Slot not found');

    if (slot.status !== 'AVAILABLE' || slot.is_active !== 1 || slot.available_count <= 0) {
      throw new BadRequestException('Slot is not available');
    }

    // Check if appointment already exists for this slot (transaction-based anti-collision)
    const existingAppointment = await this.prisma.appointment.findUnique({
      where: { slotId: dto.slotId },
    });

    if (existingAppointment) {
      throw new BadRequestException('Slot is already booked');
    }

    // Create appointment in transaction
    const appointment = await this.prisma.$transaction(async (tx) => {
      // Double-check within transaction
      const check = await tx.appointment.findUnique({
        where: { slotId: dto.slotId },
      });
      if (check) {
        throw new BadRequestException('Slot was just booked');
      }

      // Create appointment
      return tx.appointment.create({
        data: {
          patientId,
          doctorId: slot.doctor.id,
          slotId: dto.slotId,
          status: AppointmentStatus.PENDING,
          reason: dto.reason,
          attachments: dto.attachments
            ? JSON.stringify(dto.attachments)
            : null,
        },
        include: {
          slot: {
            include: { clinic: true },
          },
          doctor: true,
          patient: true,
        },
      });
    });

    return appointment;
  }

  async getMyAppointments(patientId: string) {
    return this.prisma.appointment.findMany({
      where: { patientId },
      include: {
        slot: { include: { clinic: true } },
        doctor: { include: { user: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getDoctorAppointments(doctorId: string) {
    // Get doctor by userId first
    const doctor = await this.prisma.doctor.findUnique({
      where: { userId: doctorId },
    });

    if (!appointment) throw new NotFoundException('Appointment not found');
    return appointment;
  }

  async getPatientAppointments(patientId: string, status?: string) {
    const where: any = { patientId };
    if (status) where.status = status;

    return this.prisma.appointment.findMany({
      where: { doctorId: doctor.id },
      include: {
        slot: { include: { clinic: true } },
        patient: { include: { user: true } },
        slot: { include: { clinic: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateAppointment(
    appointmentId: string,
    userId: string,
    userRole: UserRole,
    dto: UpdateAppointmentDto,
  ) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: { doctor: true, patient: true },
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    // Authorization check
    if (userRole === UserRole.DOCTOR && appointment.doctor.userId !== userId) {
      throw new ForbiddenException(
        'Only the assigned doctor can update this appointment',
      );
    }

    if (userRole === UserRole.PATIENT && appointment.patient.userId !== userId) {
      throw new ForbiddenException(
        'Only the patient can update this appointment',
      );
    }

    return this.prisma.appointment.update({
      where: { id: appointmentId },
      data: {
        status: dto.status ? (dto.status as AppointmentStatus) : undefined,
        doctorNotes: dto.doctorNotes,
        doctorAdvice: dto.doctorAdvice,
      },
      include: {
        slot: { include: { clinic: true } },
        doctor: { include: { user: true } },
        patient: { include: { user: true } },
        doctor: { include: { user: true } },
        slot: { include: { clinic: true } },
      },
    });
  }

  async cancelAppointment(
    appointmentId: string,
    userId: string,
    userRole: UserRole,
  ) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: { doctor: true, patient: true },
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    // Check authorization
    if (
      userRole === UserRole.PATIENT &&
      appointment.patient.userId !== userId
    ) {
      throw new ForbiddenException('Only the patient can cancel');
    }

    if (
      userRole === UserRole.DOCTOR &&
      appointment.doctor.userId !== userId &&
      userRole !== UserRole.ADMIN
    ) {
      throw new ForbiddenException('Not authorized');
    }

    if (
      appointment.status === AppointmentStatus.COMPLETED ||
      appointment.status === AppointmentStatus.CANCELLED
    ) {
      throw new BadRequestException(
        'Can only reschedule pending or confirmed appointments',
      );
    }

    const newSlot = await this.prisma.slot.findUnique({
      where: { id: dto.newSlotId },
      include: { appointments: true },
    });

    if (!newSlot) throw new NotFoundException('New slot not found');

    if (newSlot.isBlocked) {
      throw new BadRequestException('New slot is blocked');
    }

    const existingAppointment = newSlot.appointments.find(
      (apt) => apt.status !== AppointmentStatus.CANCELLED,
    );
    if (existingAppointment) {
      throw new BadRequestException('New slot is already booked');
    }

    const newAppointment = await this.prisma.appointment.create({
      data: {
        patientId: appointment.patientId,
        doctorId: appointment.doctorId,
        slotId: dto.newSlotId,
        reason: appointment.reason,
        rescheduledFrom: id,
        status: AppointmentStatus.PENDING,
      },
      include: {
        patient: { include: { user: true } },
        doctor: { include: { user: true } },
        slot: { include: { clinic: true } },
      },
    });

    await this.prisma.appointment.update({
      where: { id },
      data: { status: AppointmentStatus.CANCELLED },
    });

    return newAppointment;
  }

  async cancelAppointment(id: string) {
    const appointment = await this.getAppointmentById(id);

    if (appointment.status === AppointmentStatus.CANCELLED) {
      throw new BadRequestException('Appointment is already cancelled');
    }

    if (appointment.status === AppointmentStatus.COMPLETED) {
      throw new BadRequestException('Cannot cancel completed appointment');
    }

    return this.prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: AppointmentStatus.CANCELLED },
    });
  }
}

