export class MedicalHistoryListItemDto {
  id!: number;
  title!: string;
  day!: string;
  monthYear!: string;
  doctor_id!: number;
  doctorName!: string;
  specialty!: string;
  feeLabel!: string;
  primaryStatus!: string;
  secondaryStatus!: string;
  orderNumber!: string;
  queueNumber!: string;
  clinicFeeLabel!: string;
  total_amountLabel!: string;
  symptomNote!: string | null;
  caseSummary!: string;
  fileName!: string | null;
  fileUrl!: string | null;
}

export class MedicalHistoryDetailDto extends MedicalHistoryListItemDto {
  appointment_code!: string;
  appointment_date!: string | null;
  appointment_time!: string | null;
  facilityName!: string;
  facilityAddress!: string;
  doctorRating!: number;
  reviewCount!: number;
  paymentStatus!: string | null;
  canReview!: boolean;
}
