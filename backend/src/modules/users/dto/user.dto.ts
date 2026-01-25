export class CreateUserDto {
  email: string;
  password: string;
  firstName?: string;
  lastName?: string;
  phone?: string;
  role: string; // PATIENT, DOCTOR, ADMIN
}

export class UpdateUserDto {
  firstName?: string;
  lastName?: string;
  phone?: string;
  avatar?: string;
}

export class ChangePasswordDto {
  currentPassword: string;
  newPassword: string;
}
