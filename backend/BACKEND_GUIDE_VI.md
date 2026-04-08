# Tài Liệu Backend Hoàn Chỉnh

## 🚀 Hướng Dẫn Bắt Đầu Nhanh

### Điều Kiện Tiên Quyết
- Node.js 18+
- MySQL 8.0+
- npm hoặc yarn

### Cài Đặt

```bash
cd backend

# Cài đặt các phụ thuộc
npm install

# Thiết lập các biến môi trường
cp .env.example .env
# Chỉnh sửa .env với cấu hình của bạn

# Thiết lập cơ sở dữ liệu
npx prisma migrate dev

# Tạo seed cơ sở dữ liệu (tùy chọn)
npx prisma db seed

# Chạy máy chủ phát triển
npm run start:dev

# Xây dựng cho sản xuất
npm run build
npm run start:prod
```

## 📚 Tài Liệu API

### Truy Cập Swagger UI
Sau khi máy chủ đang chạy, hãy truy cập:
```
http://localhost:3000/api/docs
```

## 🏗️ Cấu Trúc Dự Án

```
backend/
├── src/
│   ├── app.module.ts                 # Mô-đun ứng dụng chính
│   ├── main.ts                       # Điểm vào ứng dụng
│   ├── common/
│   │   ├── decorators/               # Các decorator tùy chỉnh
│   │   │   ├── current-user.decorator.ts
│   │   │   └── roles.decorator.ts
│   │   └── guards/                   # Bảo vệ tuyến đường
│   │       ├── jwt.guard.ts
│   │       └── roles.guard.ts
│   ├── modules/
│   │   ├── auth/                     # Xác thực & ủy quyền
│   │   ├── appointments/             # Đặt lịch hẹn & quản lý
│   │   ├── doctors/                  # Hồ sơ bác sĩ
│   │   ├── clinics/                  # Quản lý phòng khám
│   │   ├── slots/                    # Quản lý khe thời gian
│   │   ├── specialties/              # Chuyên khoa y tế
│   │   ├── patients/                 # Hồ sơ bệnh nhân
│   │   ├── users/                    # Quản lý tài khoản người dùng
│   │   ├── ai/                       # Lọc phân loại AI & tóm tắt
│   │   └── notifications/            # Thông báo push
│   └── prisma/
│       ├── prisma.module.ts
│       └── prisma.service.ts
├── prisma/
│   ├── schema.prisma                 # Sơ đồ cơ sở dữ liệu
│   └── seed.ts                       # Tạo seed cơ sở dữ liệu
├── nest-cli.json
├── tsconfig.json
└── package.json
```

## 🔐 Xác Thực

Tất cả các endpoint API (ngoại trừ `/auth/register` và `/auth/login`) yêu cầu xác thực token Bearer:

```bash
Authorization: Bearer <access_token>
```

### Kiểm Soát Truy Cập Dựa Trên Vai Trò

- **BỆNH NHÂN**: Có thể quản lý các lịch hẹn và hồ sơ của riêng mình
- **BÁC SĨ**: Có thể xem các lịch hẹn, thêm ghi chú, quản lý tính khả dụng
- **QUẢN TRỊ VIÊN**: Truy cập đầy đủ vào tất cả các tài nguyên

## 📋 Tổng Quan Về Các Endpoint API

### Xác Thực (`/auth`)
- `POST /auth/register` - Đăng ký người dùng mới
- `POST /auth/login` - Đăng nhập người dùng
- `POST /auth/refresh` - Làm mới mã truy cập
- `POST /auth/logout` - Đăng xuất người dùng

### Bác Sĩ (`/doctors`)
- `POST /doctors` - Tạo hồ sơ bác sĩ (chỉ quản trị viên)
- `GET /doctors` - Liệt kê tất cả bác sĩ
- `GET /doctors/:id` - Lấy chi tiết bác sĩ
- `PATCH /doctors/:id` - Cập nhật hồ sơ bác sĩ
- `PATCH /doctors/:id/approve` - Phê duyệt bác sĩ (chỉ quản trị viên)
- `GET /doctors/availability/:id` - Lấy tính khả dụng của bác sĩ

