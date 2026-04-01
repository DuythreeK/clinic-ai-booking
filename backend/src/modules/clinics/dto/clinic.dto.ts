export class CreateClinicDto {
  name!: string;
  address!: string;
  city!: string;
  country!: string;
  phone?: string;
  email?: string;
  hours?: string; // JSON string with opening hours
}

export class UpdateClinicDto {
  name?: string;
  address?: string;
  city?: string;
  country?: string;
  phone?: string;
  email?: string;
  hours?: string;
}
