import { IsOptional, IsString } from 'class-validator';

export class CreatePaymentDto {
  @IsString()
  appointment_id!: string;

  @IsString()
  paymentMethod!: string;
}

export class PaymentCallbackDto {
  @IsString()
  transactionCode!: string;

  @IsString()
  status!: string;

  @IsOptional()
  @IsString()
  errorMessage?: string;
}