### Lịch Hẹn (`/appointments`)
- `POST /appointments` - Đặt lịch hẹn
- `GET /appointments` - Liệt kê các lịch hẹn (được lọc theo người dùng)
- `GET /appointments/:id` - Lấy chi tiết lịch hẹn
- `PATCH /appointments/:id` - Cập nhật lịch hẹn (chỉ PENDING)
- `PATCH /appointments/:id/status` - Cập nhật trạng thái
- `POST /appointments/:id/reschedule` - Lên lịch lại lịch hẹn
- `POST /appointments/:id/cancel` - Hủy lịch hẹn
- `POST /appointments/:id/doctor-notes` - Thêm ghi chú bác sĩ
- `DELETE /appointments/:id` - Xóa lịch hẹn (chỉ quản trị viên)

### Phòng Khám (`/clinics`)
- `POST /clinics` - Tạo phòng khám (chỉ quản trị viên)
- `GET /clinics` - Liệt kê tất cả các phòng khám
- `GET /clinics/:id` - Lấy chi tiết phòng khám
- `PATCH /clinics/:id` - Cập nhật phòng khám (chỉ quản trị viên)
- `DELETE /clinics/:id` - Xóa phòng khám (chỉ quản trị viên)

### Khe Thời Gian (`/slots`)
- `POST /slots` - Tạo khe thời gian
- `POST /slots/bulk` - Tạo nhiều khe thời gian
- `GET /slots` - Liệt kê các khe thời gian với bộ lọc
- `GET /slots/available` - Lấy các khe thời gian có sẵn
- `PATCH /slots/:id` - Cập nhật khe thời gian
- `DELETE /slots/:id` - Xóa khe thời gian

### Chuyên Khoa (`/specialties`)
- `POST /specialties` - Tạo chuyên khoa (chỉ quản trị viên)
- `GET /specialties` - Liệt kê tất cả chuyên khoa
- `GET /specialties/:id` - Lấy chi tiết chuyên khoa
- `PATCH /specialties/:id` - Cập nhật chuyên khoa (chỉ quản trị viên)
- `DELETE /specialties/:id` - Xóa chuyên khoa (chỉ quản trị viên)

### Bệnh Nhân (`/patients`)
- `GET /patients/profile` - Lấy hồ sơ bệnh nhân của riêng bạn
- `PATCH /patients/profile` - Cập nhật hồ sơ của riêng bạn
- `DELETE /patients/profile` - Xóa hồ sơ của riêng bạn

### Người Dùng (`/users`)
- `GET /users` - Liệt kê người dùng (chỉ quản trị viên)
- `GET /users/:id` - Lấy chi tiết người dùng
- `PATCH /users/:id` - Cập nhật người dùng
- `POST /users/:id/change-password` - Thay đổi mật khẩu
- `PATCH /users/:id/toggle-active` - Bật/tắt trạng thái người dùng (chỉ quản trị viên)
- `DELETE /users/:id` - Xóa người dùng (chỉ quản trị viên)

### AI (`/ai`)
- `POST /ai/triage` - Lọc phân loại triệu chứng do AI
- `POST /ai/previsit-summary` - Tạo tóm tắt trước khám cho bác sĩ

### Thông Báo (`/notifications`)
- `POST /notifications/fcm-token` - Lưu token Firebase Cloud Messaging

## 🗄️ Sơ Đồ Cơ Sở Dữ Liệu

### Các Mô Hình Chính

#### User
- Xác thực và dữ liệu hồ sơ người dùng
- Các vai trò được liên kết với PatientProfile, Doctor, AdminProfile

#### Doctor
- Thông tin giấy phép y tế và chuyên khoa
- Các mối quan hệ với User, Clinic (qua DoctorClinic), Appointment

#### PatientProfile
- Thông tin sức khỏe bệnh nhân
- Các mối quan hệ với User, Appointment

