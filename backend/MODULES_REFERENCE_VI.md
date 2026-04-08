# Thông Số Kỹ Thuật Các Module Backend

## 📦 Tham Khảo Module Hoàn Chỉnh

### 1. Module Xác Thực (`/auth`)

**Mục Đích**: Xác thực người dùng và ủy quyền

**Endpoints**:
- `POST /auth/register` - Đăng ký người dùng mới với email, mật khẩu, tên
- `POST /auth/login` - Đăng nhập bằng email/mật khẩu, trả về token JWT
- `POST /auth/refresh` - Làm mới mã truy cập bằng refresh token
- `POST /auth/logout` - Đăng xuất và hủy refresh token

**Tính Năng**:
- Xác thực dựa trên JWT
- Luân phiên refresh token
- Hashing mật khẩu với bcrypt
- Hủy token

**Các Lớp Chính**:
- `AuthService`: Xử lý logic xác thực
- `AuthController`: Các endpoint REST
- `JwtGuard`: Bảo vệ các tuyến đường được xác thực
- `RegisterDto`, `LoginDto`, `RefreshTokenDto`: Xác thực đầu vào

**Mô Hình Cơ Sở Dữ Liệu**:
- User
- RefreshToken

---

### 2. Module Bác Sĩ (`/doctors`)

**Mục Đích**: Quản lý hồ sơ bác sĩ, giấy phép và tính khả dụng

**Endpoints**:
- `POST /doctors` - Tạo hồ sơ bác sĩ (quản trị viên)
- `GET /doctors` - Liệt kê tất cả bác sĩ với bộ lọc
- `GET /doctors/:id` - Lấy chi tiết bác sĩ cụ thể
- `PATCH /doctors/:id` - Cập nhật hồ sơ bác sĩ của riêng bạn
- `PATCH /doctors/:id/approve` - Phê duyệt bác sĩ (quản trị viên)
- `GET /doctors/:doctor_id/availability` - Lấy tính khả dụng

**Tính Năng**:
- Quản lý hồ sơ bác sĩ
- Xác thực và tính duy nhất của giấy phép
- Quy trình phê duyệt
- Gán chuyên khoa
- Theo dõi xếp hạng và đánh giá

**Các Lớp Chính**:
- `DoctorsService`: Logic kinh doanh quản lý bác sĩ
- `DoctorsController`: Các endpoint REST
- `CreateDoctorDto`, `UpdateDoctorDto`, `ApproveDoctorDto`: DTO

**Mô Hình Cơ Sở Dữ Liệu**:
- Doctor
- User
- Specialty

**Ủy Quyền**: 
- BÁC SĨ có thể quản lý hồ sơ của riêng họ
- QUẢN TRỊ VIÊN có thể phê duyệt và quản lý tất cả bác sĩ

---

### 3. Module Lịch Hẹn (`/appointments`)

**Mục Đích**: Quản lý đặt lịch hẹn và vòng đời

**Endpoints**:
- `POST /appointments` - Tạo lịch hẹn mới
- `GET /appointments` - Liệt kê lịch hẹn với bộ lọc
- `GET /appointments/:id` - Lấy chi tiết lịch hẹn
- `PATCH /appointments/:id` - Cập nhật lịch hẹn đang chờ xử lý
- `PATCH /appointments/:id/status` - Cập nhật trạng thái lịch hẹn
- `POST /appointments/:id/reschedule` - Lên lịch lại lịch hẹn
- `POST /appointments/:id/cancel` - Hủy lịch hẹn
- `POST /appointments/:id/doctor-notes` - Thêm ghi chú bác sĩ
- `DELETE /appointments/:id` - Xóa lịch hẹn (quản trị viên)

**Tính Năng**:
- Đặt lịch hẹn với xác thực khe thời gian
- Máy trạng thái (PENDING → CONFIRMED → COMPLETED)
- Lên lịch lại với hủy tự động lịch hẹn cũ
- Ghi chú bác sĩ cho các lịch hẹn đã hoàn thành
- Lọc nâng cao theo bệnh nhân, bác sĩ, trạng thái, khoảng ngày

**Các Lớp Chính**:
- `AppointmentsService`: Logic lịch hẹn phức tạp
- `AppointmentsController`: Các endpoint REST
- `CreateAppointmentDto`, `RescheduleAppointmentDto`: DTO đầu vào

