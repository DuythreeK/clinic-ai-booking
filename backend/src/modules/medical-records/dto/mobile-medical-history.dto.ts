export class MedicalHistoryListItemDto {
  id!: number;
  title!: string;
  day!: string;
  monthYear!: string;
  doctorId!: number;
  doctorName!: string;
  specialty!: string;
  feeLabel!: string;
  primaryStatus!: string;
  secondaryStatus!: string;
  orderNumber!: string;
  queueNumber!: string;
  clinicFeeLabel!: string;
  totalAmountLabel!: string;
  symptomNote!: string | null;
  caseSummary!: string;
  fileName!: string | null;
  fileUrl!: string | null;
}

export class MedicalHistoryDetailDto extends MedicalHistoryListItemDto {
  appointmentCode!: string;
  appointmentDate!: string | null;
  appointmentTime!: string | null;
  facilityName!: string;
  facilityAddress!: string;
  doctorRating!: number;
  reviewCount!: number;
  paymentStatus!: string | null;
  canReview!: boolean;
}
