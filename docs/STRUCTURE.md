# Project Structure Overview

## Folder Tree (Chi tiết)

```
clinic-ai-booking/
│
├── .git/                                    # Git repository
├── .gitignore                               # Git ignore rules
├── README.md                                # Root documentation (Hướng dẫn chạy)
│
├── backend/                                 # ========== BACKEND (NestJS) ==========
│   ├── .env.example                         # Environment template
│   ├── .eslintrc.js                         # ESLint config
│   ├── nest-cli.json                        # NestJS CLI config
│   ├── package.json                         # Dependencies (NestJS, Prisma, etc.)
│   ├── tsconfig.json                        # TypeScript config
│   ├── README.md                            # Backend documentation
│   │
│   ├── src/
│   │   ├── app.module.ts                    # Root module (import all modules)
│   │   ├── main.ts                          # Entry point
│   │   │
│   │   ├── common/                          # Shared guards, decorators, pipes
│   │   │   ├── decorators/
│   │   │   │   ├── current-user.decorator.ts    # @CurrentUser() → access req.user
│   │   │   │   └── roles.decorator.ts          # @Roles() → role requirement
│   │   │   └── guards/
│   │   │       ├── jwt.guard.ts                # JwtGuard: verify token
│   │   │       └── roles.guard.ts              # RolesGuard: check role
│   │   │
│   │   ├── prisma/                          # Prisma ORM
│   │   │   ├── prisma.module.ts
│   │   │   └── prisma.service.ts            # Database connection
│   │   │
│   │   └── modules/                         # Feature modules
│   │       │
│   │       ├── auth/                        # Authentication & JWT
│   │       │   ├── auth.controller.ts       # POST /auth/register, login, refresh, logout
│   │       │   ├── auth.service.ts          # JWT sign, password hash, token refresh
│   │       │   ├── auth.module.ts
│   │       │   └── dto/
│   │       │       └── auth.dto.ts          # RegisterDto, LoginDto, AuthResponseDto
│   │       │
│   │       ├── appointments/                # Booking anti-collision
│   │       │   ├── appointments.controller.ts  # POST /appointments (with transaction)
│   │       │   │                               # GET /appointments/my, /doctor
│   │       │   │                               # PATCH update status
│   │       │   ├── appointments.service.ts     # Appointment logic
│   │       │   ├── appointments.module.ts
│   │       │   └── dto/
│   │       │       └── appointment.dto.ts
│   │       │
│   │       ├── ai/                          # AI Triage & Pre-visit
│   │       │   ├── ai.controller.ts         # POST /ai/triage, /previsit-summary
│   │       │   ├── ai.service.ts            # Mock LLM (TODO: OpenAI integration)
│   │       │   ├── ai.module.ts
│   │       │   └── dto/
│   │       │       └── ai.dto.ts            # TriageRequestDto, PrevisitSummaryDto
│   │       │
│   │       ├── notifications/               # FCM framework
│   │       │   ├── notifications.controller.ts  # POST /notifications/fcm-token
│   │       │   ├── notifications.service.ts     # Cron scheduler + FCM placeholder
│   │       │   ├── notifications.module.ts
│   │       │   └── dto/
│   │       │       └── notification.dto.ts
│   │       │
│   │       ├── doctors/                     # Doctor management
│   │       │   └── doctors.module.ts        # (Placeholder, expand as needed)
│   │       │
│   │       ├── patients/                    # Patient profiles
│   │       │   └── patients.module.ts       # (Placeholder, expand as needed)
│   │       │
│   │       ├── specialties/                 # Medical specialties
│   │       │   └── specialties.module.ts    # (Placeholder, expand as needed)
│   │       │
│   │       ├── slots/                       # Doctor time slots
│   │       │   └── slots.module.ts          # (Placeholder, expand as needed)
│   │       │
│   │       ├── clinics/                     # Clinic management
│   │       │   └── clinics.module.ts        # (Placeholder, expand as needed)
│   │       │
│   │       ├── users/                       # User management
│   │       │   └── users.module.ts          # (Placeholder, expand as needed)
│   │       │
│   │       └── admin/                       # Admin operations (placeholder)
│   │           └── (To be implemented)
│   │
│   ├── prisma/
│   │   ├── schema.prisma                    # FULL Database schema (11 models)
│   │   │                                    # - User, RefreshToken, FcmToken
│   │   │                                    # - PatientProfile, Doctor, Specialty
│   │   │                                    # - Clinic, DoctorClinic, Slot
│   │   │                                    # - Appointment, TriageResult
│   │   │                                    # - AdminProfile, AuditLog
│   │   └── seed.ts                          # Seed: users, doctors, specialties, slots
│   │
│   └── node_modules/                        # npm packages (installed)
│
├── mobile/                                  # ========== MOBILE (Flutter) ==========
│   ├── pubspec.yaml                         # Dependencies (Dio, Firebase, Go Router, etc.)
│   ├── analysis_options.yaml                # Dart lint rules
│   ├── README.md                            # Mobile documentation
│   │
│   ├── lib/
│   │   ├── main.dart                        # App entry point + theme
│   │   ├── router.dart                      # Go Router configuration
│   │   │
│   │   ├── core/                            # Shared core logic
│   │   │   ├── api/
│   │   │   │   └── dio_client.dart          # HTTP client + token interceptor + auto-refresh
│   │   │   ├── config/
│   │   │   │   └── api_config.dart          # API base URLs
│   │   │   ├── storage/
│   │   │   │   └── auth_storage.dart        # Secure storage for tokens
│   │   │   └── models/
│   │   │       └── (API response models - to be added)
│   │   │
│   │   ├── features/                        # Feature-first architecture
│   │   │   ├── auth/
│   │   │   │   ├── screens/
│   │   │   │   │   └── login_screen.dart    # Login UI + validation
│   │   │   │   └── services/
│   │   │   │       └── auth_service.dart    # API calls: login, register, logout
│   │   │   │
│   │   │   ├── booking/
│   │   │   │   ├── screens/
│   │   │   │   │   └── home_screen.dart     # Home with 3 tabs (Search, Appointments, Profile)
│   │   │   │   └── services/
│   │   │   │       └── booking_service.dart # (To be created)
│   │   │   │
│   │   │   ├── appointments/
│   │   │   │   ├── screens/
│   │   │   │   │   └── appointments_list.dart   # (Placeholder)
│   │   │   │   └── services/
│   │   │   │
│   │   │   ├── ai_triage/
│   │   │   │   ├── screens/
│   │   │   │   │   └── triage_form.dart     # (Placeholder)
│   │   │   │   └── services/
│   │   │   │
│   │   │   ├── doctor_portal/
│   │   │   │   └── (Doctor appointment view - placeholder)
│   │   │   │
│   │   │   └── admin_portal/
│   │   │       └── (Admin CRUD - placeholder)
│   │   │
│   │   └── shared/
│   │       ├── widgets/                     # Reusable widgets
│   │       │   └── (To be created)
│   │       └── utils/                       # Utilities
│   │           └── (To be created)
│   │
│   ├── test/                                # Unit & widget tests
│   │   └── (To be created)
│   │
│   ├── ios/                                 # iOS native code
│   │   ├── Podfile                          # CocoaPods config
│   │   ├── Runner.xcodeproj/                # Xcode project
│   │   └── Runner.xcworkspace/              # Xcode workspace
│   │
│   ├── android/                             # Android native code
│   │   ├── build.gradle                     # Gradle config
│   │   ├── app/                             # App module
│   │   └── gradle.properties                # Gradle properties
│   │
│   ├── web/                                 # Web build (Flutter Web)
│   │   └── (Auto-generated)
│   │
│   └── .packages                            # (Generated)
│
├── docs/                                    # ========== DOCUMENTATION ==========
│   └── (Placeholders for API docs, architecture, etc.)
│
└── .github/                                 # (Optional) GitHub workflows
    └── workflows/
        └── (CI/CD to be added)
```