**Mô Hình Cơ Sở Dữ Liệu**:
- Appointment
- Slot
- Doctor
- PatientProfile
- User

**Ủy Quyền**:
- BỆNH NHÂN: Quản lý các lịch hẹn của riêng họ
- BÁC SĨ: Cập nhật trạng thái và thêm ghi chú
- QUẢN TRỊ VIÊN: Truy cập đầy đủ

**Logic Kinh Doanh**:
```typescript
// Chuyển đổi trạng thái
PENDING → CONFIRMED → COMPLETED
PENDING/CONFIRMED/COMPLETED → CANCELLED (từ bất kỳ)

// Xác thực khe thời gian
- Kiểm tra tính khả dụng của khe thời gian trước khi đặt lịch
- Ngăn chặn đặt lịch kép
- Xác thực bác sĩ và bệnh nhân tồn tại
```

---

### 4. Module Phòng Khám (`/clinics`)

**Mục Đích**: Quản lý vị trí phòng khám và thông tin

**Endpoints**:
- `POST /clinics` - Tạo phòng khám (quản trị viên)
- `GET /clinics` - Liệt kê tất cả phòng khám
- `GET /clinics/:id` - Lấy chi tiết phòng khám
- `PATCH /clinics/:id` - Cập nhật phòng khám (quản trị viên)
- `DELETE /clinics/:id` - Xóa phòng khám (quản trị viên)

**Tính Năng**:
- Quản lý vị trí phòng khám
- Giờ hoạt động
- Thông tin địa chỉ và liên hệ
- Liên kết bác sĩ-phòng khám

**Các Lớp Chính**:
- `ClinicsService`: Logic quản lý phòng khám
- `ClinicsController`: Các endpoint REST
- `CreateClinicDto`, `UpdateClinicDto`: DTO

**Mô Hình Cơ Sở Dữ Liệu**:
- Clinic
- DoctorClinic (bảng kết hợp)

**Các Trường**:
- name, address, city, country
- phone, email
- hours (định dạng JSON)

---

### 5. Module Khe Thời Gian (`/slots`)

**Mục Đích**: Quản lý khe thời gian khả dụng của bác sĩ

**Endpoints**:
- `POST /slots` - Tạo khe thời gian đơn
- `POST /slots/bulk` - Tạo nhiều khe thời gian (lặp lại)
- `GET /slots` - Liệt kê khe thời gian với bộ lọc
- `GET /slots/available` - Lấy các khe thời gian có sẵn chưa đặt lịch
- `PATCH /slots/:id` - Cập nhật khe thời gian (chặn/bỏ chặn)
- `DELETE /slots/:id` - Xóa khe thời gian

**Tính Năng**:
- Tạo khe thời gian đơn
- Tạo khe thời gian hàng loạt với lịch trình lặp lại
- Phát hiện xung đột (ngăn chặn đặt lịch kép)
- Xử lý chặn/không khả dụng
- Lọc nâng cao theo bác sĩ, phòng khám, khoảng ngày

**Các Lớp Chính**:
- `SlotsService`: Quản lý khe thời gian và phòng chống xung đột
- `SlotsController`: Các endpoint REST
- `CreateSlotDto`, `CreateBulkSlotsDto`: Xác thực đầu vào

**Mô Hình Cơ Sở Dữ Liệu**:
- Slot (có ràng buộc duy nhất trên doctor_id, clinicId, startAt, endAt)

**Tính Năng Nâng Cao**:
```typescript
// Tạo hàng loạt
{
  doctor_id: string;
  clinicId: string;
  startDate: "2024-01-15";  // YYYY-MM-DD
  endDate: "2024-01-31";
  start_time: "09:00";       // HH:mm
  end_time: "17:00";
  slotDuration: 30;         // phút
  daysOfWeek: [1, 2, 3, 4, 5];  // Thứ 2-6 (0=Chủ nhật)
}
```

---

### 6. Module Chuyên Khoa (`/specialties`)

**Mục Đích**: Quản lý chuyên khoa y tế

