import { PrismaClient, UserRole, AppointmentStatus } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting seeding database...');

  // 1. Dọn dẹp dữ liệu cũ
  await prisma.auditLog.deleteMany();
  await prisma.triageResult.deleteMany();
  await prisma.appointment.deleteMany();
  await prisma.slot.deleteMany();
  await prisma.doctorClinic.deleteMany();
  await prisma.doctor.deleteMany();
  await prisma.patientProfile.deleteMany();
  await prisma.adminProfile.deleteMany();
  await prisma.user.deleteMany();
  await prisma.specialty.deleteMany();
  await prisma.clinic.deleteMany();

  const hashedPassword = await bcrypt.hash('password123', 10);

  // 2. Tạo Chuyên khoa
  const specialtiesData = [
    { name: 'Tổng quát', description: 'Khám sức khỏe đa khoa' },
    { name: 'Tim mạch', description: 'Chuyên khoa tim mạch' },
    { name: 'Nhi khoa', description: 'Chăm sóc sức khỏe trẻ em' },
  ];
  const specialties = await Promise.all(specialtiesData.map(data => prisma.specialty.create({ data })));

  // 3. DANH SÁCH 20 BỆNH VIỆN & PHÒNG KHÁM CHI TIẾT
  console.log('🏥 Creating 20 detailed healthcare facilities...');
  const clinicsData = [
    // --- HÀ NỘI (10 địa điểm) ---
    {
      name: "Bệnh viện Bạch Mai",
      address: "78 Giải Phóng, Phương Mai, Đống Đa, Hà Nội",
      city: "Hà Nội",
      description: "Bệnh viện Bạch Mai là bệnh viện đa khoa hạng đặc biệt đầu tiên của Việt Nam. \n\nVới quy mô hơn 2000 giường bệnh, đây là tuyến cuối chuyên tiếp nhận các ca bệnh khó nhất. \n\nCác trung tâm mũi nhọn: \n- Trung tâm Tim mạch: Can thiệp mạch vành chuyên sâu. \n- Trung tâm Hồi sức cấp cứu: Nơi cứu sống hàng ngàn ca nguy kịch. \n- Trung tâm Chống độc: Duy nhất tại miền Bắc xử lý các loại ngộ độc hiếm gặp. \n\nBệnh viện trang bị hệ thống MRI 3.0 Tesla và CT 512 lát cắt hiện đại bậc nhất.",
    },
    {
      name: "Bệnh viện Việt Đức",
      address: "40 Tràng Thi, Hàng Bông, Hoàn Kiếm, Hà Nội",
      city: "Hà Nội",
      description: "Bệnh viện Hữu nghị Việt Đức là trung tâm phẫu thuật lớn nhất cả nước. \n\nVới bề dày lịch sử hơn 100 năm, bệnh viện đi đầu trong lĩnh vực ngoại khoa và ghép tạng. \n\nThế mạnh đặc biệt: \n- Ghép tạng: Thực hiện thành công ghép Tim, Gan, Phổi từ người cho chết não. \n- Chấn thương chỉnh hình: Xử lý mọi ca tai nạn giao thông phức tạp. \n- Phẫu thuật thần kinh: Điều trị u não bằng robot định vị chính xác tuyệt đối.",
    },
    {
      name: "Bệnh viện Trung ương Quân đội 108",
      address: "1 Trần Hưng Đạo, Hai Bà Trưng, Hà Nội",
      city: "Hà Nội",
      description: "Bệnh viện 108 là cơ sở y tế quân đội hiện đại nhất Đông Nam Á. \n\nTòa nhà trung tâm thông minh tích hợp hệ thống vận chuyển mẫu bằng khí tự động. \n\nĐiểm nổi bật: \n- Khoa Quốc tế: Phục vụ khách hàng với tiêu chuẩn 5 sao. \n- Kỹ thuật ghép gan: Trình độ tương đương các nước phát triển. \n- Hệ thống phòng mổ Hybrid: Tối ưu cho các ca can thiệp tim mạch phức tạp.",
    },
    {
      name: "Bệnh viện Đa khoa Tâm Anh Hà Nội",
      address: "108 Hoàng Như Tiếp, Long Biên, Hà Nội",
      city: "Hà Nội",
      description: "Bệnh viện Tâm Anh kết hợp mô hình khám chữa bệnh và nghỉ dưỡng cao cấp. \n\nNổi tiếng với tỷ lệ thành công cao trong hỗ trợ sinh sản. \n\nLĩnh vực dẫn đầu: \n- IVF Tâm Anh: Công nghệ nuôi cấy phôi tiên tiến. \n- Chấn thương chỉnh hình: Thay khớp gối, khớp háng bằng robot cầm tay. \n- Trung tâm Nhi khoa: Tiêm chủng và điều trị nhi khoa tiêu chuẩn quốc tế.",
    },
    {
      name: "Bệnh viện Nhi Trung ương",
      address: "18/879 La Thành, Đống Đa, Hà Nội",
      city: "Hà Nội",
      description: "Cơ sở y tế chuyên khoa Nhi hàng đầu, điều trị mọi bệnh lý từ sơ sinh đến vị thành niên. \n\nNăng lực chuyên môn: \n- Phẫu thuật tim bẩm sinh sơ sinh cực khó. \n- Điều trị các bệnh lý gene và chuyển hóa. \n- Trung tâm can thiệp sớm cho trẻ tự kỷ. \n\nKhông gian bệnh viện được trang trí sinh động giúp giảm tâm lý sợ hãi cho trẻ em.",
    },
    {
      name: "Phòng khám Đa khoa Thu Cúc TCI",
      address: "286 Thụy Khuê, Tây Hồ, Hà Nội",
      city: "Hà Nội",
      description: "Thu Cúc TCI nổi tiếng với dịch vụ 'Chăm sóc sức khỏe như người thân'. \n\nMô hình bệnh viện khách sạn xanh, sạch, đẹp. \n\nƯu điểm: \n- Thai sản trọn gói: Theo dõi thai kỳ sát sao và đi đẻ nhẹ nhàng như đi nghỉ dưỡng. \n- Tầm soát ung thư: Gói khám chuyên sâu phát hiện sớm mọi dấu hiệu bất thường. \n- Hệ thống xét nghiệm tự động cho kết quả nhanh và chính xác.",
    },
    {
      name: "Bệnh viện Đa khoa Hồng Ngọc",
      address: "55 Yên Ninh, Ba Đình, Hà Nội",
      city: "Hà Nội",
      description: "Hồng Ngọc là đơn vị y tế tư nhân lâu đời và uy tín bậc nhất Thủ đô. \n\nPhong cách phục vụ chuyên nghiệp, tận tâm. \n\nChuyên khoa mạnh: \n- Răng Hàm Mặt: Thẩm mỹ nụ cười công nghệ cao. \n- Sản phụ khoa: Đội ngũ bác sĩ từ các viện trung ương. \n- Trung tâm vật lý trị liệu: Phục hồi chức năng sau phẫu thuật cực kỳ hiệu quả.",
    },
    {
      name: "Phòng khám Đa khoa Medlatec",
      address: "42 Nghĩa Dũng, Ba Đình, Hà Nội",
      city: "Hà Nội",
      description: "Medlatec là đơn vị đi đầu trong dịch vụ lấy mẫu xét nghiệm tận nơi. \n\nCông nghệ hiện đại: \n- Trung tâm xét nghiệm đạt chuẩn quốc tế ISO 15189 và CAP. \n- Chẩn đoán hình ảnh: Đọc kết quả trực tuyến bởi đội ngũ chuyên gia hàng đầu. \n- Dịch vụ bác sĩ gia đình tận tâm, chu đáo.",
    },
    {
      name: "Phòng khám Quốc tế Vinmec Times City",
      address: "458 Minh Khai, Hai Bà Trưng, Hà Nội",
      city: "Hà Nội",
      description: "Hệ thống y tế tư nhân hiện đại nhất Việt Nam với tiêu chuẩn JCI quốc tế. \n\nThế mạnh: \n- Y học tái tạo: Điều trị bằng tế bào gốc cho nhiều bệnh nan y. \n- Trung tâm tim mạch: Can thiệp không cần mổ mở. \n- Ung bướu: Cá nhân hóa phác đồ điều trị cho từng bệnh nhân.",
    },
    {
      name: "Bệnh viện Đa khoa PTIT",
      address: "96A Trần Phú, Hà Đông, Hà Nội",
      city: "Hà Nội",
      description: "Đơn vị y tế tiên phong ứng dụng trí tuệ nhân tạo (AI) trong quản lý sức khỏe. \n\nNơi sinh viên và giảng viên tin dùng. \n\nĐặc điểm: \n- Hệ thống hồ sơ điện tử đồng bộ. \n- Tư vấn sức khỏe thông minh qua app. \n- Chuyên khoa mắt và da liễu với công nghệ laser hiện đại.",
    },

    // --- TP. HỒ CHÍ MINH (10 địa điểm) ---
    {
      name: "Bệnh viện Chợ Rẫy",
      address: "201B Nguyễn Chí Thanh, Quận 5, TP.HCM",
      city: "Hồ Chí Minh",
      description: "Bệnh viện Chợ Rẫy là biểu tượng của y khoa miền Nam với hơn 120 năm lịch sử. \n\nTuyến cuối cùng tiếp nhận các ca bệnh hiểm nghèo từ khắp các tỉnh phía Nam. \n\nKhoa mũi nhọn: \n- ICU: Hồi sức cấp cứu trình độ cao. \n- Thận nhân tạo: Quy mô lớn nhất cả nước. \n- Ung bướu: Xạ trị bằng máy gia tốc hiện đại.",
    },
    {
      name: "Bệnh viện Đại học Y Dược TP.HCM",
      address: "215 Hồng Bàng, Quận 5, TP.HCM",
      city: "Hồ Chí Minh",
      description: "Hoạt động theo mô hình Trường - Viện kết hợp hoàn hảo giữa nghiên cứu và điều trị. \n\nBệnh viện có quy trình quản lý thông minh nhất Việt Nam. \n\nĐiểm mạnh: \n- Nội soi tiêu hóa: Can thiệp cắt u sớm qua nội soi. \n- Tim mạch: Điều trị rối loạn nhịp bằng sóng cao tần. \n- Khoa Nội tiết: Quản lý bệnh tiểu đường chuyên sâu.",
    },
    {
      name: "Bệnh viện Từ Dũ",
      address: "284 Cống Quỳnh, Quận 1, TP.HCM",
      city: "Hồ Chí Minh",
      description: "Bệnh viện Phụ sản hàng đầu, nơi khai sinh kỹ thuật IVF đầu tiên tại Việt Nam. \n\nSứ mệnh: \n- Hỗ trợ sinh sản: Tỷ lệ thành công đứng top đầu khu vực. \n- Sản khoa: Nơi chào đời an toàn của hàng triệu em bé. \n- Chăm sóc trẻ sơ sinh cực non: Kỹ thuật Kangaroo chuyên sâu.",
    },
    {
      name: "Bệnh viện Nhân dân Gia Định",
      address: "1 Nơ Trang Long, Bình Thạnh, TP.HCM",
      city: "Hồ Chí Minh",
      description: "Bệnh viện đa khoa hạng I lâu đời và uy tín bậc nhất TP.HCM. \n\nNăng lực điều trị: \n- Can thiệp mạch vành cấp cứu 24/7. \n- Phẫu thuật nội soi tiêu hóa và tiết niệu. \n- Khoa Sản: Dịch vụ sinh trọn gói được nhiều gia đình lựa chọn.",
    },
    {
      name: "Bệnh viện Ung bướu TP.HCM",
      address: "3 Nơ Trang Long, Bình Thạnh, TP.HCM",
      city: "Hồ Chí Minh",
      description: "Cơ sở chuyên khoa ung thư hàng đầu, phục vụ toàn bộ khu vực phía Nam. \n\nCông nghệ: \n- Xạ trị gia tốc thế hệ mới nhất. \n- Tầm soát ung thư sớm bằng kỹ thuật sinh thiết lỏng. \n- Phẫu thuật u phổi và đường tiêu hóa kỹ thuật cao.",
    },
    {
      name: "Bệnh viện Nhi Đồng 1",
      address: "341 Sư Vạn Hạnh, Quận 10, TP.HCM",
      city: "Hồ Chí Minh",
      description: "Bệnh viện nhi khoa tuyến cuối nổi tiếng với các ca phẫu thuật tim bẩm sinh phức tạp. \n\nThế mạnh: \n- Chuyên khoa Nhiễm: Khống chế các bệnh dịch nguy hiểm ở trẻ em. \n- Hồi sức nhi khoa: Hệ thống trang thiết bị hỗ trợ hô hấp tiên tiến. \n- Ngoại nhi: Phẫu thuật các dị tật bẩm sinh đường tiêu hóa.",
    },
    {
      name: "Bệnh viện FV (Pháp Việt)",
      address: "6 Nguyễn Lương Bằng, Quận 7, TP.HCM",
      city: "Hồ Chí Minh",
      description: "Bệnh viện đạt tiêu chuẩn quốc tế JCI với đội ngũ bác sĩ đa quốc gia. \n\nDịch vụ cao cấp: \n- Trung tâm Hy Vọng: Điều trị ung thư tiêu chuẩn Pháp. \n- Khoa Mắt: Phẫu thuật khúc xạ và đục thủy tinh thể công nghệ mới. \n- Nội trú sang trọng, bảo mật thông tin tuyệt đối.",
    },
    {
      name: "Phòng khám Đa khoa Victoria Healthcare",
      address: "37-39 Lương Hữu Khánh, Quận 1, TP.HCM",
      city: "Hồ Chí Minh",
      description: "Phòng khám theo tiêu chuẩn Mỹ, tập trung vào y học thực chứng. \n\nTriết lý: \n- Không lạm dụng kháng sinh và xét nghiệm không cần thiết. \n- Bác sĩ tư vấn kỹ lưỡng, dành nhiều thời gian lắng nghe bệnh nhân. \n- Hệ thống hồ sơ trực tuyến dễ dàng truy cập từ mọi nơi.",
    },
    {
      name: "Bệnh viện Quân y 175",
      address: "786 Nguyễn Kiệm, Gò Vấp, TP.HCM",
      city: "Hồ Chí Minh",
      description: "Bệnh viện quân đội đa khoa tuyến cuối khu vực phía Nam. \n\nSở hữu sân bay trực thăng cấp cứu hiện đại. \n\nĐiểm mạnh: \n- Cấp cứu đường không: Đưa bệnh nhân từ vùng sâu vùng xa về viện nhanh nhất. \n- Trung tâm chấn thương chỉnh hình: Quy mô cực lớn. \n- Điều trị vật lý trị liệu và phục hồi chức năng chuyên sâu.",
    },
    {
      name: "Phòng khám Đa khoa CarePlus",
      address: "6-7 Tân Viên, Tân Bình, TP.HCM",
      city: "Hồ Chí Minh",
      description: "Hệ thống phòng khám chuẩn quốc tế với vốn đầu tư từ Singapore. \n\nĐiểm nổi bật: \n- Gói khám tổng quát đa dạng cho mọi lứa tuổi. \n- Chẩn đoán hình ảnh và xét nghiệm nhanh chóng. \n- Không gian hiện đại, nhân viên phục vụ tận tình, chu đáo.",
    },
  ];

  const createdClinics = await Promise.all(
    clinicsData.map(c => prisma.clinic.create({
      data: {
        ...c,
        country: "Việt Nam",
        hours: JSON.stringify({ morning: '07:30-11:30', afternoon: '13:00-16:30' })
      }
    }))
  );

  // 4. Tạo User mẫu để App không lỗi
  const doctor = await prisma.user.create({
    data: {
      email: 'doctor1@clinic.local',
      password: hashedPassword,
      firstName: 'Trung',
      lastName: 'Dũng',
      role: UserRole.DOCTOR,
      doctor: {
        create: {
          licenseNumber: 'DOC-2026-001',
          specialtyId: specialties[0].id,
          isApproved: true,
          doctorClinics: { create: { clinicId: createdClinics[0].id } },
        },
      },
    },
    include: { doctor: true },
  });

  console.log(`✨ Seed completed! ${createdClinics.length} detailed facilities added.`);
}

main().catch((e) => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());