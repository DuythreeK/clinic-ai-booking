const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const patient = await prisma.patientProfile.findFirst();
  const facility = await prisma.facility.findFirst();
  const service = await prisma.service.findFirst({ where: { facilityId: facility.facilityId } });
  const doctor = await prisma.doctor.findFirst();
  
  const slot = await prisma.slot.findFirst({ 
    where: { 
      status: 'AVAILABLE',
      facilityId: facility.facilityId
    }
  });

  if (!patient || !facility || !service || !slot) {
    console.log("Missing data:", { patient: !!patient, facility: !!facility, service: !!service, slot: !!slot });
    return;
  }

  // Luồng tạo lịch (Mô phỏng logic của AppointmentsService)
  const appt = await prisma.appointment.create({
    data: {
      appointmentCode: `APT-${Date.now().toString().slice(-6)}`,
      userId: patient.userId,
      patientId: patient.patientId,
      facilityId: facility.facilityId,
      doctorId: doctor ? doctor.doctorId : null,
      serviceId: service.serviceId,
      slotId: slot.slotId,
      appointmentDate: slot.slotDate,
      appointmentTime: slot.startTime,
      appointment_type: 'consultation',
      status: 'pending',
      totalAmount: service.price,
      note: 'Auto-booking to verify system flow'
    }
  });
  
  // Cập nhật slot status (Mô phỏng Transaction của backend)
  await prisma.slot.update({
    where: { slotId: slot.slotId },
    data: { 
      available_count: slot.available_count - 1,
      status: slot.available_count - 1 <= 0 ? 'FULL' : 'AVAILABLE'
    }
  });

  // Luồng tạo Payment (Mô phỏng logic của PaymentsService)
  const payment = await prisma.payment.create({
    data: {
      appointmentId: appt.appointmentId,
      payment_method: 'vnpay',
      amount: appt.totalAmount,
      transaction_code: `PAY-${Date.now()}`,
      status: 'pending'
    }
  });

  console.log("SUCCESS!");
  console.log("Appointment ID:", appt.appointmentId);
  console.log("Appointment Code:", appt.appointmentCode);
  console.log("Payment Transaction:", payment.transaction_code);
}

main().catch(console.error).finally(() => prisma.$disconnect());
