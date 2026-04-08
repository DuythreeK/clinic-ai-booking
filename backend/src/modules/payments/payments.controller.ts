import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { PaymentsService } from './payments.service';
import { CreatePaymentDto, PaymentCallbackDto } from './dto/payment.dto';

@Controller('payments')
export class PaymentsController {
  constructor(private paymentsService: PaymentsService) {}

  @Post()
  @UseGuards(JwtGuard)
  async createPayment(
    @CurrentUser('sub') user_id: string,
    @Body() dto: CreatePaymentDto,
  ) {
    return this.paymentsService.createPayment(user_id, dto);
  }

  @Post('callback')
  async callback(@Body() dto: PaymentCallbackDto) {
    return this.paymentsService.handleCallback(dto);
  }
}
