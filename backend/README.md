# Backend - Clinic AI Booking (NestJS + Prisma)

Production-ready backend cho hệ thống đặt lịch khám bệnh AI.

## Setup & Installation

### 1. Cài đặt Dependencies

```bash
cd backend
npm install
```

### 2. Cấu hình Database

```bash
# Copy env template
cp .env.example .env

# Chỉnh sửa .env với MySQL credentials của bạn
# Ví dụ:
# DATABASE_URL="mysql://user:password@localhost:3306/clinic_ai"
# JWT_SECRET=your_secret_key_here
```

### 3. Setup Database Schema

```bash
# Chạy migrations
npx prisma migrate dev --name init

# Generate Prisma Client
npx prisma generate

# Seed dữ liệu mẫu
npx prisma db seed
```

### 4. Chạy Development Server

```bash
npm run start:dev
```

Server sẽ chạy tại `http://localhost:3000`

## Folder Structure

```
backend/
├── src/
│   ├── common/
│   │   ├── guards/
│   │   │   ├── jwt.guard.ts          # JWT authentication
│   │   │   └── roles.guard.ts        # Role-based authorization
│   │   └── decorators/
│   │       ├── roles.decorator.ts    # @Roles() decorator
│   │       └── current-user.decorator.ts # @CurrentUser() decorator
│   ├── modules/
│   │   ├── auth/                     # Authentication module
│   │   │   ├── dto/
│   │   │   │   └── auth.dto.ts
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   └── auth.module.ts
│   │   ├── appointments/              # Booking module
│   │   │   ├── dto/
│   │   │   │   └── appointment.dto.ts
│   │   │   ├── appointments.controller.ts
│   │   │   ├── appointments.service.ts
│   │   │   └── appointments.module.ts
│   │   ├── ai/                        # AI Triage module
│   │   │   ├── dto/
│   │   │   │   └── ai.dto.ts
│   │   │   ├── ai.controller.ts
│   │   │   ├── ai.service.ts
│   │   │   └── ai.module.ts
│   │   ├── notifications/             # FCM notifications
│   │   │   ├── dto/
│   │   │   │   └── notification.dto.ts
│   │   │   ├── notifications.controller.ts
│   │   │   ├── notifications.service.ts
│   │   │   └── notifications.module.ts
│   │   ├── doctors/
│   │   ├── patients/
│   │   ├── specialties/
│   │   ├── slots/
│   │   ├── clinics/
│   │   └── users/
│   ├── prisma/
│   │   ├── prisma.service.ts
│   │   └── prisma.module.ts
│   ├── app.module.ts                  # Root module
│   └── main.ts                        # Entry point
├── prisma/
│   ├── schema.prisma                  # Database schema
│   └── seed.ts                        # Seed script
├── .env.example
├── .eslintrc.js
├── nest-cli.json
├── package.json
└── tsconfig.json
```

## API Endpoints

### Auth
- `POST /auth/register` - Đăng ký
- `POST /auth/login` - Đăng nhập
- `POST /auth/refresh` - Làm mới token
- `POST /auth/logout` - Đăng xuất

### Appointments
- `POST /appointments` - Tạo lịch khám (Patient)
- `GET /appointments/my` - Lịch của bệnh nhân
- `GET /appointments/doctor` - Lịch của bác sĩ
- `PATCH /appointments/:id` - Cập nhật lịch
- `DELETE /appointments/:id` - Hủy lịch

### AI
- `POST /ai/triage` - Phân tích triệu chứng
- `POST /ai/previsit-summary` - Tạo bản tóm tắt trước khám

### Notifications
- `POST /notifications/fcm-token` - Lưu FCM token

## Authentication Flow

1. User đăng nhập → nhận `accessToken` (15m) + `refreshToken` (7d)
2. Các API requests dùng `Authorization: Bearer <accessToken>`
3. Khi token hết hạn → dùng `refreshToken` để lấy token mới
4. `refreshToken` được hash + lưu trong DB cho security

## Database Schema

### Users
- `id`: UUID
- `email`: Unique
- `password`: bcrypt hashed
- `role`: PATIENT | DOCTOR | ADMIN
- Relations: RefreshToken[], FcmToken[], PatientProfile, Doctor, AdminProfile

### Appointments
- `id`: UUID
- `patientId`, `doctorId`, `slotId`: Foreign keys
- `status`: PENDING | CONFIRMED | CANCELLED | COMPLETED | NO_SHOW
- `triageJson`: AI triage output (JSON string)
- `previsitSummary`: AI generated summary
- `doctorNotes`: Bác sĩ ghi chú
- Unique constraint: One appointment per slot (anti-collision)