**Endpoints**:
- `POST /specialties` - Tạo chuyên khoa (quản trị viên)
- `GET /specialties` - Liệt kê tất cả chuyên khoa
- `GET /specialties/:id` - Lấy chi tiết chuyên khoa
- `PATCH /specialties/:id` - Cập nhật chuyên khoa (quản trị viên)
- `DELETE /specialties/:id` - Xóa chuyên khoa (quản trị viên)

**Tính Năng**:
- Định nghĩa và quản lý chuyên khoa
- Xác thực tính duy nhất
- Hỗ trợ biểu tượng/danh mục
- Liên kết bác sĩ-chuyên khoa

**Các Lớp Chính**:
- `SpecialtiesService`: Quản lý chuyên khoa
- `SpecialtiesController`: Các endpoint REST
- `CreateSpecialtyDto`, `UpdateSpecialtyDto`: DTO

**Mô Hình Cơ Sở Dữ Liệu**:
- Specialty

**Các Trường**:
- name (duy nhất)
- description
- icon (URL)

---

### 7. Module Bệnh Nhân (`/patients`)

**Mục Đích**: Quản lý hồ sơ bệnh nhân và thông tin y tế

**Endpoints**:
- `GET /patients/profile` - Lấy hồ sơ bệnh nhân của riêng bạn
- `PATCH /patients/profile` - Cập nhật hồ sơ của riêng bạn
- `DELETE /patients/profile` - Xóa hồ sơ của riêng bạn

**Tính Năng**:
- Theo dõi lịch sử y tế
- Tài liệu dị ứng
- Thuốc hiện tại
- Thông tin liên hệ khẩn cấp
- Thông tin nhân khẩu

**Các Lớp Chính**:
- `PatientsService`: Quản lý hồ sơ bệnh nhân
- `PatientsController`: Các endpoint REST
- `UpdatePatientProfileDto`: Xác thực cập nhật hồ sơ

**Mô Hình Cơ Sở Dữ Liệu**:
- PatientProfile
- User

**Các Trường**:
- dateOfBirth, gender, address
- medicalHistory (JSON)
- allergies (JSON)
- currentMedications (JSON)
- emergencyPhone

**Ủy Quyền**:
- BỆNH NHÂN: Chỉ có thể quản lý hồ sơ của riêng họ

---

### 8. Module Người Dùng (`/users`)

**Mục Đích**: Quản lý tài khoản người dùng và kiểm soát truy cập

**Endpoints**:
- `GET /users` - Liệt kê người dùng (quản trị viên)
- `GET /users/:id` - Lấy chi tiết người dùng
- `PATCH /users/:id` - Cập nhật hồ sơ người dùng
- `POST /users/:id/change-password` - Thay đổi mật khẩu
- `PATCH /users/:id/toggle-active` - Kích hoạt/Vô hiệu hóa (quản trị viên)
- `DELETE /users/:id` - Xóa người dùng (quản trị viên)

**Tính Năng**:
- Quản lý tài khoản người dùng
- Thay đổi mật khẩu
- Kích hoạt/vô hiệu hóa tài khoản
- Quản lý vai trò
- Cập nhật hồ sơ

**Các Lớp Chính**:
- `UsersService`: Logic quản lý người dùng
- `UsersController`: Các endpoint REST
- `UpdateUserDto`, `ChangePasswordDto`: Xác thực đầu vào

**Mô Hình Cơ Sở Dữ Liệu**:
- User

**Ủy Quyền**:
- BỆNH NHÂN/BÁC SĨ: Quản lý hồ sơ của riêng họ
- QUẢN TRỊ VIÊN: Quản lý tất cả người dùng

---

### 9. Module AI (`/ai`)

**Mục Đích**: Các dịch vụ y tế do AI hỗ trợ

**Endpoints**:
- `POST /ai/triage` - Lọc phân loại triệu chứng do AI
- `POST /ai/previsit-summary` - Tóm tắt trước khám cho bác sĩ

**Tính Năng**:
- Suy nghị chuyên khoa dựa trên triệu chứng
- Đánh giá mức độ khẩn cấp (THUONG, NEN_DI_SOM, KHAN)
- Tạo các câu hỏi tiếp theo
- Tạo tóm tắt trước khám

**Các Lớp Chính**:
- `AiService`: Logic AI (hiện tại là giả, sẵn sàng tích hợp LLM)
- `AiController`: Các endpoint REST
- `TriageRequestDto`, `PrevisitSummaryRequestDto`: Xác thực đầu vào

