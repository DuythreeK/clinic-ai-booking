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

  async createPayment(userId: string, dto: CreatePaymentDto) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { appointmentId: this.toBigIntId(dto.appointmentId) },
    });

    if (!appointment || appointment.userId !== this.toBigIntId(userId)) {
      throw new NotFoundException('Appointment not found');
    }

    const payment = await this.prisma.payment.create({
      data: {
        appointmentId: appointment.appointmentId,
        payment_method: dto.paymentMethod as any,
        amount: appointment.totalAmount,
        transaction_code: `PAY-${Date.now()}`,
      },
    });

    return okResponse('Create payment successfully', {
      id: toNumberId(payment.payment_id),
      appointmentId: toNumberId(payment.appointmentId),
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

    const updated = await this.prisma.payment.update({
      where: { payment_id: payment.payment_id },
      data: {
        status: dto.status as any,
        error_message: dto.errorMessage,
        paid_at: dto.status === 'success' ? new Date() : undefined,
      },
    });

    return okResponse('Payment callback processed successfully', {
      appointmentId: toNumberId(updated.appointmentId),
      paymentStatus: updated.status,
    });
  }
}