### Slots
- `id`: UUID
- `doctorId`, `clinicId`: Foreign keys
- `startAt`, `endAt`: DateTime
- `isBlocked`: Boolean (admin có thể block slot)
- Unique constraint: `(doctorId, clinicId, startAt, endAt)`

## Authorization

Dùng Role-based Access Control:

```typescript
// Protect endpoint với role
@Roles(UserRole.PATIENT)
@UseGuards(JwtGuard, RolesGuard)
async myEndpoint(@CurrentUser('sub') userId: string) {
  // Only PATIENT can access
}
```

## AI Module

**Triage Service**:
- Input: `symptoms` (array), `severity`, `duration`
- Output: 
  ```json
  {
    "recommended_specialties": ["Tổng quát", "Tim mạch"],
    "urgency_level": "KHAN|NEN_DI_SOM|THUONG",
    "follow_up_questions": ["?"],
    "disclaimer": "..."
  }
  ```
- **Current**: Mock implementation (keyword matching)
- **TODO**: Integrate OpenAI API

**Pre-visit Summary**:
- Input: patient data, appointment history
- Output: Bullet points summary cho doctor
- **Current**: Mock implementation
- **TODO**: Integrate LLM

## Notifications

**Firebase Cloud Messaging (FCM)**:
- Endpoint để save FCM token: `POST /notifications/fcm-token`
- Cron job kiểm tra appointments sắp tới (mỗi 15 min)
- **Current**: Placeholder (logs only)
- **TODO**: 
  1. Setup Firebase Admin SDK
  2. Implement `sendPushNotification()`
  3. Handle token refresh/expiry

## Caching & Performance

- Prisma Client caching
- TODO: Add Redis cho token blacklist
- TODO: Query optimization với `.select()` / `.include()`

## Error Handling

- Centralized with NestJS exception filters
- Status codes: 200, 201, 400, 401, 403, 404, 500
- Error response format:
  ```json
  {
    "statusCode": 400,
    "message": "Error description",
    "error": "Bad Request"
  }
  ```

## Testing

```bash
# Unit tests
npm run test

# Watch mode
npm run test:watch

# Coverage
npm run test:cov

# E2E tests
npm run test:e2e
```

## Development

### Create New Module

```bash
nest g module modules/feature
nest g service modules/feature
nest g controller modules/feature
```

### Database Changes

```bash
# Create migration
npx prisma migrate dev --name feature_name

# Check schema
npx prisma studio
```

### Linting

```bash
npm run lint
npm run format
```

## Production Checklist

- [ ] Set `NODE_ENV=production`
- [ ] Generate JWT secrets: `openssl rand -base64 32`
- [ ] Setup MySQL (production instance)
- [ ] Configure environment variables securely
- [ ] Enable HTTPS/TLS
- [ ] Setup monitoring/logging (e.g., Sentry, DataDog)
- [ ] Setup database backups
- [ ] Setup CI/CD pipeline
- [ ] Run security audit: `npm audit`
- [ ] Setup rate limiting
- [ ] Setup API documentation (Swagger)

## Build & Deploy

```bash
# Build
npm run build

# Run production
npm run start:prod

# Docker
docker build -t clinic-ai-backend .
docker run -p 3000:3000 --env-file .env clinic-ai-backend
```

## Troubleshooting

### Database Connection Error
```
Error: connect ECONNREFUSED 127.0.0.1:5432
```
- Kiểm tra PostgreSQL đang chạy
- Kiểm tra `DATABASE_URL` đúng

### Module Not Found
- Chạy `npm install` lại
- Kiểm tra path aliases trong `tsconfig.json`

### JWT Errors
- Kiểm tra `JWT_SECRET` được set
- Kiểm tra token format: `Bearer <token>`
- Kiểm tra token còn hạn

## Resources

- [NestJS Documentation](https://docs.nestjs.com)
- [Prisma Documentation](https://www.prisma.io/docs)
- [JWT Best Practices](https://tools.ietf.org/html/rfc7519)
- [MySQL Documentation](https://dev.mysql.com/doc/)

## Contributing

1. Create feature branch: `git checkout -b feature/my-feature`
2. Commit: `git commit -am 'Add feature'`
3. Push: `git push origin feature/my-feature`
4. Create Pull Request

## License

MIT