**Triển Khai Giả**:
```typescript
// Khớp từ khóa cho bản demo
Đầu vào: "đau ngực" → Đầu ra:
{
  recommended_specialties: ["Tim mạch", "Tổng quát"],
  urgency_level: "KHAN",
  follow_up_questions: [...]
}
```

**Điểm Tích Hợp**:
- OpenAI GPT-4 API
- Anthropic Claude API
- Mô hình LLM cục bộ

---

### 10. Module Thông Báo (`/notifications`)

**Mục Đích**: Thông báo push và nhắc nhở

**Endpoints**:
- `POST /notifications/fcm-token` - Lưu token Firebase Cloud Messaging

**Tính Năng**:
- Quản lý token FCM
- Nhắc nhở lịch hẹn (cron job)
- Gửi thông báo push
- Xử lý luân phiên token

**Các Lớp Chính**:
- `NotificationsService`: Logic thông báo với nhắc nhở được lên lịch
- `NotificationsController`: Các endpoint REST
- `SaveFcmTokenDto`: Xác thực token

**Mô Hình Cơ Sở Dữ Liệu**:
- FcmToken
- Appointment (được tham chiếu cho nhắc nhở)

**Các Tác Vụ Được Lên Lịch**:
```typescript
// Mỗi 5 phút
- Kiểm tra các lịch hẹn sắp tới (1 giờ tiếp theo)
- Gửi thông báo push cho bệnh nhân và bác sĩ
- Ghi nhật ký các lần thử gửi thông báo
```

**Triển Khai Tương Lai**:
- Tích hợp Firebase Admin SDK
- Thông báo email
- Thông báo SMS qua Twilio

---

## 🔐 Mô Hình Ủy Quyền

### JwtGuard (Xác Thực)
Bảo vệ tất cả các endpoint yêu cầu xác thực

```typescript
@UseGuards(JwtGuard)
async method() { }
```

### RolesGuard (Ủy Quyền)
Giới hạn các endpoint cho các vai trò cụ thể

```typescript
@UseGuards(JwtGuard, RolesGuard)
@Roles(UserRole.admin)
async method() { }
```

### Decorator Tùy Chỉnh
Trích xuất người dùng hiện tại từ token

```typescript
@CurrentUser('sub') user_id: string
@CurrentUser() user: JwtPayload
```

---

## 📊 Mô Hình Dữ Liệu Chung

### Phân Trang
```typescript
{
  skip: number;
  take: number;
}
```

### Lọc
```typescript
where: {
  status: AppointmentStatus.pending,
  doctor_id: string,
  patient_id: string,
  created_at: { gte: Date, lte: Date }
}
```

### Xử Lý Lỗi
```typescript
throw new NotFoundException('Tài nguyên không tìm thấy');
throw new BadRequestException('Đầu vào không hợp lệ');
throw new ForbiddenException('Truy cập bị từ chối');
throw new UnauthorizedException('Thông tin xác thực không hợp lệ');
```

---

## 🧩 Phụ Thuộc Module

```
AppModule
├── AuthModule (PrismaModule)
├── AppointmentsModule (PrismaModule)
├── DoctorsModule (PrismaModule)
├── ClinicsModule (PrismaModule)
├── SlotsModule (PrismaModule)
├── SpecialtiesModule (PrismaModule)
├── PatientsModule (PrismaModule)
├── UsersModule (PrismaModule)
├── AiModule (PrismaModule)
├── NotificationsModule (PrismaModule, ScheduleModule)
└── PrismaModule (singleton)
```

---

## 💡 Ghi Chú Triển Khai

1. **DTOs**: Tất cả các yêu cầu/phản hồi API sử dụng DTO để xác thực
2. **Dịch Vụ**: Logic kinh doanh được cô lập trong các lớp dịch vụ
3. **Prisma**: Các hoạt động cơ sở dữ liệu thông qua Prisma ORM
4. **Xử Lý Lỗi**: Ném ngoại lệ nhất quán
5. **Decorator**: Decorator tùy chỉnh cho các mô hình chung
6. **Guard**: Các guard có thể tái sử dụng để bảo mật
7. **Xác Thực**: Global ValidationPipe + decorator class-validator
