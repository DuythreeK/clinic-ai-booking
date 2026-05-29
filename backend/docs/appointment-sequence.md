# Vaccination Booking Sequence Diagram

Below is the sequence diagram for the vaccination booking flow implemented in this project. It uses the shared `AppointmentsController` / `AppointmentsService`, but the selected `serviceId` comes from the vaccination package flow.

```mermaid
sequenceDiagram
  participant Client
  participant AppointmentsController as "AppointmentsController\n(create)"
  participant AppointmentsService as "AppointmentsService\n(createAppointment)"
  participant PrismaService as "PrismaService (prisma client)"
  participant DB as "DB (tblSlots, tblAppointment, tblPatientProfile, tblService)"

  Client->>AppointmentsController: POST /appointments { CreateAppointmentDto }
  activate AppointmentsController
  AppointmentsController->>AppointmentsService: createAppointment(userId, dto)
  activate AppointmentsService

  %% 1. Validate patient
  AppointmentsService->>PrismaService: patientProfile.findUnique(where: patientId)
  PrismaService-->>AppointmentsService: patient | null
  alt patient missing or not owned
    AppointmentsService-->>AppointmentsController: throw NotFoundException("Patient profile not found")
  end

  %% 2. Validate slot
  AppointmentsService->>PrismaService: slot.findUnique(where: slotId, include: { doctor })
  PrismaService-->>AppointmentsService: slot | null
  alt slot invalid or inactive
    AppointmentsService-->>AppointmentsController: throw NotFoundException("Slot not found")
  end

  AppointmentsService->>PrismaService: service.findUnique(where: serviceId)  // optional
  PrismaService-->>AppointmentsService: service | null

  %% 3. Transaction: check duplicate, decrement slot, create appointment
  AppointmentsService->>PrismaService: $transaction(tx => { 
    tx.appointment.findFirst({ slot_id, patient_id, status not cancelled }) 
  })
  PrismaService-->>AppointmentsService: duplicate | null
  alt duplicate exists
    AppointmentsService-->>PrismaService: tx.rollback (implicit via exception)
    AppointmentsService-->>AppointmentsController: throw BadRequestException('Bệnh nhân đã có lịch...')
  else
    AppointmentsService->>PrismaService: tx.slot.updateMany(where: slot_id & status AVAILABLE & available_count > 0, data: decrement available_count)
    PrismaService-->>AppointmentsService: { count }
    alt count === 0
      AppointmentsService-->>PrismaService: throw BadRequestException('Slot đã hết chỗ')
    else
      AppointmentsService->>PrismaService: tx.slot.findUnique(select: available_count)
      PrismaService-->>AppointmentsService: latestSlot
      alt latestSlot.available_count <= 0
        AppointmentsService->>PrismaService: tx.slot.update({ status: 'FULL' })
      end
      AppointmentsService->>PrismaService: tx.appointment.create({...})
      PrismaService-->>AppointmentsService: createdAppointment
      AppointmentsService->>PrismaService: tx.appointment.findUniqueOrThrow({ where: createdId, include: patient, doctor, facility, service, slot })
      PrismaService-->>AppointmentsService: appointmentWithIncludes
    end
  end

  %% 4. Return
  AppointmentsService-->>AppointmentsController: okResponse({ appointment summary })
  deactivate AppointmentsService
  AppointmentsController-->>Client: HTTP 201 Created (okResponse)
  deactivate AppointmentsController
```

If you want an exported PNG/SVG or a Visual Paradigm file, tell me which format and I'll generate it.