export class MobileDoctorFacilityDto {
  id!: number;
  name!: string;
  type!: string;
  address!: string;
}

export class MobileDoctorCardDto {
  id!: number;
  name!: string;
  specialty!: string;
  focus!: string;
  imageUrl!: string | null;
  rating!: number;
  reviewCount!: number;
  priceValue!: number;
  priceLabel!: string;
  bookingToday!: number;
  yearsExperience!: number;
  patientsLabel!: string;
  nextAvailable!: string | null;
  gender!: string;
  email!: string | null;
  phone!: string | null;
  about!: string;
  certifications!: string[];
  facility!: MobileDoctorFacilityDto | null;
}

export class MobileDoctorReviewDto {
  id!: number;
  reviewerName!: string;
  reviewerAvatar!: string;
  rating!: number;
  comment!: string | null;
  createdAt!: Date;
}
