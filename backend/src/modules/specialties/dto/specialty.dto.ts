export class CreateSpecialtyDto {
  name: string;
  description?: string;
  icon?: string;
}

export class UpdateSpecialtyDto {
  name?: string;
  description?: string;
  icon?: string;
}
