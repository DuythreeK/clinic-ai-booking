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

  async createAppointment(user_id: string, dto: CreateAppointmentDto) {
    const patient_id = this.toBigIntId(dto.patient_id, 'patient_id');
    const slot_id = this.toBigIntId(dto.slot_id, 'slot_id');
    const facility_id = this.toBigIntId(dto.facility_id, 'facility_id');

    const patient = await this.prisma.patientProfile.findUnique({
      where: { patient_id: patient_id },
    });

    if (!patient || patient.user_id !== this.toBigIntId(user_id, 'user_id')) {
      throw new NotFoundException('Patient profile not found');
    }

    const slot = await this.prisma.slot.findUnique({
      where: { slot_id: slot_id },
      include: { doctor: true },
    });

    if (!slot || slot.is_active !== 1) {
      throw new NotFoundException('Slot not found');
    }

    if (slot.facility_id !== facility_id) {
      throw new BadRequestException('Slot does not belong to facility');
    }

    if (slot.status !== 'AVAILABLE' || slot.available_count <= 0) {
      throw new BadRequestException('Slot is not available');
    }

    const existingAppointment = await this.prisma.appointment.findUnique({
      where: { slot_id: slot_id },
    });

    if (existingAppointment) {
      throw new BadRequestException('Slot is already booked');
    }

    const service = dto.service_id
      ? await this.prisma.service.findUnique({
          where: { service_id: this.toBigIntId(dto.service_id, 'service_id') },
        })
      : null;

    const appointment = await this.prisma.$transaction(async (tx) => {
      console.log('--- ĐANG TẠO LỊCH HẸN VÀ KHÓA SLOT ---');
      const check = await tx.appointment.findUnique({
        where: { slot_id: slot_id },
      });
      if (check) {
        throw new BadRequestException('Slot was just booked');
      }

      const createdAppointment = await tx.appointment.create({
        data: {
          appointment_code: `APT-${Date.now()}`,
          user_id: this.toBigIntId(user_id, 'user_id'),
          patient_id: patient_id,
          facility_id: slot.facility_id,
          doctor_id: slot.doctor_id,
          slot_id: slot_id,
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
        where: { slot_id: slot_id },
        data: {
          is_active: 0, // Đổi sang PENDING để Flutter hiện MÀU VÀNG
          status: SlotStatus.AVAILABLE,
          available_count: { decrement: 1 }
        },
      });
      console.log(`--- ĐÃ KHÓA SLOT ${slot_id} THÀNH CÔNG ---`);
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

    // Chèn sau khi kết thúc transaction
    setTimeout(async () => {
      try {
        const currentAppt = await this.prisma.appointment.findUnique({
          where: { appointment_id: appointment.appointment_id },
        });

        // Nếu vẫn là pending tức là chưa thanh toán xong
        if (currentAppt && currentAppt.status === AppointmentStatus.pending) {
          await this.prisma.$transaction([
            this.prisma.appointment.update({
              where: { appointment_id: appointment.appointment_id },
              data: { status: 'cancelled' as any },
            }),
            this.prisma.slot.update({
              where: { slot_id: slot_id },
              data: {
                is_active: 1, // Mở khóa lại slot về trạng thái hoạt động
                available_count: { increment: 1 }
              },
            }),
          ]);
          console.log(`[Timer] Đã kích hoạt lại slot ${slot_id} do hết hạn thanh toán.`);
        }
      } catch (error) {
        console.error('[Timer Error] Lỗi nhả slot:', error);
      }
    }, 300000); // 5 phút

    return okResponse('Create appointment successfully', {
      id: toNumberId(appointment.appointment_id),
      appointment_code: appointment.appointment_code,
      user_id: toNumberId(appointment.user_id),
      patient_id: toNumberId(appointment.patient_id),
      facility_id: toNumberId(appointment.facility_id),
      service_id: appointment.service_id ? toNumberId(appointment.service_id) : null,
      slot_id: toNumberId(appointment.slot_id),
      appointmentType: appointment.appointment_type,
      appointment_date: formatDateOnly(appointment.appointment_date),
      appointment_time: formatTimeOnly(appointment.appointment_time),
      status: appointment.status,
      paymentStatus: 'pending',
      total_amount: Number(appointment.total_amount),
      note: appointment.note,
      created_at: appointment.created_at,
    });
  }

  async getAppointmentById(user_id: string, appointment_id: string) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { appointment_id: this.toBigIntId(appointment_id, 'appointment_id') },
      include: {
        patient: true,
        doctor: true,
        facility: true,
        service: true,
        slot: true,
      },
    });

    if (!appointment || appointment.user_id !== this.toBigIntId(user_id, 'user_id')) {
      throw new NotFoundException('Appointment not found');
    }

    return okResponse('Get appointment detail successfully', {
      id: toNumberId(appointment.appointment_id),
      appointment_code: appointment.appointment_code,
      appointmentType: appointment.appointment_type,
      appointment_date: formatDateOnly(appointment.appointment_date),
      appointment_time: formatTimeOnly(appointment.appointment_time),
      status: appointment.status,
      note: appointment.note,
      total_amount: Number(appointment.total_amount),
      patient: appointment.patient
        ? {
            id: toNumberId(appointment.patient.patient_id),
            full_name: appointment.patient.full_name,
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
  async getUserAppointments(user_id: string) {
    const appointments = await this.prisma.appointment.findMany({
      where: { user_id: this.toBigIntId(user_id, 'user_id') },
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
      appointment_code: apt.appointment_code,
      appointmentType: apt.appointment_type,
      appointment_date: formatDateOnly(apt.appointment_date),
      appointment_time: formatTimeOnly(apt.appointment_time),
      status: apt.status,
      note: apt.note,
      symptomsNote: apt.symptoms_note,
      total_amount: Number(apt.total_amount),
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
            full_name: apt.patient.full_name,
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