#### Appointment
- Bản ghi đặt lịch liên kết Bệnh nhân, Bác sĩ và Khe thời gian
- Theo dõi trạng thái với máy trạng thái

#### Slot
- Khe thời gian khả dụng của bác sĩ
- Có cơ chế phòng chống xung đột
- Có thể bị chặn

#### Clinic
- Vị trí phòng khám vật lý
- Các mối quan hệ với bác sĩ

#### FcmToken
- Token Firebase Cloud Messaging cho thông báo push

## 🛡️ Các Tính Năng Bảo Mật

1. **Xác Thực JWT**: Xác thực an toàn dựa trên token
2. **Hashing Mật Khẩu**: bcrypt cho bảo mật mật khẩu
3. **Kiểm Soát Truy Cập Dựa Trên Vai Trò**: Các vai trò PATIENT, DOCTOR, ADMIN
4. **Xác Thực Đầu Vào**: Global ValidationPipe với class-validator
5. **Cấu Hình CORS**: Danh sách gốc có thể cấu hình
6. **Luân Phiên Refresh Token**: Cơ chế refresh token an toàn
7. **Giới Hạn Tốc Độ**: Tích hợp sẵn với các công cụ NestJS

## 📝 DTOs (Đối Tượng Truyền Dữ Liệu)

Tất cả các yêu cầu/phản hồi API sử dụng DTOs để xác thực và tài liệu:

```typescript
// Ví dụ: CreateAppointmentDto
export class CreateAppointmentDto {
  patient_id: string;
  doctor_id: string;
  slot_id: string;
  reason: string;
  attachments?: string[];
}
```

## 🚀 Triển Khai

### Các Biến Môi Trường cho Sản Xuất

```bash
NODE_ENV=production
JWT_SECRET=<bí mật ngẫu nhiên mạnh>
DATABASE_URL=mysql://user:password@prod-host:3306/clinic_booking
CORS_ORIGIN=https://your-domain.com
```

### Triển Khai Docker

```bash
docker build -t clinic-booking-backend .
docker run -e DATABASE_URL=... -p 3000:3000 clinic-booking-backend
```

### Di Chuyển Cơ Sở Dữ Liệu

```bash
npx prisma migrate deploy
npx prisma db push
```

## 🧪 Kiểm Tra

```bash
# Chạy các kiểm tra đơn vị
npm run test

# Chạy các kiểm tra e2e
npm run test:e2e

# Phạm vi bảo hiểm
npm run test:cov
```

## 📦 Các Lệnh Phát Triển

```bash
# Khởi động máy chủ dev với tải lại tự động
npm run start:dev

# Khởi động máy chủ sản xuất
npm start

# Xây dựng cho sản xuất
npm run build

# Định dạng mã
npm run format

# Kiểm tra linting mã
npm run lint

# Tạo máy khách Prisma
npx prisma generate

# Mở Prisma Studio (trình duyệt cơ sở dữ liệu tương tác)
npx prisma studio

# Chạy các di chuyển cơ sở dữ liệu
npx prisma migrate dev --name migration_name
npx prisma migrate deploy
```

## 🐛 Khắc Phục Sự Cố

### Vấn Đề Kết Nối Cơ Sở Dữ Liệu
- Đảm bảo MySQL đang chạy
- Kiểm tra DATABASE_URL trong .env
- Xác minh quyền người dùng MySQL

### Lỗi JWT
- Đảm bảo JWT_SECRET được đặt trong .env
- Kiểm tra token chưa hết hạn
- Xác minh định dạng token trong tiêu đề Ủy quyền

### Vấn Đề CORS
- Cập nhật CORS_ORIGIN trong .env
- Đảm bảo cấu hình tiêu đề thích hợp

## 📞 Hỗ Trợ

Để giải quyết các vấn đề hoặc câu hỏi:
1. Kiểm tra tài liệu Swagger tại `/api/docs`
2. Kiểm tra các thông báo lỗi trong bàn điều khiển
3. Kiểm tra cấu hình `.env`
4. Xem lại tài liệu sơ đồ Prisma

## 📄 Giấy Phép

MIT