## Database Schema (Prisma)

```
User (role: PATIENT/DOCTOR/ADMIN)
├── RefreshToken (tokenHash, expires_at, revokedAt)
├── FcmToken (token for push notifications)
├── PatientProfile (if PATIENT)
├── Doctor (if DOCTOR)
│   ├── Specialty
│   ├── DoctorClinic (many-to-many with Clinic)
│   └── Slot (assigned time slots)
│       └── Appointment (linked to this slot)
└── AdminProfile (if ADMIN)

Specialty
└── Doctor[]

Clinic
├── DoctorClinic[]
└── Slot[]

Slot
├── Doctor
├── Clinic
└── Appointment (unique constraint: one appointment per slot)

Appointment
├── PatientProfile
├── Doctor
├── Slot
├── TriageResult (cached AI triage output)
└── fields: status, reason, attachments, triageJson, previsitSummary, doctorNotes

AuditLog (for admin tracking)
```

## Key Design Patterns

### Authentication
1. User registers → password bcrypt hashed → access + refresh token generated
2. Access token (15m) + Refresh token (7d) returned
3. Refresh token hash stored in DB (security: server can invalidate)
4. Mobile app saves tokens in secure storage
5. Token auto-refreshed when 401 via mobile interceptor

### Anti-collision Booking
```typescript
// In transaction:
1. Check slot exists and not blocked
2. Check NO appointment for this slot yet (prevents race condition)
3. Create appointment with PENDING status
```

