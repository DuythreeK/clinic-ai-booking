# Quick Start Guide

Hướng dẫn nhanh chạy Clinic AI Booking (Backend + Mobile).

## 🚀 Backend Setup (NestJS + Prisma + MySQL)

### Prerequisites
- Node.js 18+ (https://nodejs.org)
- MySQL 8.0+ (https://dev.mysql.com/downloads/mysql/)

### Steps

#### 1. Start MySQL
```bash
# macOS (Homebrew)
brew services start mysql

# Windows (MySQL Workbench)
# Mở MySQL Workbench hoặc cmd: net start MySQL80

# Linux
sudo systemctl start mysql
```

#### 2. Create Database
```bash
# Connect to MySQL
mysql -u root -p

# In MySQL terminal
CREATE DATABASE clinic_ai;
```

#### 3. Install Backend
```bash
cd backend
npm install
```

#### 4. Configure Environment
```bash
cp .env.example .env

# Edit .env
DATABASE_URL="mysql://root:password@localhost:3306/clinic_ai"
JWT_SECRET="your_secret_key_here_change_in_production"
JWT_REFRESH_SECRET="your_refresh_secret_key"
NODE_ENV="development"
PORT=3000
```

#### 5. Setup Prisma
```bash
cd backend

# Create tables from schema
npx prisma migrate dev --name init

# Generate Prisma Client
npx prisma generate

# Seed sample data
npx prisma db seed

# View database (optional)
npx prisma studio
```

#### 6. Run Backend
```bash
npm run start:dev
```

✅ Backend running at `http://localhost:3000`

**Test it:**
```bash
# In another terminal
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"patient@clinic.local","password":"patient123"}'

# Should return: { accessToken, refreshToken, user }
```

---

## 📱 Mobile Setup (Flutter)

### Prerequisites
- Flutter 3.10+ (https://flutter.dev/docs/get-started/install)
- Xcode 14+ (iOS only)
- Android Studio (Android)

### Steps

#### 1. Install Flutter
```bash
# Check installation
flutter doctor

# All checkmarks except maybe Android toolchain (if not developing for Android)
```

#### 2. Install Dependencies
```bash
cd mobile
flutter pub get
```

#### 3. Update Backend URL
Edit `mobile/lib/core/config/api_config.dart`:

```dart
// Replace with your machine IP (for physical device)
// or localhost:3000 (for iOS simulator)
// or 10.0.2.2:3000 (for Android emulator)
const String baseUrl = 'http://10.0.2.2:3000';
```

#### 4. Run Mobile App

**iOS Simulator:**
```bash
flutter run -d ios

# or pick specific device
flutter devices
flutter run -d "iPhone 15"
```

**Android Emulator:**
```bash
flutter run -d emulator-5554

# or start emulator first
emulator @emulator_name
```

**Physical Device:**
```bash
# Enable USB debugging on device
# Connect with USB cable
flutter devices
flutter run -d <device_id>
```

#### 5. Test Login
1. Launch app
2. Email: `patient@clinic.local`
3. Password: `patient123`
4. Tap "Login"
5. Should see home screen with 3 tabs

---

## 🔄 Full Test Flow

### 1. Register New Patient (Backend)
```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email":"newpatient@clinic.local",
    "password":"password123",
    "firstName":"Nguyễn",
    "lastName":"Văn A",
    "phone":"0901234567"
  }'

# Response:
# {
#   "accessToken": "eyJhbGc...",
#   "refreshToken": "eyJhbGc...",
#   "user": { id, email, firstName, ... }
# }
```

### 2. Login (Mobile)
- Use credentials from above in login screen

### 3. Get Available Slots (Backend)
```bash
# First get your access token from login
TOKEN="<your_accessToken>"

curl -X GET "http://localhost:3000/slots?doctor_id=<id>&clinicId=<id>" \
  -H "Authorization: Bearer $TOKEN"
```

### 4. Create Appointment (Backend)
```bash
curl -X POST http://localhost:3000/appointments \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "slot_id":"<slot_id>",
    "reason":"Check up symptoms"
  }'

# Response: { id, status: "PENDING", ... }
```

### 5. View My Appointments (Mobile)
- Open "Appointments" tab → see booked appointment

### 6. AI Triage (Backend)
```bash
curl -X POST http://localhost:3000/ai/triage \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "symptoms":["headache","fever"],
    "duration":"3 days",
    "severity":"moderate"
  }'

# Response:
# {
#   "recommended_specialties": ["Tổng quát", "Nhi khoa"],
#   "urgency_level": "NEN_DI_SOM",
#   "follow_up_questions": ["..."],
#   "disclaimer": "..."
# }
```

### 7. Pre-visit Summary (Backend)
```bash
curl -X POST http://localhost:3000/ai/previsit-summary \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patientData":{"firstName":"Nguyễn","age":30},
    "appointment_id":"<appointment_id>"
  }'

# Response:
# {
#   "summary": ["• Bệnh nhân: Nguyễn...", ...],
#   "keyPoints": [...],
#   "recommendations": [...]
# }
```

---

## 📊 Database Seed Data

Seed script tạo:
- **1 Admin user**: `admin@clinic.local` / `admin123`
- **2 Doctor**: `doctor1@clinic.local`, `doctor2@clinic.local` (password: `doctor123`)
- **1 Patient**: `patient@clinic.local` (password: `patient123`)
- **2 Clinics**: Clinic Center, International Hospital
- **5 Specialties**: Tổng quát, Tim mạch, Da liễu, Tâm thần, Nhi khoa
- **3 Sample Slots**: Tomorrow at 08:00, 09:00, 14:00

---

## 🐛 Troubleshooting

### Backend Issues

**PostgreSQL Connection Error**
```
Error: connect ECONNREFUSED 127.0.0.1:5432
```
→ Check PostgreSQL is running: `psql -U postgres`

**Database Not Found**
```
Error: database "clinic_ai" does not exist
```
→ Create database: `CREATE DATABASE clinic_ai;` in PostgreSQL terminal

**Module Not Found**
```
Cannot find module '@/...'
```
→ Run: `npm install` in backend folder
→ Check tsconfig.json paths mapping

**Port Already in Use**
```
Error: listen EADDRINUSE :::3000
```
→ Kill process: `lsof -i :3000` then `kill -9 <PID>`
→ Or change PORT in .env

### Mobile Issues

**Flutter Not Installed**
```
flutter: command not found
```
→ Add Flutter to PATH or reinstall

**Gradle Build Error** (Android)
```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

**Xcode Build Error** (iOS)
```bash
flutter clean
flutter pub get
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter run
```

**Cannot Connect to Backend**
- Check backend URL in `api_config.dart`
- For emulator: `10.0.2.2:3000` (Android) or `localhost:3000` (iOS)
- For device: use your machine IP: `192.168.x.x:3000`
- Check firewall isn't blocking port 3000

**Token Expired**
- Token auto-refreshes via Dio interceptor
- If still failing: logout and login again

---

## 📝 Useful Commands

### Backend
```bash
cd backend

# Development
npm run start:dev          # Hot-reload dev server
npm run build              # Compile TypeScript
npm run lint               # Check code quality

# Database
npx prisma studio         # View/edit data graphically
npx prisma migrate dev     # Create new migration
npx prisma db seed         # Re-seed data
npx prisma db push         # Sync schema without migration

# Testing
npm test                   # Run unit tests
npm run test:e2e           # End-to-end tests
```

### Mobile
```bash
cd mobile

# Running
flutter run                # Dev on any device
flutter run -d web         # Run on browser
flutter run --profile      # Performance profiling
flutter run --release      # Optimized build

# Development
flutter pub get            # Install dependencies
flutter pub upgrade        # Upgrade packages
flutter format lib/        # Format code
flutter analyze            # Check code

# Building
flutter build apk          # Android APK
flutter build ios          # iOS app
flutter clean              # Clean build artifacts
flutter pub run build_runner build  # Generate code
```

---

## 🌍 API Base URL

Change in `mobile/lib/core/config/api_config.dart`:

```dart
// For local development
const String baseUrl = 'http://localhost:3000';

// For Android emulator
const String baseUrl = 'http://10.0.2.2:3000';

// For physical device (replace with your IP)
const String baseUrl = 'http://192.168.1.100:3000';

// For production
const String baseUrl = 'https://api.clinic.io';
```

---

## 📚 Documentation

- [Backend README](./backend/README.md) - NestJS details
- [Mobile README](./mobile/README.md) - Flutter details
- [Project Structure](./docs/STRUCTURE.md) - Architecture overview
- [API Endpoints](./docs/API.md) - (To be created)

---

## ✅ Checklist

### Backend ✅
- [x] NestJS app setup
- [x] Prisma ORM configured
- [x] Auth module with JWT
- [x] Appointments with anti-collision
- [x] AI Triage service
- [x] Notifications framework
- [x] Database seed data
- [ ] Swagger API docs
- [ ] Unit tests
- [ ] Real LLM integration

### Mobile ✅
- [x] Flutter app structure
- [x] Dio HTTP client
- [x] Token interceptor
- [x] Login screen
- [x] Home screen with tabs
- [ ] Doctor search
- [ ] Booking flow
- [ ] AI Triage UI
- [ ] Doctor portal
- [ ] Admin portal
- [ ] Push notifications

---

## 💡 Tips

1. **Use Prisma Studio to inspect data:**
   ```bash
   cd backend && npx prisma studio
   ```

2. **Save API responses in Postman for testing**

3. **Use `flutter hot reload` (press `r`) for fast mobile development**

4. **Check logs in backend terminal for debugging**

5. **Test auth flow with Postman before mobile integration**

---

**Happy Coding! 🎉**

For issues, check README files or GitHub Issues.
