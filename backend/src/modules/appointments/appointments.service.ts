import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
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

  private createAppointmentCode() {
    // Create a semi-unique appointment code for human-readable reference
    return `APT-${Date.now()}-${randomUUID().slice(0, 8).toUpperCase()}`;
  }

  async createAppointment(userId: string, dto: CreateAppointmentDto) {
    /**
     * Tạo appointment (đặt lịch)
     * Quy trình:
     *  - Validate patient, slot và service
     *  - Trong `prisma.$transaction` kiểm tra duplicate, giảm available_count của slot (updateMany)
     *  - Nếu updateMany trả về 0 => slot đã hết chỗ -> throw
     *  - Tạo appointment và trả về dữ liệu đã format
     * Lưu ý concurrency: sử dụng conditional update (updateMany with available_count > 0) để giảm race.
     */
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

    const service = dto.serviceId
      ? await this.prisma.service.findUnique({
          where: { service_id: this.toBigIntId(dto.serviceId, 'serviceId') },
        })
      : null;

    const appointment = await this.prisma.$transaction(async (tx) => {
      const duplicate = await tx.appointment.findFirst({
        where: {
          slot_id: slotId,
          patient_id: patientId,
          status: {
            not: AppointmentStatus.cancelled,
          },
        },
      });
      if (duplicate) {
        throw new BadRequestException('Bệnh nhân đã có lịch ở khung giờ này');
      }

      const updatedSlot = await tx.slot.updateMany({
        where: {
          slot_id: slotId,
          facility_id: facilityId,
          is_active: 1,
          status: 'AVAILABLE',
          available_count: { gt: 0 },
        },
        data: {
          available_count: { decrement: 1 },
        },
      });

      if (updatedSlot.count === 0) {
        throw new BadRequestException('Slot đã hết chỗ');
      }

      const latestSlot = await tx.slot.findUnique({
        where: { slot_id: slotId },
        select: { available_count: true },
      });

      if (!latestSlot) {
        throw new BadRequestException('Slot đã hết chỗ');
      }

      if (latestSlot.available_count <= 0) {
        await tx.slot.update({
          where: { slot_id: slotId },
          data: { status: 'FULL' },
        });
      }

      const createdAppointment = await tx.appointment.create({
        data: {
          appointment_code: this.createAppointmentCode(),
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
    /**
     * Lấy chi tiết appointment cho user (kiểm tra quyền sở hữu)
     * Throws NotFoundException nếu không tồn tại hoặc không thuộc user.
     */
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
    /**
     * Lấy tất cả appointment của user, kèm thông tin doctor, service, slot
     * Trả về danh sách đã format.
     */
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
