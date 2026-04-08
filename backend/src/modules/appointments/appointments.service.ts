import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateAppointmentDto, UpdateAppointmentDto } from './dto/appointment.dto';

import { okResponse } from '@/common/utils/api-response';
import { formatDateOnly, formatTimeOnly, toNumberId } from '@/common/utils/formatters';
import { SlotStatus, AppointmentStatus, AppointmentType } from '@prisma/client';
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
      where: { patientId: patientId },
    });

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
      console.log('--- ĐANG TẠO LỊCH HẸN VÀ KHÓA SLOT ---');
      const check = await tx.appointment.findUnique({
        where: { slotId: slotId },
      });
      if (check) {
        throw new BadRequestException('Slot was just booked');
      }

      const createdAppointment = await tx.appointment.create({
        data: {
          appointmentCode: `APT-${Date.now()}`,
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
          appointmentDate: slot.slotDate,
          appointmentTime: slot.startTime,
          status: AppointmentStatus.pending,
          symptoms_note: dto.symptomsNote,
          note: dto.note,
          totalAmount: slot.doctor?.consultation_fee ?? service?.price ?? 0,
        },
      });

      await tx.slot.update({
        where: { slotId: slotId },
        data: {
          isActive: 0, // Đổi sang PENDING để Flutter hiện MÀU VÀNG
          status: SlotStatus.AVAILABLE,
          available_count: { decrement: 1 }
        },
      });
      console.log(`--- ĐÃ KHÓA SLOT ${slotId} THÀNH CÔNG ---`);
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

    // Chèn sau khi kết thúc transaction
    setTimeout(async () => {
      try {
        const currentAppt = await this.prisma.appointment.findUnique({
          where: { appointmentId: appointment.appointmentId },
        });

        // Nếu vẫn là pending tức là chưa thanh toán xong
        if (currentAppt && currentAppt.status === AppointmentStatus.pending) {
          await this.prisma.$transaction([
            this.prisma.appointment.update({
              where: { appointmentId: appointment.appointmentId },
              data: { status: 'cancelled' as any },
            }),
            this.prisma.slot.update({
              where: { slotId: slotId },
              data: {
                isActive: 1, // Mở khóa lại slot về trạng thái hoạt động
                available_count: { increment: 1 }
              },
            }),
          ]);
          console.log(`[Timer] Đã kích hoạt lại slot ${slotId} do hết hạn thanh toán.`);
        }
      } catch (error) {
        console.error('[Timer Error] Lỗi nhả slot:', error);
      }
    }, 300000); // 5 phút

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
  async getUserAppointments(userId: string) {
    const appointments = await this.prisma.appointment.findMany({
      where: { userId: this.toBigIntId(userId, 'userId') },
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
        { appointmentDate: 'desc' },
        { appointmentTime: 'desc' },
      ],
    });

    return okResponse('Get user appointments successfully', appointments.map(apt => ({
      id: toNumberId(apt.appointmentId),
      appointmentCode: apt.appointmentCode,
      appointmentType: apt.appointment_type,
      appointmentDate: formatDateOnly(apt.appointmentDate),
      appointmentTime: formatTimeOnly(apt.appointmentTime),
      status: apt.status,
      note: apt.note,
      symptomsNote: apt.symptoms_note,
      totalAmount: Number(apt.totalAmount),
      doctor: apt.doctor
        ? {
            id: toNumberId(apt.doctor.doctorId),
            name: apt.doctor.fullName,
            specialty: apt.doctor.specialty?.name,
            imageUrl: apt.doctor.avatar_url,
          }
        : null,
      patient: apt.patient
        ? {
            id: toNumberId(apt.patient.patientId),
            fullName: apt.patient.fullName,
          }
        : null,
      service: apt.service
        ? {
            id: toNumberId(apt.service.serviceId),
            name: apt.service.name,
          }
        : null,
    })));
  }
}
