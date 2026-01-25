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

  async createAppointment(
    patientId: string,
    dto: CreateAppointmentDto,
  ) {
    // Validate slot exists and is available
    const slot = await this.prisma.slot.findUnique({
      where: { id: dto.slotId },
      include: { doctor: true },
    });

    if (!slot) {
      throw new NotFoundException('Slot not found');
    }

    if (slot.isBlocked) {
      throw new BadRequestException('Slot is blocked');
    }

    // Check if appointment already exists for this slot (transaction-based anti-collision)
    const existingAppointment = await this.prisma.appointment.findUnique({
      where: { slotId: dto.slotId },
    });

    if (existingAppointment) {
      throw new BadRequestException('Slot already booked');
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

    if (!doctor) {
      throw new NotFoundException('Doctor profile not found');
    }

    return this.prisma.appointment.findMany({
      where: { doctorId: doctor.id },
      include: {
        slot: { include: { clinic: true } },
        patient: { include: { user: true } },
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
        'Cannot cancel completed or already cancelled appointment',
      );
    }

    return this.prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: AppointmentStatus.CANCELLED },
    });
  }
}
