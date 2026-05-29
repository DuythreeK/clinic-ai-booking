import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import {
  MedicalHistoryDetailDto,
  MedicalHistoryListItemDto,
} from './dto/mobile-medical-history.dto';
import { okResponse, paginatedResponse } from '@/common/utils/api-response';
import {
  formatCurrencyVnd,
  formatDateOnly,
  formatTimeOnly,
  toNumberId,
} from '@/common/utils/formatters';

@Injectable()
export class MedicalRecordsService {
  constructor(private prisma: PrismaService) {}

  private toBigIntId(id: string): bigint {
    return BigInt(id);
  }

  private monthYearLabel(value?: Date | null) {
    if (!value) return '';
    const date = new Date(value);
    return `Tháng ${date.getMonth() + 1}\n${date.getFullYear()}`;
  }

  private appointmentStatusLabel(status: string) {
    switch (status) {
      case 'completed':
        return 'Kết thúc';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'pending':
        return 'Chuẩn bị khám';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  private extractAttachment(attachments: unknown) {
    if (!Array.isArray(attachments) || attachments.length === 0) {
      return { fileName: null, fileUrl: null };
    }

    const first = attachments[0] as Record<string, unknown>;
    return {
      fileName:
        typeof first?.fileName === 'string'
          ? first.fileName
          : typeof first?.name === 'string'
            ? first.name
            : 'tai-lieu.pdf',
      fileUrl:
        typeof first?.fileUrl === 'string'
          ? first.fileUrl
          : typeof first?.url === 'string'
            ? first.url
            : null,
    };
  }

  private toListItem(record: any): MedicalHistoryListItemDto {
    /**
     * Chuyển một `MedicalRecord` sang item list dùng cho màn hình lịch sử khám
     * - Extract attachment, format fees và các label hiển thị
     */
    const attachment = this.extractAttachment(record.attachments);
    const amount = Number(record.appointment.total_amount ?? 0);
    const feeLabel = formatCurrencyVnd(amount) ?? '0đ';

    return {
      id: toNumberId(record.record_id)!,
      title: record.diagnosis,
      day: String(new Date(record.appointment.appointment_date).getDate()).padStart(2, '0'),
      monthYear: this.monthYearLabel(record.appointment.appointment_date),
      doctorId: toNumberId(record.doctor_id)!,
      doctorName: record.doctor.full_name,
      specialty: record.doctor.specialty?.name ?? 'Chưa cập nhật',
      feeLabel,
      primaryStatus: record.appointment.status === 'completed' ? 'NEW' : feeLabel,
      secondaryStatus: this.appointmentStatusLabel(record.appointment.status),
      orderNumber: record.appointment.appointment_code,
      queueNumber: record.appointment.appointment_code,
      clinicFeeLabel: feeLabel,
      totalAmountLabel: feeLabel,
      symptomNote: record.symptoms,
      caseSummary: record.diagnosis,
      fileName: attachment.fileName,
      fileUrl: attachment.fileUrl,
    };
  }

  async getMyMedicalRecords(userId: string) {
    /**
     * Lấy toàn bộ medical records của user (patient) kèm thông tin appointment, doctor
     * Output: paginatedResponse (hiện mặc định page 1, limit 10)
     */
    const records = await this.prisma.medicalRecord.findMany({
      where: {
        patient: {
          user_id: this.toBigIntId(userId),
        },
      },
      include: {
        doctor: {
          include: {
            specialty: true,
          },
        },
        appointment: {
          include: {
            facility: true,
            payments: true,
            review: true,
          },
        },
      },
      orderBy: { created_at: 'desc' },
    });

    const items = records.map((record) => this.toListItem(record));

    return paginatedResponse('Get medical records successfully', items, 1, 10, items.length);
  }

  async getMedicalRecordById(userId: string, id: string) {
    /**
     * Lấy chi tiết một medical record theo id
     * - Kiểm tra quyền (record.patient.user_id === userId)
     * - Gom các thông tin payment, review để trả về chi tiết
     */
    const record = await this.prisma.medicalRecord.findUnique({
      where: { record_id: this.toBigIntId(id) },
      include: {
        patient: true,
        doctor: {
          include: {
            specialty: true,
          },
        },
        appointment: {
          include: {
            facility: true,
            payments: true,
            review: true,
          },
        },
      },
    });

    if (!record || record.patient.user_id !== this.toBigIntId(userId)) {
      throw new NotFoundException('Medical record not found');
    }

    const [reviewAggregate] = await Promise.all([
      this.prisma.doctorReview.aggregate({
        where: {
          doctor_id: record.doctor_id,
          is_visible: 1,
        },
        _count: { review_id: true },
        _avg: { rating: true },
      }),
    ]);

    const base = this.toListItem(record);
    const payment = record.appointment.payments[0];
    const detail: MedicalHistoryDetailDto = {
      ...base,
      appointmentCode: record.appointment.appointment_code,
      appointmentDate: formatDateOnly(record.appointment.appointment_date),
      appointmentTime: formatTimeOnly(record.appointment.appointment_time),
      facilityName: record.appointment.facility.name,
      facilityAddress: [
        record.appointment.facility.address_detail,
        record.appointment.facility.ward,
        record.appointment.facility.district,
        record.appointment.facility.province,
      ]
        .filter(Boolean)
        .join(', '),
      doctorRating: Number(reviewAggregate._avg.rating ?? 0),
      reviewCount: reviewAggregate._count.review_id,
      paymentStatus: payment?.status ?? null,
      canReview: !record.appointment.review,
      caseSummary: [
        record.diagnosis,
        record.treatment_plan,
        record.follow_up_date ? `Tái khám: ${formatDateOnly(record.follow_up_date)}` : null,
      ]
        .filter(Boolean)
        .join('\n\n'),
    };

    return okResponse('Get medical record detail successfully', detail);
  }
}
