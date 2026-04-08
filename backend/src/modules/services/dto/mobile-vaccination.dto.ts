export class VaccinationFacilityDto {
  id!: number;
  name!: string;
  address!: string;
  type!: string;
  rating!: number;
}

export class VaccinationPackageDto {
  id!: number;
  title!: string;
  facilityId!: number;
  facilityName!: string;
  facilityAddress!: string;
  priceValue!: number;
  priceLabel!: string;
  note!: string;
  badge!: string;
}

export class VaccinationSlotItemDto {
  slotId!: number;
  startTime!: string | null;
  endTime!: string | null;
  availableCount!: number;
}

export class VaccinationSlotGroupDto {
  date!: string;
  weekdayLabel!: string;
  morningSlots!: VaccinationSlotItemDto[];
  afternoonSlots!: VaccinationSlotItemDto[];
}

export class VaccinationBookingDetailDto {
  serviceId!: number;
  serviceName!: string;
  specialty!: string;
  servicePriceValue!: number;
  servicePriceLabel!: string;
  note!: string;
  facility!: VaccinationFacilityDto;
  slots!: VaccinationSlotGroupDto[];
}
