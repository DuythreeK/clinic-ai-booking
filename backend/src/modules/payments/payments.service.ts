import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreatePaymentDto, PaymentCallbackDto } from './dto/payment.dto';
import { okResponse } from '@/common/utils/api-response';
import { toNumberId } from '@/common/utils/formatters';

@Injectable()
export class PaymentsService {
  constructor(private prisma: PrismaService) {}

  private toBigIntId(id: string): bigint {
    return BigInt(id);
  }

  async createPayment(user_id: string, dto: CreatePaymentDto) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { appointment_id: this.toBigIntId(dto.appointment_id) },
    });

    if (!appointment || appointment.user_id !== this.toBigIntId(user_id)) {
      throw new NotFoundException('Appointment not found');
    }

    const payment = await this.prisma.payment.create({
      data: {
        appointment_id: appointment.appointment_id,
        payment_method: dto.paymentMethod as any,
        amount: appointment.total_amount,
        transaction_code: `PAY-${Date.now()}`,
      },
    });

    return okResponse('Create payment successfully', {
      id: toNumberId(payment.payment_id),
      appointment_id: toNumberId(payment.appointment_id),
      paymentMethod: payment.payment_method,
      amount: Number(payment.amount),
      status: payment.status,
      paymentUrl: `https://sandbox.vnpay.vn/example?txnRef=${payment.transaction_code}`,
    });
  }

  async handleCallback(dto: PaymentCallbackDto) {
    const payment = await this.prisma.payment.findUnique({
      where: { transaction_code: dto.transactionCode },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    const result = await this.prisma.$transaction(async (tx) => {
        // 1. Cập nhật trạng thái Payment
        const updatedPayment = await tx.payment.update({
          where: { payment_id: payment.payment_id },
          data: {
            status: dto.status as any,
            error_message: dto.errorMessage,
            paid_at: dto.status === 'success' ? new Date() : undefined,
          },
        });

        // 2. Nếu thanh toán THÀNH CÔNG, cập nhật Appointment và Slot
        if (dto.status === 'success') {
          // Đổi trạng thái lịch hẹn sang 'confirmed'
          const appointment = await tx.appointment.update({
            where: { appointment_id: payment.appointment_id },
            data: { status: 'confirmed' as any }, // 'confirmed' hoặc trạng thái bạn quy định
          });

          // Đổi trạng thái Slot sang 'FULL' để hiện MÀU ĐỎ trên Flutter
          await tx.slot.update({
            where: { slot_id: appointment.slot_id },
            data: { status: 'FULL' },
          });
        }
        // Nếu thanh toán THẤT BẠI, bạn có thể giữ nguyên 'pending' hoặc hủy tùy kịch bản

        return updatedPayment;
      });

    return okResponse('Payment callback processed successfully', {
      appointment_id: toNumberId(result.appointment_id),
      paymentStatus: result.status,
    });
  }
}
