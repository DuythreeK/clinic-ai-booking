import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateAppointmentDto, UpdateAppointmentDto } from './dto/appointment.dto';
// Sửa AppointmentStatus.pending thành chữ thường theo Enum trong Schema của bạn
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
    // Schema của bạn dùng facilityId (có gạch dưới)
    const facilityId = this.toBigIntId(dto.facilityId, 'facilityId');

    const patient = await this.prisma.patientProfile.findUnique({
      where: { patientId: patientId },
    });

    // So sánh BigInt phải dùng BigInt (toBigIntId đã xử lý)
    if (!patient || patient.userId !== this.toBigIntId(userId, 'userId')) {
      throw new NotFoundException('Patient profile not found');
    }

    const slot = await this.prisma.slot.findUnique({
      where: { slotId: slotId },
      include: { doctor: true },
    });

    if (!slot || slot.isActive !== 1) {
      throw new NotFoundException('Slot not found');
    }

    // Kiểm tra facilityId theo chuẩn Schema của bạn
    if (slot.facilityId !== facilityId) {
      throw new BadRequestException('Slot does not belong to facility');
    }

    if (slot.status !== 'AVAILABLE' || slot.available_count <= 0) {
      throw new BadRequestException('Slot is not available');
    }

    const existingAppointment = await this.prisma.appointment.findUnique({
      where: { slotId: slotId },
    });

    if (existingAppointment) {
      throw new BadRequestException('Slot is already booked');
    }

    const service = dto.serviceId
      ? await this.prisma.service.findUnique({
          where: { serviceId: this.toBigIntId(dto.serviceId, 'serviceId') },
        })
      : null;

    const appointment = await this.prisma.$transaction(async (tx) => {
      const check = await tx.appointment.findUnique({
        where: { slotId: slotId },
      });
      if (check) {
        throw new BadRequestException('Slot was just booked');
      }

      const createdAppointment = await tx.appointment.create({
        data: {
          appointmentCode: `APT-${Date.now()}`, // Schema dùng appointmentCode
          userId: this.toBigIntId(userId, 'userId'),
          patientId: patientId,
          facilityId: slot.facilityId,
          doctorId: slot.doctorId,
          slotId: slotId,
          serviceId: service?.serviceId,
          appointment_type:
            dto.appointmentType === 'consultation'
              ? AppointmentType.consultation
              : AppointmentType.vaccination,
          appointmentDate: slot.slot_date,
          appointmentTime: slot.start_time,
          status: AppointmentStatus.pending, // Schema dùng chữ thường: pending
          note: dto.note,
          totalAmount: service?.price ?? 0,
        },
      });

      await tx.slot.update({
        where: { slotId: slotId },
        data: {
          available_count: { decrement: 1 },
          status: slot.available_count - 1 <= 0 ? 'FULL' : undefined,
        },
      });

      return tx.appointment.findUniqueOrThrow({
        where: { appointmentId: createdAppointment.appointmentId },
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
      id: toNumberId(appointment.appointmentId),
      appointmentCode: appointment.appointmentCode,
      userId: toNumberId(appointment.userId),
      patientId: toNumberId(appointment.patientId),
      facilityId: toNumberId(appointment.facilityId),
      serviceId: appointment.serviceId ? toNumberId(appointment.serviceId) : null,
      slotId: toNumberId(appointment.slotId),
      appointmentType: appointment.appointment_type,
      appointmentDate: formatDateOnly(appointment.appointmentDate),
      appointmentTime: formatTimeOnly(appointment.appointmentTime),
      status: appointment.status,
      paymentStatus: 'pending',
      totalAmount: Number(appointment.totalAmount),
      note: appointment.note,
      createdAt: appointment.createdAt,
    });
  }

  async getAppointmentById(userId: string, appointmentId: string) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { appointmentId: this.toBigIntId(appointmentId, 'appointmentId') },
      include: {
        patient: true,
        doctor: true,
        facility: true,
        service: true,
        slot: true,
      },
    });

    if (!appointment || appointment.userId !== this.toBigIntId(userId, 'userId')) {
      throw new NotFoundException('Appointment not found');
    }

    return okResponse('Get appointment detail successfully', {
      id: toNumberId(appointment.appointmentId),
      appointmentCode: appointment.appointmentCode,
      appointmentType: appointment.appointment_type,
      appointmentDate: formatDateOnly(appointment.appointmentDate),
      appointmentTime: formatTimeOnly(appointment.appointmentTime),
      status: appointment.status,
      note: appointment.note,
      totalAmount: Number(appointment.totalAmount),
      patient: appointment.patient
        ? {
            id: toNumberId(appointment.patient.patientId),
            fullName: appointment.patient.fullName,
          }
        : null,
      facility: appointment.facility
        ? {
            id: toNumberId(appointment.facility.facilityId),
            name: appointment.facility.name,
          }
        : null,
      service: appointment.service
        ? {
            id: toNumberId(appointment.service.serviceId),
            name: appointment.service.name,
            price: Number(appointment.service.price),
          }
        : null,
    });
  }
}