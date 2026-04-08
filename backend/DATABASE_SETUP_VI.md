# Hướng Dẫn Thiết Lập Cơ Sở Dữ Liệu & Dự Phòng

## 🔄 Thiết Lập Ban Đầu

### 1. Tạo Cơ Sở Dữ Liệu

```bash
# Sử dụng CLI MySQL
mysql -u root -p
CREATE DATABASE clinic_booking;
USE clinic_booking;
```

### 2. Cấu Hình Môi Trường

Tạo tệp `.env` trong thư mục backend:

```bash
DATABASE_URL="mysql://user:password@localhost:3306/clinic_booking"
JWT_SECRET="your-secret-key-minimum-32-characters"
JWT_REFRESH_SECRET="your-refresh-secret-minimum-32-characters"
NODE_ENV="development"
PORT=3000
```

### 3. Chạy Di Chuyển Prisma

```bash
# Cài đặt Prisma CLI nếu chưa được cài đặt
npm install -D prisma

# Tạo máy khách Prisma
npx prisma generate

# Chạy di chuyển ban đầu
npx prisma migrate dev --name init
```

### 4. Tạo Seed Cơ Sở Dữ Liệu (Tùy Chọn)

```bash
npx prisma db seed
```

## 📊 Tổng Quan Sơ Đồ Cơ Sở Dữ Liệu

### Bảng Người Dùng
- Lưu trữ dữ liệu xác thực và hồ sơ người dùng
- Các vai trò: BỆNH NHÂN, BÁC SĨ, QUẢN TRỊ VIÊN
- Mối quan hệ: Một-Một với PatientProfile, Doctor, AdminProfile

### Hồ Sơ Bác Sĩ
- Thông tin giấy phép y tế và chuyên khoa
- Quy trình phê duyệt (cờ isApproved)
- Mối quan hệ: Một-Nhiều với Appointment và Slot

### Hồ Sơ Bệnh Nhân
- Thông tin sức khỏe và dị ứng
- Thông tin liên lạc khẩn cấp
- Mối quan hệ: Một-Nhiều với Appointment

### Phòng Khám
- Các vị trí vật lý nơi bác sĩ làm việc
- Giờ hoạt động
- Mối quan hệ: Nhiều-Nhiều với Bác Sĩ thông qua DoctorClinic

### Lịch Hẹn
- Bản ghi đặt lịch liên kết Bệnh nhân, Bác sĩ và Khe thời gian
- Theo dõi trạng thái với máy trạng thái
- Hỗ trợ lên lịch lại và ghi chú bác sĩ

### Khe Thời Gian
- Khe thời gian khả dụng của bác sĩ
- Cơ chế phòng chống xung đột để ngăn chặn đặt lịch kép
- Có thể bị chặn cho sự không khả dụng

### FcmToken
- Token Firebase Cloud Messaging
- Cho thông báo push

## 🔄 Quy Trình Di Chuyển

### Tạo Di Chuyển Mới

```bash
# Sau khi thay đổi schema.prisma
npx prisma migrate dev --name descriptive_name
```

### Kiểm Tra Trạng Thái Di Chuyển

```bash
npx prisma migrate status
```

### Đặt Lại Cơ Sở Dữ Liệu (Chỉ Phát Triển)

```bash
# ⚠️ CẢNH BÁO: Điều này xóa tất cả dữ liệu!
npx prisma migrate reset
```

### Xem Cơ Sở Dữ Liệu trong Studio

```bash
# Mở trình duyệt cơ sở dữ liệu tương tác
npx prisma studio
```

## 📝 Các Tình Huống Di Chuyển Phổ Biến

### Thêm Cột Mới vào Bảng Hiện Có

1. Cập nhật `schema.prisma`:
```prisma
model User {
  // ... các trường hiện có
  newField String?  // trường tùy chọn
  updatedAt DateTime @updatedAt
}
```

2. Tạo và chạy di chuyển:
```bash
npx prisma migrate dev --name add_new_field_to_users
```

### Tạo Mô Hình/Bảng Mới

1. Thêm vào `schema.prisma`:
```prisma
model NewEntity {
  id String @id @default(cuid())
  name String
  created_at DateTime @default(now())
}
```

2. Chạy di chuyển:
```bash
npx prisma migrate dev --name create_new_entity
```

### Đổi Tên Trường

1. Cập nhật `schema.prisma`
2. Tạo di chuyển:
```bash
npx prisma migrate dev --name rename_field
```

## 🔍 Xác Minh

### Kiểm Tra Di Chuyển Được Áp Dụng

```bash
npx prisma migrate status
```

### Xác Minh Sơ Đồ Khớp Mã

```bash
npx prisma db push --skip-generate
```

### Tạo Máy Khách Prisma Sau Khi Thay Đổi Sơ Đồ

```bash
npx prisma generate
```

## ⚡ Tối Ưu Hóa Hiệu Suất

### Thêm Chỉ Mục Cơ Sở Dữ Liệu

```prisma
model User {
  id String @id
  email String @unique
  created_at DateTime @default(now())
  
  @@index([created_at])
  @@index([email])
}
```

### Gộp Kết Nối

Đảm bảo DATABASE_URL của bạn bao gồm cài đặt gộp kết nối:

```
DATABASE_URL="mysql://user:pass@localhost:3306/clinic_booking?pool_size=10&max_overflow=20"
```

## 🛡️ Sao Lưu & Khôi Phục

### Sao Lưu Cơ Sở Dữ Liệu

```bash
# Sử dụng mysqldump
mysqldump -u user -p clinic_booking > backup.sql

# Với dấu thời gian
mysqldump -u user -p clinic_booking > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Khôi Phục Cơ Sở Dữ Liệu

```bash
mysql -u user -p clinic_booking < backup.sql
```

## 📋 Danh Sách Kiểm Tra Trước Triển Khai

- [ ] Tất cả các di chuyển được áp dụng: `npx prisma migrate status`
- [ ] Không có di chuyển đang chờ xử lý: `npx prisma migrate deploy`
- [ ] Kết nối cơ sở dữ liệu được xác minh
- [ ] Sao lưu được tạo
- [ ] Các biến môi trường được đặt chính xác
- [ ] Chạy các bài kiểm tra: `npm test`
- [ ] Xây dựng thành công: `npm run build`

## 🔧 Khắc Phục Sự Cố

### Xung Đột Di Chuyển

Nếu các di chuyển xung đột trong khi phát triển theo nhóm:

```bash
# Đặt lại thành di chuyển cụ thể
npx prisma migrate resolve --applied "migration_name"
```

### Lỗi Xác Minh Sơ Đồ

```bash
# Xác thực cú pháp sơ đồ
npx prisma validate
```

### Lỗi Máy Khách Prisma

```bash
# Tạo lại máy khách sau khi thay đổi sơ đồ
npx prisma generate

# Buộc tạo lại
npx prisma generate --force
```

### Vấn Đề Kết Nối Cơ Sở Dữ Liệu

```bash
# Kiểm tra kết nối
npx prisma db execute --stdin < test.sql

# Kiểm tra trạng thái cơ sở dữ liệu
npx prisma db push
```

## 📞 Hỗ Trợ

Để giải quyết các vấn đề di chuyển:
1. Kiểm tra cú pháp `prisma/schema.prisma`
2. Xem lại các tệp di chuyển trong `prisma/migrations/`
3. Xác minh DATABASE_URL là chính xác
4. Kiểm tra dịch vụ MySQL đang chạy
