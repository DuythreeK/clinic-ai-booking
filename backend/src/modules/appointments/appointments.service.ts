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

  async createAppointment(patientId: string, dto: CreateAppointmentDto) {
    const slot = await this.prisma.slot.findUnique({
      where: { id: dto.slotId },
      include: { appointments: true },
    });

    if (!slot) throw new NotFoundException('Slot not found');

    if (slot.isBlocked) {
      throw new BadRequestException('Slot is blocked');
    }

    const existingAppointment = slot.appointments.find(
      (apt) => apt.status !== AppointmentStatus.CANCELLED,
    );
    if (existingAppointment) {
      throw new BadRequestException('Slot is already booked');
    }

    const patient = await this.prisma.patientProfile.findUnique({
      where: { id: patientId },
    });
    if (!patient) throw new NotFoundException('Patient not found');

    const doctor = await this.prisma.doctor.findUnique({
      where: { id: dto.doctorId },
    });
    if (!doctor) throw new NotFoundException('Doctor not found');

    return this.prisma.appointment.create({
      data: {
        patientId,
        doctorId: dto.doctorId,
        slotId: dto.slotId,
        reason: dto.reason,
        attachments: dto.attachments,
        status: AppointmentStatus.PENDING,
      },
      include: {
        patient: { include: { user: true } },
        doctor: { include: { user: true, specialty: true } },
        slot: { include: { clinic: true } },
      },
    });
  }

  async getAppointments(filter: AppointmentFilterDto) {
    const where: any = {};

    if (filter.patientId) where.patientId = filter.patientId;
    if (filter.doctorId) where.doctorId = filter.doctorId;
    if (filter.status) where.status = filter.status;

    if (filter.fromDate || filter.toDate) {
      where.slot = {
        startAt: {},
      };
      if (filter.fromDate) {
        where.slot.startAt.gte = new Date(filter.fromDate);
      }
      if (filter.toDate) {
        where.slot.startAt.lte = new Date(filter.toDate);
      }
    }

    return this.prisma.appointment.findMany({
      where,
      include: {
        patient: { include: { user: true } },
        doctor: { include: { user: true, specialty: true } },
        slot: { include: { clinic: true } },
      },
      orderBy: { slot: { startAt: 'asc' } },
    });
  }

  async getAppointmentById(id: string) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id },
      include: {
        patient: { include: { user: true } },
        doctor: { include: { user: true, specialty: true } },
        slot: { include: { clinic: true } },
      },
    });

    if (!appointment) throw new NotFoundException('Appointment not found');
    return appointment;
  }

  async getPatientAppointments(patientId: string, status?: string) {
    const where: any = { patientId };
    if (status) where.status = status;

    return this.prisma.appointment.findMany({
      where,
      include: {
        doctor: { include: { user: true, specialty: true } },
        slot: { include: { clinic: true } },
      },
      orderBy: { slot: { startAt: 'desc' } },
    });
  }

  async getDoctorAppointments(doctorId: string, status?: string) {
    const where: any = { doctorId };
    if (status) where.status = status;

    return this.prisma.appointment.findMany({
      where,
      include: {
        patient: { include: { user: true } },
        slot: { include: { clinic: true } },
      },
      orderBy: { slot: { startAt: 'asc' } },
    });
  }

  async updateAppointment(id: string, dto: UpdateAppointmentDto) {
    const appointment = await this.getAppointmentById(id);

    if (appointment.status !== AppointmentStatus.PENDING) {
      throw new BadRequestException('Can only update pending appointments');
    }

    return this.prisma.appointment.update({
      where: { id },
      data: {
        reason: dto.reason,
        attachments: dto.attachments,
      },
      include: {
        patient: { include: { user: true } },
        doctor: { include: { user: true, specialty: true } },
        slot: { include: { clinic: true } },
      },
    });
  }

  async updateAppointmentStatus(id: string, dto: UpdateAppointmentStatusDto) {
    const appointment = await this.getAppointmentById(id);

    const validTransitions: Record<string, string[]> = {
      [AppointmentStatus.PENDING]: [
        AppointmentStatus.CONFIRMED,
        AppointmentStatus.CANCELLED,
      ],
      [AppointmentStatus.CONFIRMED]: [
        AppointmentStatus.CANCELLED,
        AppointmentStatus.COMPLETED,
        AppointmentStatus.NO_SHOW,
      ],
      [AppointmentStatus.CANCELLED]: [],
      [AppointmentStatus.COMPLETED]: [],
      [AppointmentStatus.NO_SHOW]: [],
    };

    if (!validTransitions[appointment.status]?.includes(dto.status as AppointmentStatus)) {
      throw new BadRequestException(
        `Cannot transition from ${appointment.status} to ${dto.status}`,
      );
    }

    return this.prisma.appointment.update({
      where: { id },
      data: { status: dto.status as AppointmentStatus },
      include: {
        patient: { include: { user: true } },
        doctor: { include: { user: true } },
        slot: { include: { clinic: true } },
      },
    });
  }

  async addDoctorNotes(id: string, dto: AddDoctorNotesDto) {
    const appointment = await this.getAppointmentById(id);

    if (appointment.status !== AppointmentStatus.COMPLETED) {
      throw new BadRequestException('Can only add notes to completed appointments');
    }

    return this.prisma.appointment.update({
      where: { id },
      data: {
        doctorNotes: dto.doctorNotes,
        doctorAdvice: dto.doctorAdvice,
      },
      include: {
        patient: { include: { user: true } },
        doctor: { include: { user: true } },
        slot: { include: { clinic: true } },
      },
    });
  }

  async rescheduleAppointment(id: string, dto: RescheduleAppointmentDto) {
    const appointment = await this.getAppointmentById(id);

    if (
      ![AppointmentStatus.PENDING, AppointmentStatus.CONFIRMED].includes(
        appointment.status as any,
      )
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
      where: { id },
      data: { status: AppointmentStatus.CANCELLED },
      include: {
        patient: { include: { user: true } },
        doctor: { include: { user: true } },
        slot: { include: { clinic: true } },
      },
    });
  }

  async deleteAppointment(id: string) {
    await this.getAppointmentById(id);

    return this.prisma.appointment.delete({
      where: { id },
    });
  }
}

