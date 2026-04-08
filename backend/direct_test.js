const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const patient = await prisma.patientProfile.findFirst();
  const facility = await prisma.facility.findFirst();
  const service = await prisma.service.findFirst({ where: { facility_id: facility.facility_id } });
  const doctor = await prisma.doctor.findFirst();
  
  const slot = await prisma.slot.findFirst({ 
    where: { 
      status: 'AVAILABLE',
      facility_id: facility.facility_id
    }
  });

  if (!patient || !facility || !service || !slot) {
    console.log("Missing data:", { patient: !!patient, facility: !!facility, service: !!service, slot: !!slot });
    return;
  }

  // Luồng tạo lịch (Mô phỏng logic của AppointmentsService)
  const appt = await prisma.appointment.create({
    data: {
      appointment_code: `APT-${Date.now().toString().slice(-6)}`,
      user_id: patient.user_id,
      patient_id: patient.patient_id,
      facility_id: facility.facility_id,
      doctor_id: doctor ? doctor.doctor_id : null,
      service_id: service.service_id,
      slot_id: slot.slot_id,
      appointment_date: slot.slot_date,
      appointment_time: slot.start_time,
      appointment_type: 'consultation',
      status: 'pending',
      total_amount: service.price,
      note: 'Auto-booking to verify system flow'
    }
  });
  
  // Cập nhật slot status (Mô phỏng Transaction của backend)
  await prisma.slot.update({
    where: { slot_id: slot.slot_id },
    data: { 
      available_count: slot.available_count - 1,
      status: slot.available_count - 1 <= 0 ? 'FULL' : 'AVAILABLE'
    }
  });

  // Luồng tạo Payment (Mô phỏng logic của PaymentsService)
  const payment = await prisma.payment.create({
    data: {
      appointment_id: appt.appointment_id,
      payment_method: 'vnpay',
      amount: appt.total_amount,
      transaction_code: `PAY-${Date.now()}`,
      status: 'pending'
    }
  });

  console.log("SUCCESS!");
  console.log("Appointment ID:", appt.appointment_id);
  console.log("Appointment Code:", appt.appointment_code);
  console.log("Payment Transaction:", payment.transaction_code);
}

main().catch(console.error).finally(() => prisma.$disconnect());
