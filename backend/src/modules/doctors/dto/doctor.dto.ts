export class CreateDoctorDto {
  licenseNumber: string | undefined;
  specialtyId?: string;
  bio?: string;
  yearsExperience?: number;
}

export class UpdateDoctorDto {
  licenseNumber?: string;
  specialtyId?: string;
  bio?: string;
  yearsExperience?: number;
}

export class ApproveDoctorDto {
  isApproved: boolean | undefined;
}
