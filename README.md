# Clinic AI Booking System

Monorepo project cho hệ thống đặt lịch khám bệnh với AI triage, hỗ trợ bệnh nhân (Patient), bác sĩ (Doctor) và quản trị viên (Admin).

## Cấu trúc Dự án

```
clinic-ai-booking/
├── backend/          # NestJS + Prisma + MySQL
├── mobile/           # Flutter app
├── docs/             # Documentation
└── README.md         # File này
```

## Yêu cầu Hệ thống

- **Node.js**: v18+ (Backend)
- **MySQL**: v8.0+ (Database)
- **Flutter**: v3.10+ (Mobile)
- **Dart**: v3.15+

## Hướng dẫn Chạy

### Backend - Cài đặt & Chạy

**1. Cài đặt Dependencies**

```bash
cd backend
npm install
```

**2. Cấu hình Environment**

```bash
cp .env.example .env
```

Ví dụ `.env`:
```
DATABASE_URL="mysql://root:password@localhost:3306/clinic_ai"
JWT_SECRET=your_super_secret_key_here_change_in_production
JWT_REFRESH_SECRET=your_super_secret_refresh_key
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
NODE_ENV=development
PORT=3000
```

**3. Setup Database**

```bash
cd backend
npx prisma migrate dev --name init
npx prisma db seed
```

**4. Chạy Backend**

```bash
npm run start:dev
```

Server chạy tại `http://localhost:3000`

### Mobile - Cài đặt & Chạy

**1. Cài đặt Dependencies**

```bash
cd mobile
flutter pub get
```

**2. Chạy App**

```bash
cd mobile
flutter run -d android  # hoặc -d ios
```

## Tính năng Chính

### Auth & Authorization
- ✅ JWT Access Token + Refresh Token
- ✅ bcrypt password hashing
- ✅ Role-based Access Control

### Booking
- ✅ Anti-collision slot booking
- ✅ Appointment status workflow

### AI Features
- 🔲 AI Triage symptom analysis
- 🔲 Pre-visit Summary generation

### Notifications
- 🔲 FCM push notifications
- 🔲 Appointment reminders

## License

MIT
