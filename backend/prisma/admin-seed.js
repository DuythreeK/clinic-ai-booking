const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🚀 Starting Comprehensive Seeding...');

  const sharedPassword = await bcrypt.hash('Admin@123', 10);
  const now = new Date();
  const tomorrow = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(0, 0, 0, 0);

  // 1. Clear Data
  console.log('🧹 Clearing existing data...');
  const tables = [
    'notification', 'doctorReview', 'medicalRecord', 'appointment',
    'slot', 'schedule', 'room', 'doctor', 'patientProfile',
    'facility', 'specialty', 'adminProfile', 'user'
  ];
  for (const table of tables) {
    if (prisma[table]) await prisma[table].deleteMany();
  }

  // 2. Specialties
  console.log('📋 Creating Specialties...');
  const specsData = [
    { name: 'Nội Tổng Quát', description: 'General Internal Medicine' },
    { name: 'Nhi Khoa', description: 'Pediatrics' },
    { name: 'Sản Phụ Khoa', description: 'Obstetrics and Gynecology' },
    { name: 'Tim Mạch', description: 'Cardiology' },
    { name: 'Da Liễu', description: 'Dermatology' }
  ];
  const specs = [];
  for (const s of specsData) {
    specs.push(await prisma.specialty.create({ data: { ...s, isActive: 1 } }));
  }

  // 3. Facilities
  console.log('🏥 Creating Facilities...');
  const facility1 = await prisma.facility.create({
    data: {
      name: 'Phòng khám Đa khoa Trung tâm',
      facility_type: 'clinic',
      address_detail: '123 Nguyễn Trãi, Thanh Xuân, Hà Nội',
      phone: '02431234567',
    }
  });
  const facility2 = await prisma.facility.create({
    data: {
      name: 'Chi nhánh Quận 1',
      facility_type: 'clinic',
      address_detail: '456 Lê Lợi, Quận 1, TP.HCM',
      phone: '02831234567',
    }
  });

  // 4. Rooms
  console.log('🚪 Creating Rooms...');
  const rooms = [];
  for (let i = 0; i < specs.length; i++) {
    rooms.push(await prisma.room.create({
      data: {
        name: `Phòng ${i + 1}01`,
        code: `R${i + 1}01`,
        specialty_id: specs[i].specialty_id,
        floor: 1
      }
    }));
  }

  // 5. Admin User
  console.log('👤 Creating Admin...');
  await prisma.user.create({
    data: {
      full_name: 'Quản trị viên',
      email: 'admin@clinic.local',
      phone: '0900000001',
      password_hash: sharedPassword,
      role: 'admin',
    }
  });

  // 6. Doctors & Profiles
  console.log('👨‍⚕️ Creating Doctors...');
  const docNames = ['Nguyễn Văn A', 'Trần Thị B', 'Lê Văn C', 'Phạm Thị D', 'Hoàng Văn E'];
  const doctors = [];
  for (let i = 0; i < docNames.length; i++) {
    const u = await prisma.user.create({
      data: {
        full_name: docNames[i],
        email: `dr.${i + 1}@clinic.local`,
        phone: `098800000${i + 1}`,
        password_hash: sharedPassword,
        role: 'doctor',
      }
    });
    doctors.push(await prisma.doctor.create({
      data: {
        user_id: u.user_id,
        full_name: u.full_name,
        specialty_id: specs[i % specs.length].specialty_id,
        facility_id: i < 3 ? facility1.facility_id : facility2.facility_id,
        experience_years: 5 + i,
        consultation_fee: 200000 + (i * 50000),
        license_number: `DOC-00${i + 1}`,
      }
    }));
  }

  // 7. Patients
  console.log('👥 Creating Patients...');
  const patients = [];
  for (let i = 0; i < 10; i++) {
    const u = await prisma.user.create({
      data: {
        full_name: `Bệnh nhân ${i + 1}`,
        email: `patient.${i + 1}@mail.com`,
        phone: `091100000${i}`,
        password_hash: sharedPassword,
        role: 'patient',
      }
    });
    patients.push(await prisma.patientProfile.create({
      data: {
        user_id: u.user_id,
        full_name: u.full_name,
        phone_number: u.phone, // Map user phone to patient profile phone
        gender: i % 2 === 0 ? 'male' : 'female',
        date_of_birth: new Date(1980 + i, 0, 1),
        address_detail: 'Hà Nội',
      }
    }));
  }

  // 8. Schedules & Slots & Appointments
  console.log('📅 Generating Schedules & Appointments...');
  for (let d = 0; d < 5; d++) {
    const date = new Date(tomorrow);
    date.setDate(date.getDate() + d);

    for (const doc of doctors) {
      // 1. Schedule
      const sch = await prisma.schedule.create({
        data: {
          doctor_id: doc.doctor_id,
          room_id: doc.room_id || null, // Assign doctor's room to schedule
          workDate: date,
          startTime: new Date(date.getTime() + 8 * 3600000),
          endTime: new Date(date.getTime() + 17 * 3600000),
          maxSlots: 10,
        }
      });

      // 2. Slots (8:00 to 12:00)
      for (let h = 8; h < 12; h++) {
        const slot = await prisma.slot.create({
          data: {
            doctor_id: doc.doctor_id,
            facility_id: doc.facility_id,
            slot_date: date,
            start_time: new Date(date.getTime() + h * 3600000),
            end_time: new Date(date.getTime() + h * 3600000 + 30 * 60000),
          }
        });

        // 3. Appointments (Sample 50%)
        if (Math.random() > 0.5) {
          const pat = patients[Math.floor(Math.random() * patients.length)];
          const status = d === 0 ? 'confirmed' : 'pending';
          
          const appt = await prisma.appointment.create({
            data: {
              appointment_code: `APT-${doc.doctor_id}-${pat.patient_id}-${d}-${h}`,
              user_id: pat.user_id, // booked by
              patient_id: pat.patient_id,
              facility_id: doc.facility_id,
              doctor_id: doc.doctor_id,
              slot_id: slot.slot_id,
              schedule_id: sch.scheduleId,
              appointment_type: 'consultation',
              appointment_date: date,
              appointment_time: slot.start_time,
              status: status,
              total_amount: doc.consultation_fee || 300000,
            }
          });

          // 4. Medical Record for first day if random
          if (d === 0 && Math.random() > 0.7) {
            await prisma.appointment.update({ where: { appointment_id: appt.appointment_id }, data: { status: 'completed' }});
            await prisma.medicalRecord.create({
              data: {
                appointment_id: appt.appointment_id,
                patient_id: pat.patient_id,
                doctor_id: doc.doctor_id,
                diagnosis: 'Cảm cúm thông thường',
                treatment_plan: 'Nghỉ ngơi và uống nhiều nước.',
                is_locked: 1,
              }
            });

            // Review
            await prisma.doctorReview.create({
              data: {
                doctor_id: doc.doctor_id,
                user_id: pat.user_id,
                appointment_id: appt.appointment_id,
                rating: 5,
                comment: 'Bác sĩ rất thân thiện.',
              }
            });
          }
        }
      }
    }
  }

  console.log('✨ SEEDING COMPLETE!');
}

main()
  .catch((e) => {
    console.error('Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
