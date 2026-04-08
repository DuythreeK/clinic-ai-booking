import { ApptStatus, Gender, NotifType, PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Clearing old data...');
  await prisma.notification.deleteMany();
  await prisma.review.deleteMany();
  await prisma.medicalRecord.deleteMany();
  await prisma.appointment.deleteMany();
  await prisma.schedule.deleteMany();
  await prisma.room.deleteMany();
  await prisma.doctor.deleteMany();
  await prisma.patient.deleteMany();
  await prisma.user.deleteMany();
  await prisma.specialty.deleteMany();

  console.log('Seeding Specialties...');
  const specialtiesData = [
    { name: 'Nội Tổng Quát', code: 'NOI', description: 'Khám các bệnh lý nội khoa tiêu hóa, hô hấp, tim mạch cơ bản.' },
    { name: 'Ngoại Khoa', code: 'NGOAI', description: 'Khám và tư vấn phẫu thuật, các bệnh lý ngoại khoa.' },
    { name: 'Nhi Khoa', code: 'NHI', description: 'Khám chữa bệnh cho trẻ em và trẻ sơ sinh.' },
    { name: 'Sản Phụ Khoa', code: 'SAN', description: 'Khám thai, tư vấn sinh sản và các bệnh lý phụ khoa.' },
    { name: 'Tai Mũi Họng', code: 'TMH', description: 'Khám nội soi Tai Mũi Họng, viêm xoang, thanh quản.' },
    { name: 'Răng Hàm Mặt', code: 'RHM', description: 'Khám nha khoa tổng quát, nhổ răng, niềng răng.' },
    { name: 'Da Liễu', code: 'DA', description: 'Khám và điều trị các bệnh về da, tóc, móng.' },
    { name: 'Mắt', code: 'MAT', description: 'Khám thị lực, đo tật khúc xạ, các bệnh lý về mắt.' },
    { name: 'Tim Mạch', code: 'TIM', description: 'Khám chuyên sâu bệnh lý tim mạch, đo điện tâm đồ.' },
    { name: 'Thần Kinh', code: 'THAN', description: 'Khám đau đầu, mất ngủ, rối loạn tiền đình.' }
  ];

  const specs: any[] = [];
  for (const s of specialtiesData) {
    const sp = await prisma.specialty.create({
      data: { name: s.name, code: s.code, description: s.description, isActive: true },
    });
    specs.push(sp);
  }

  console.log('Seeding Base Users...');
  const sharedPassword = await bcrypt.hash(process.env.ADMIN_PASSWORD || 'Admin@123', 10);

  await prisma.user.create({
    data: {
      fullName: 'Quản trị viên Hệ thống',
      email: 'admin@clinic.local',
      phone: '0900000001',
      passwordHash: sharedPassword,
      role: UserRole.admin,
    },
  });

  await prisma.user.create({
    data: {
      fullName: 'Lễ tân Tầng 1',
      email: 'reception@clinic.local',
      phone: '0900000002',
      passwordHash: sharedPassword,
      role: UserRole.receptionist,
    },
  });

  console.log('Seeding Rooms...');
  const rooms: any[] = [];
  for (let i = 0; i < specs.length; i++) {
    const r1 = await prisma.room.create({
      data: { name: `Phòng ${i + 1}01`, code: `P${i + 1}01`, specialtyId: specs[i].id, floor: i < 5 ? 1 : 2 },
    });
    const r2 = await prisma.room.create({
      data: { name: `Phòng ${i + 1}02 (VIP)`, code: `P${i + 1}02`, specialtyId: specs[i].id, floor: i < 5 ? 1 : 2 },
    });
    rooms.push(r1, r2);
  }
  const generalRoom = await prisma.room.create({
    data: { name: 'Phòng Đa Năng 1', code: 'P-GEN1', floor: 1 },
  });

  console.log('Seeding Doctors...');
  const docNames = [
    { title: 'ThS.BS', name: 'Nguyễn Trường Giang', exp: 12, fee: 350000 },
    { title: 'BS.CKI', name: 'Trần Thu Hà', exp: 8, fee: 250000 },
    { title: 'PGS.TS', name: 'Lê Đình Bảo', exp: 20, fee: 500000 },
    { title: 'BS.CKII', name: 'Phạm Mai Anh', exp: 15, fee: 400000 },
    { title: 'ThS.BS', name: 'Võ Minh Trí', exp: 10, fee: 300000 },
    { title: 'BS', name: 'Hoàng Bích Hạnh', exp: 5, fee: 200000 },
    { title: 'BS.CKI', name: 'Đặng Tuấn Tú', exp: 7, fee: 250000 },
    { title: 'ThS.BS', name: 'Vương Bảo Ngọc', exp: 11, fee: 300000 },
    { title: 'BS', name: 'Đỗ Hữu Thắng', exp: 4, fee: 150000 },
    { title: 'BS.CKII', name: 'Ngô Kim Liên', exp: 18, fee: 450000 }
  ];

  const doctors: any[] = [];
  for (let i = 0; i < docNames.length; i++) {
    const u = await prisma.user.create({
      data: {
        fullName: docNames[i].name,
        email: `dr.${docNames[i].name.split(' ').pop()?.toLowerCase()}${i}@clinic.local`,
        phone: `09880000${i.toString().padStart(2, '0')}`,
        passwordHash: sharedPassword,
        role: UserRole.doctor,
      },
    });

    const d = await prisma.doctor.create({
      data: {
        userId: u.id,
        specialtyId: specs[i % specs.length].id,
        title: docNames[i].title,
        licenseNumber: `CCHN-${2000+i}`,
        bio: `Bác sĩ ${docNames[i].name} có ${docNames[i].exp} năm kinh nghiệm trong lĩnh vực ${specs[i % specs.length].name}. Từng công tác tại các bệnh viện lớn tuyến trung ương.`,
        yearsExperience: docNames[i].exp,
        consultationFee: docNames[i].fee,
        avgRating: 4.5 + (Math.random() * 0.5),
      },
    });
    doctors.push(d);
  }

  console.log('Seeding Patients...');
  const patientNames = [
    'Trần Văn An', 'Nguyễn Thị Hoa', 'Lý Tấn Tài', 'Phạm Quỳnh Như', 'Hoàng Minh Tuấn', 
    'Lê Ngọc Hà', 'Vũ Văn Thanh', 'Bùi Thị Lan', 'Trịnh Quốc Bảo', 'Đỗ Mai Trang',
    'Ngô Quang Đăng', 'Lương Bích Hữu', 'Hồ Yến Nhi', 'Thái Kim Anh', 'Đinh Tiến Đạt',
    'Châu Tinh Trì', 'Vương Đình Lộc', 'Tăng Thanh Hà', 'Mai Khôi', 'Khổng Tú Quỳnh'
  ];
  
  const patients: any[] = [];
  for (let i = 0; i < patientNames.length; i++) {
    const p = await prisma.patient.create({
      data: {
        fullName: patientNames[i],
        phone: `0911000${i.toString().padStart(3, '0')}`,
        email: `benhnhan${i}@mail.com`,
        gender: i % 2 === 0 ? Gender.male : Gender.female,
        dob: new Date(1970 + Math.floor(Math.random() * 40), Math.floor(Math.random() * 12), Math.floor(Math.random() * 28) + 1),
        address: `${Math.floor(Math.random() * 100) + 1} Đường Nguyễn Trãi, Quận Thanh Xuân, Hà Nội`,
      },
    });
    patients.push(p);
  }

  console.log('Seeding Schedules for the upcoming week...');
  const schedules: any[] = [];
  const today = new Date();
  today.setHours(0,0,0,0);
  
  for (let i = 0; i < doctors.length; i++) {
    for (let d = 1; d <= 7; d++) {
      // 70% chance doctor works on a given day
      if (Math.random() < 0.3) continue;

      const wDate = new Date(today.getTime() + (d * 86400000));
      
      const sType = Math.random() > 0.5 ? 'Morning' : 'Afternoon';
      const startTime = new Date(wDate);
      const endTime = new Date(wDate);
      
      if (sType === 'Morning') {
        startTime.setHours(8, 0, 0, 0);
        endTime.setHours(12, 0, 0, 0);
      } else {
        startTime.setHours(13, 30, 0, 0);
        endTime.setHours(17, 30, 0, 0);
      }

      const roomMatch = rooms.find(r => r.specialtyId === doctors[i].specialtyId) || generalRoom;

      const sch = await prisma.schedule.create({
        data: {
          doctorId: doctors[i].id,
          roomId: roomMatch.id,
          workDate: wDate,
          startTime: startTime,
          endTime: endTime,
          slotDurationMin: 30,
          maxSlots: 20,
          bookedSlots: 0,
        },
      });
      schedules.push(sch);
    }
  }

  console.log('Seeding Appointments...');
  for (let i = 0; i < 80; i++) {
    const sch = schedules[Math.floor(Math.random() * schedules.length)];
    const pat = patients[Math.floor(Math.random() * patients.length)];

    // Skip if patient already has appt in this schedule
    const check = await prisma.appointment.findFirst({ where: { scheduleId: sch.id, patientId: pat.id }});
    if (check) continue;

    const statuses = [
      ApptStatus.pending,
      ApptStatus.confirmed,
      ApptStatus.checked_in,
      ApptStatus.in_progress,
      ApptStatus.completed,
      ApptStatus.no_show,
      ApptStatus.cancelled,
    ];
    const status = statuses[Math.floor(Math.random() * statuses.length)];

    const apptDate = sch.workDate;
    const apptTime = new Date(sch.startTime.getTime() + (sch.bookedSlots * 30 * 60000));

    const appt = await prisma.appointment.create({
      data: {
        refCode: `PKC-${apptDate.getFullYear()}${(apptDate.getMonth()+1).toString().padStart(2,'0')}${apptDate.getDate().toString().padStart(2,'0')}-${Math.floor(Math.random()*9000)+1000}`,
        patientId: pat.id,
        doctorId: sch.doctorId,
        scheduleId: sch.id,
        apptDate: apptDate,
        apptTime: apptTime,
        queueNumber: sch.bookedSlots + 1,
        status: status,
        reason: 'Khám tổng quát định kỳ, thường xuyên mệt mỏi.',
      },
    });

    await prisma.schedule.update({
      where: { id: sch.id },
      data: { bookedSlots: sch.bookedSlots + 1 },
    });
    sch.bookedSlots += 1;

    if (status === ApptStatus.completed) {
      await prisma.medicalRecord.create({
        data: {
          appointmentId: appt.id,
          patientId: pat.id,
          doctorId: sch.doctorId,
          diagnosis: 'Cơ thể suy nhược, cần nghỉ ngơi và bồi bổ.',
          treatmentPlan: 'Uống thuốc theo toa, tái khám sau 1 tháng nếu không đỡ.',
          isLocked: true,
        }
      });
      
      await prisma.patient.update({
        where: { id: pat.id },
        data: {
          totalVisits: { increment: 1 },
          lastVisitDate: apptDate,
        },
      });
      
      if (Math.random() > 0.5) {
        await prisma.review.create({
          data: {
            appointmentId: appt.id,
            patientId: pat.id,
            doctorId: sch.doctorId,
            rating: Math.floor(Math.random() * 2) + 4,
            comment: 'Bác sĩ rất nhiệt tình và chu đáo.',
          }
        });
      }
    }
  }

  console.log('----------------------------------------------------');
  console.log('✅ SEED HOÀN TẤT VỚI DỮ LIỆU MẪU TIẾNG VIỆT THỰC TẾ!');
  console.log('----------------------------------------------------');
  console.log(`- Tài khoản Admin: admin@clinic.local / Admin@123`);
  console.log(`- Tài khoản Lễ tân: reception@clinic.local / Admin@123`);
  console.log(`- Và 10 tài khoản Bác sĩ giả lập (Mật khẩu: Admin@123)`);
  console.log(`- Chuyên khoa: ${specs.length} | Phòng: ${rooms.length+1} | Bệnh nhân: ${patients.length} | Ca trực mới: ${schedules.length}`);
}

main()
  .catch((e) => {
    console.error('Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