### Token Refresh Flow
```
Mobile: GET /api → header: Authorization: Bearer <expired-token>
Server: 401 Unauthorized
Mobile Interceptor: 
  → GET /auth/refresh { refreshToken }
  → Save new accessToken
  → Retry original request
Server: 200 OK
```

### AI Module
- **Input**: Symptoms, severity, duration
- **Processing**: Mock LLM (keyword matching) → can replace with OpenAI/Anthropic
- **Output**: JSON with specialties, urgency level, follow-up questions
- **Usage**: Save to appointment.triageJson for future reference

### Notifications
- **Framework**: Firebase Cloud Messaging (FCM)
- **Flow**: Mobile saves FCM token → Backend queries appointments → Cron sends push
- **Current**: Placeholder (logs only, ready for FCM integration)

## Compilation & Build

### Backend
```bash
cd backend
npm install
npx prisma generate
npm run build       # Compiles to dist/
npm run start:dev   # Dev with hot-reload
npm run start:prod  # Production
```

### Mobile
```bash
cd mobile
flutter pub get
flutter run         # Dev
flutter build apk   # Android release
flutter build ios   # iOS release
```

## Next Steps (TODO)

### Backend Priority
1. ✅ Auth module (core feature)
2. ✅ Appointments with anti-collision
3. ✅ AI Triage (mock)
4. ✅ Notifications framework
5. 🔲 Implement Doctors CRUD with approval workflow
6. 🔲 Implement Slots management
7. 🔲 Implement Specialties endpoints
8. 🔲 Integrate real LLM (OpenAI)
9. 🔲 Setup Firebase Admin SDK for FCM
10. 🔲 Add Swagger API documentation
11. 🔲 Setup logging/monitoring (Sentry)
12. 🔲 Add Redis for session/token cache

### Mobile Priority
1. ✅ Auth screens (login/register)
2. ✅ Dio client + token interceptor
3. ✅ Home screen skeleton
4. 🔲 Doctor search & filter
5. 🔲 Slot selection & booking
6. 🔲 Appointment list & detail
7. 🔲 AI Triage form
8. 🔲 Doctor portal (view/update appointments)
9. 🔲 Admin portal
10. 🔲 FCM notification handling
11. 🔲 Offline mode support

## Environment Setup

### Backend .env
```
DATABASE_URL="mysql://root:password@localhost:3306/clinic_ai"
JWT_SECRET=...
JWT_REFRESH_SECRET=...
NODE_ENV=development
PORT=3000
```

### Mobile API Config
```dart
const String baseUrl = 'http://localhost:3000'; // or your IP
```

## References

- Prisma: https://www.prisma.io/docs
- NestJS: https://docs.nestjs.com
- Flutter: https://flutter.dev/docs
- Dio: https://pub.dev/packages/dio
- Firebase: https://firebase.google.com/docs
