import { PrismaClient, UserRole, FacilityType } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Đang bắt đầu nạp dữ liệu mẫu (seeding)...');

  // 1. Dọn dẹp dữ liệu cũ (Xóa theo thứ tự để tránh lỗi khóa ngoại)
  console.log('🧹 Đang dọn dẹp dữ liệu cũ...');
  await prisma.doctorReview.deleteMany();
  await prisma.medicalRecord.deleteMany();
  await prisma.appointmentStatusLog.deleteMany();
  await prisma.appointment.deleteMany();
  await prisma.slot.deleteMany();
  await prisma.doctor.deleteMany();
  await prisma.facility.deleteMany();
  await prisma.specialty.deleteMany();
  await prisma.patientProfile.deleteMany();
  await prisma.user.deleteMany();

  const hashedPassword = await bcrypt.hash('password123', 10);

  // 2. Tạo Chuyên khoa
  console.log('🧬 Đang tạo chuyên khoa...');
  const specialtiesData = [
    { name: 'Nội tổng quát', description: 'Khám sức khỏe đa khoa và tư vấn tổng quát' },
    { name: 'Tim mạch', description: 'Chuyên khoa điều trị các bệnh lý về tim và mạch máu' },
    { name: 'Nhi khoa', description: 'Chăm sóc sức khỏe toàn diện cho trẻ em' },
    { name: 'Sản phụ khoa', description: 'Chăm sóc sức khỏe phụ nữ và thai sản' },
    { name: 'Răng Hàm Mặt', description: 'Điều trị và thẩm mỹ nha khoa' },
  ];

  const createdSpecialties = await Promise.all(
    specialtiesData.map(data => prisma.specialty.create({ data }))
  );

  // 3. Danh sách 20 Cơ sở y tế (Hà Nội & HCM)
  console.log('🏥 Đang tạo 20 bệnh viện và phòng khám...');
  const facilitiesData = [
    // HÀ NỘI
    { name: "Bệnh viện Bạch Mai", type: FacilityType.hospital, address: "78 Giải Phóng, Đống Đa, Hà Nội", province: "Hà Nội", district: "Đống Đa" },
    { name: "Bệnh viện Việt Đức", type: FacilityType.hospital, address: "40 Tràng Thi, Hoàn Kiếm, Hà Nội", province: "Hà Nội", district: "Hoàn Kiếm" },
    { name: "Bệnh viện Trung ương Quân đội 108", type: FacilityType.hospital, address: "1 Trần Hưng Đạo, Hai Bà Trưng, Hà Nội", province: "Hà Nội", district: "Hai Bà Trưng" },
    { name: "Bệnh viện Đa khoa Tâm Anh", type: FacilityType.hospital, address: "108 Hoàng Như Tiếp, Long Biên, Hà Nội", province: "Hà Nội", district: "Long Biên" },
    { name: "Bệnh viện Nhi Trung ương", type: FacilityType.hospital, address: "18/879 La Thành, Đống Đa, Hà Nội", province: "Hà Nội", district: "Đống Đa" },
    { name: "Phòng khám Đa khoa Thu Cúc TCI", type: FacilityType.clinic, address: "286 Thụy Khuê, Tây Hồ, Hà Nội", province: "Hà Nội", district: "Tây Hồ" },
    { name: "Bệnh viện Đa khoa Hồng Ngọc", type: FacilityType.hospital, address: "55 Yên Ninh, Ba Đình, Hà Nội", province: "Hà Nội", district: "Ba Đình" },
    { name: "Phòng khám Đa khoa Medlatec", type: FacilityType.clinic, address: "42 Nghĩa Dũng, Ba Đình, Hà Nội", province: "Hà Nội", district: "Ba Đình" },
    { name: "Phòng khám Vinmec Times City", type: FacilityType.clinic, address: "458 Minh Khai, Hai Bà Trưng, Hà Nội", province: "Hà Nội", district: "Hai Bà Trưng" },
    { name: "Trung tâm Tiêm chủng VNVC Hà Nội", type: FacilityType.vaccination_center, address: "180 Trường Chinh, Đống Đa, Hà Nội", province: "Hà Nội", district: "Đống Đa" },
    // HCM
    { name: "Bệnh viện Chợ Rẫy", type: FacilityType.hospital, address: "201B Nguyễn Chí Thanh, Quận 5, TP.HCM", province: "Hồ Chí Minh", district: "Quận 5" },
    { name: "Bệnh viện Đại học Y Dược", type: FacilityType.hospital, address: "215 Hồng Bàng, Quận 5, TP.HCM", province: "Hồ Chí Minh", district: "Quận 5" },
    { name: "Bệnh viện Từ Dũ", type: FacilityType.hospital, address: "284 Cống Quỳnh, Quận 1, TP.HCM", province: "Hồ Chí Minh", district: "Quận 1" },
    { name: "Bệnh viện Nhi Đồng 1", type: FacilityType.hospital, address: "341 Sư Vạn Hạnh, Quận 10, TP.HCM", province: "Hồ Chí Minh", district: "Quận 10" },
    { name: "Bệnh viện Ung bướu TP.HCM", type: FacilityType.hospital, address: "3 Nơ Trang Long, Bình Thạnh, TP.HCM", province: "Hồ Chí Minh", district: "Bình Thạnh" },
    { name: "Bệnh viện FV (Pháp Việt)", type: FacilityType.hospital, address: "6 Nguyễn Lương Bằng, Quận 7, TP.HCM", province: "Hồ Chí Minh", district: "Quận 7" },
    { name: "Phòng khám Victoria Healthcare", type: FacilityType.clinic, address: "37 Lương Hữu Khánh, Quận 1, TP.HCM", province: "Hồ Chí Minh", district: "Quận 1" },
    { name: "Bệnh viện Quân y 175", type: FacilityType.hospital, address: "786 Nguyễn Kiệm, Gò Vấp, TP.HCM", province: "Hồ Chí Minh", district: "Gò Vấp" },
    { name: "Phòng khám CarePlus Tân Bình", type: FacilityType.clinic, address: "107 Tân Hải, Tân Bình, TP.HCM", province: "Hồ Chí Minh", district: "Tân Bình" },
    { name: "Trung tâm VNVC Hoàng Văn Thụ", type: FacilityType.vaccination_center, address: "198 Hoàng Văn Thụ, Phú Nhuận, TP.HCM", province: "Hồ Chí Minh", district: "Phú Nhuận" },
  ];

  const lastNames = ['Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Huỳnh', 'Phan', 'Vũ', 'Đặng', 'Bùi'];
  const middleNames = ['Văn', 'Thị', 'Minh', 'Anh', 'Quang', 'Hữu', 'Đức', 'Hoàng'];
  const firstNames = ['An', 'Bình', 'Cường', 'Dũng', 'Em', 'Giang', 'Hương', 'Hùng', 'Kiên', 'Linh', 'Nam', 'Phúc', 'Sơn', 'Tâm'];

  let doctorCounter = 1;

  for (const f of facilitiesData) {
    // Tạo cơ sở y tế
    const facility = await prisma.facility.create({
      data: {
        name: f.name,
        facility_type: f.type,
        address_detail: f.address,
        province: f.province,
        district: f.district,
        phone: `024${Math.floor(1000000 + Math.random() * 9000000)}`,
        email: `contact@${f.name.toLowerCase().replace(/\s/g, '')}.vn`,
        opening_hours: "07:30 - 17:00",
        rating_avg: 4.5 + Math.random() * 0.5,
        isActive: 1
      }
    });

    // Tạo 2-3 bác sĩ cho mỗi cơ sở
    const numDoctors = Math.floor(Math.random() * 2) + 2; // Random 2 hoặc 3
    for (let i = 0; i < numDoctors; i++) {
      const lName = lastNames[Math.floor(Math.random() * lastNames.length)];
      const mName = middleNames[Math.floor(Math.random() * middleNames.length)];
      const fName = firstNames[Math.floor(Math.random() * firstNames.length)];
      const fullName = `${lName} ${mName} ${fName}`;

      const email = `doctor${doctorCounter}@clinic.ai`;

      // 1. Tạo User trước
      const user = await prisma.user.create({
        data: {
          fullName: fullName,
          email: email,
          phone: `09${Math.floor(10000000 + Math.random() * 90000000)}`,
          password_hash: hashedPassword,
          role: UserRole.doctor,
          status: 'active'
        }
      });

      // 2. Tạo Doctor profile liên kết với User và Facility
      await prisma.doctor.create({
        data: {
          userId: user.userId,
          fullName: fullName,
          specialty_id: createdSpecialties[Math.floor(Math.random() * createdSpecialties.length)].specialty_id,
          facilityId: facility.facilityId,
          title: i === 0 ? "Thạc sĩ, Bác sĩ" : "Bác sĩ chuyên khoa I",
          experience_years: 5 + Math.floor(Math.random() * 15),
          consultation_fee: 200000 + (Math.floor(Math.random() * 6) * 50000),
          bio: `Bác sĩ ${fullName} có nhiều năm kinh nghiệm công tác tại các bệnh viện lớn, chuyên môn cao và tận tâm với bệnh nhân.`,
          isActive: 1
        }
      });

      doctorCounter++;
    }
  }

  // 4. Tạo một bệnh nhân mẫu để Dũng test app
  console.log('👤 Đang tạo tài khoản bệnh nhân mẫu...');
  const patientUser = await prisma.user.create({
    data: {
      fullName: "Nguyễn Trung Dũng",
      email: "dung.patient@gmail.com",
      phone: "0988888888",
      password_hash: hashedPassword,
      role: UserRole.patient,
      status: 'active'
    }
  });

  await prisma.patientProfile.create({
    data: {
      userId: patientUser.userId,
      fullName: "Nguyễn Trung Dũng",
      is_primary: 1
    }
  });

  console.log(`
  ✨ HOÀN TẤT SEED DỮ LIỆU:
  - Chuyên khoa: ${createdSpecialties.length}
  - Cơ sở y tế: ${facilitiesData.length}
  - Tổng số bác sĩ: ${doctorCounter - 1}
  - Tài khoản Patient: dung.patient@gmail.com / password123
  `);
}

main()
  .catch((e) => {
    console.error('❌ Lỗi khi seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });