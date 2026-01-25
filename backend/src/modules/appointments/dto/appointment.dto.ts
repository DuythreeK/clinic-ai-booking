export class CreateAppointmentDto {
  patientId!: string;
  doctorId!: string;
  slotId!: string;
  reason?: string;
  attachments?: string;
}

export class UpdateAppointmentDto {
  reason?: string;
  attachments?: string;
}

export class UpdateAppointmentStatusDto {
  status!: string;
}

export class AddDoctorNotesDto {
  doctorNotes!: string;
  doctorAdvice?: string;
}

export class RescheduleAppointmentDto {
  newSlotId!: string;
  reason?: string;
}

export class AppointmentFilterDto {
  patientId?: string;
  doctorId?: string;
  status?: string;
  fromDate?: string;
  toDate?: string;
}
