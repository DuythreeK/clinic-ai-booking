export class CreateClinicDto {
  name!: string;
  address!: string;
  city!: string;
  country!: string;
  phone?: string;
  email?: string;
}