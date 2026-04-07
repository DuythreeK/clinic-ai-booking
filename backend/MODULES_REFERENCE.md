# Backend Modules Specification

## 📦 Complete Module Reference

### 1. Auth Module (`/auth`)

**Purpose**: User authentication and authorization

**Endpoints**:
- `POST /auth/register` - Register new user with email, password, name
- `POST /auth/login` - Login with email/password, returns JWT tokens
- `POST /auth/refresh` - Refresh access token using refresh token
- `POST /auth/logout` - Logout and revoke refresh token

**Features**:
- JWT-based authentication
- Refresh token rotation
- Password hashing with bcrypt
- Token revocation

**Key Classes**:
- `AuthService`: Handles authentication logic
- `AuthController`: REST endpoints
- `JwtGuard`: Protects authenticated routes
- `RegisterDto`, `LoginDto`, `RefreshTokenDto`: Input validation

**Database Models**:
- User
- RefreshToken

---

### 2. Doctors Module (`/doctors`)

**Purpose**: Manage doctor profiles, licenses, and availability

**Endpoints**:
- `POST /doctors` - Create doctor profile (admin)
- `GET /doctors` - List all doctors with filters
- `GET /doctors/:id` - Get specific doctor details
- `PATCH /doctors/:id` - Update own doctor profile
- `PATCH /doctors/:id/approve` - Approve doctor (admin)
- `GET /doctors/:doctorId/availability` - Get availability

**Features**:
- Doctor profile management
- License validation and uniqueness
- Approval workflow
- Specialty assignment
- Rating and reviews tracking

**Key Classes**:
- `DoctorsService`: Business logic for doctor management
- `DoctorsController`: REST endpoints
- `CreateDoctorDto`, `UpdateDoctorDto`, `ApproveDoctorDto`: DTOs

**Database Models**:
- Doctor
- User
- Specialty

**Authorization**: 
- DOCTOR can manage own profile
- ADMIN can approve and manage all doctors

---

### 3. Appointments Module (`/appointments`)

**Purpose**: Manage appointment booking and lifecycle

**Endpoints**:
- `POST /appointments` - Create new appointment
- `GET /appointments` - List appointments with filters
- `GET /appointments/:id` - Get appointment details
- `PATCH /appointments/:id` - Update pending appointment
- `PATCH /appointments/:id/status` - Update appointment status
- `POST /appointments/:id/reschedule` - Reschedule appointment
- `POST /appointments/:id/cancel` - Cancel appointment
- `POST /appointments/:id/doctor-notes` - Add doctor notes
- `DELETE /appointments/:id` - Delete appointment (admin)

**Features**:
- Appointment booking with slot validation
- Status state machine (PENDING → CONFIRMED → COMPLETED)
- Rescheduling with automatic old appointment cancellation
- Doctor notes for completed appointments
- Advanced filtering by patient, doctor, status, date range

**Key Classes**:
- `AppointmentsService`: Complex appointment logic
- `AppointmentsController`: REST endpoints
- `CreateAppointmentDto`, `RescheduleAppointmentDto`: Input DTOs

**Database Models**:
- Appointment
- Slot
- Doctor
- PatientProfile
- User

**Authorization**:
- PATIENT: Manage own appointments
- DOCTOR: Update status and add notes
- ADMIN: Full access

**Business Logic**:
```typescript
// Status transitions
PENDING → CONFIRMED → COMPLETED
PENDING/CONFIRMED/COMPLETED → CANCELLED (from any)

// Slot validation
- Check slot availability before booking
- Prevent double booking
- Validate doctor and patient exist
```

---

### 4. Clinics Module (`/clinics`)

**Purpose**: Manage clinic locations and information

**Endpoints**:
- `POST /clinics` - Create clinic (admin)
- `GET /clinics` - List all clinics
- `GET /clinics/:id` - Get clinic details
- `PATCH /clinics/:id` - Update clinic (admin)
- `DELETE /clinics/:id` - Delete clinic (admin)

**Features**:
- Clinic location management
- Hours of operation
- Address and contact information
- Doctor-clinic associations

**Key Classes**:
- `ClinicsService`: Clinic management logic
- `ClinicsController`: REST endpoints
- `CreateClinicDto`, `UpdateClinicDto`: DTOs

**Database Models**:
- Clinic
- DoctorClinic (junction table)

**Fields**:
- name, address, city, country
- phone, email
- hours (JSON format)

---

### 5. Slots Module (`/slots`)

**Purpose**: Manage doctor availability time slots

**Endpoints**:
- `POST /slots` - Create single slot
- `POST /slots/bulk` - Create multiple slots (recurring)
- `GET /slots` - List slots with filters
- `GET /slots/available` - Get available unbooked slots
- `PATCH /slots/:id` - Update slot (block/unblock)
- `DELETE /slots/:id` - Delete slot

**Features**:
- Single slot creation
- Bulk slot creation with recurring schedules
- Conflict detection (prevent double-booking)
- Blocking/unavailability handling
- Advanced filtering by doctor, clinic, date range

**Key Classes**:
- `SlotsService`: Slot management and conflict prevention
- `SlotsController`: REST endpoints
- `CreateSlotDto`, `CreateBulkSlotsDto`: Input validation

**Database Models**:
- Slot (with unique constraint on doctorId, clinicId, startAt, endAt)

**Advanced Features**:
```typescript
// Bulk creation
{
  doctorId: string;
  clinicId: string;
  startDate: "2024-01-15";  // YYYY-MM-DD
  endDate: "2024-01-31";
  startTime: "09:00";       // HH:mm
  endTime: "17:00";
  slotDuration: 30;         // minutes
  daysOfWeek: [1, 2, 3, 4, 5];  // Mon-Fri (0=Sunday)
}
```

---

### 6. Specialties Module (`/specialties`)

**Purpose**: Manage medical specialties

**Endpoints**:
- `POST /specialties` - Create specialty (admin)
- `GET /specialties` - List all specialties
- `GET /specialties/:id` - Get specialty details
- `PATCH /specialties/:id` - Update specialty (admin)
- `DELETE /specialties/:id` - Delete specialty (admin)

**Features**:
- Specialty definition and management
- Uniqueness validation
- Icon/category support
- Doctor-specialty associations

**Key Classes**:
- `SpecialtiesService`: Specialty management
- `SpecialtiesController`: REST endpoints
- `CreateSpecialtyDto`, `UpdateSpecialtyDto`: DTOs

**Database Models**:
- Specialty

**Fields**:
- name (unique)
- description
- icon (URL)

---

### 7. Patients Module (`/patients`)

**Purpose**: Manage patient profiles and medical information

**Endpoints**:
- `GET /patients/profile` - Get own patient profile
- `PATCH /patients/profile` - Update own profile
- `DELETE /patients/profile` - Delete own profile

**Features**:
- Medical history tracking
- Allergies documentation
- Current medications
- Emergency contact information
- Date of birth and demographics

**Key Classes**:
- `PatientsService`: Patient profile management
- `PatientsController`: REST endpoints
- `UpdatePatientProfileDto`: Profile update validation

**Database Models**:
- PatientProfile
- User

**Fields**:
- dateOfBirth, gender, address
- medicalHistory (JSON)
- allergies (JSON)
- currentMedications (JSON)
- emergencyPhone

**Authorization**:
- PATIENT: Can only manage own profile

---

### 8. Users Module (`/users`)

**Purpose**: Manage user accounts and access control

**Endpoints**:
- `GET /users` - List users (admin)
- `GET /users/:id` - Get user details
- `PATCH /users/:id` - Update user profile
- `POST /users/:id/change-password` - Change password
- `PATCH /users/:id/toggle-active` - Activate/deactivate (admin)
- `DELETE /users/:id` - Delete user (admin)

**Features**:
- User account management
- Password change functionality
- Account activation/deactivation
- Role management
- Profile updates

**Key Classes**:
- `UsersService`: User management logic
- `UsersController`: REST endpoints
- `UpdateUserDto`, `ChangePasswordDto`: Input validation

**Database Models**:
- User

**Authorization**:
- PATIENT/DOCTOR: Manage own profile
- ADMIN: Manage all users

---

### 9. AI Module (`/ai`)

**Purpose**: AI-powered medical services

**Endpoints**:
- `POST /ai/triage` - AI symptom triage
- `POST /ai/previsit-summary` - Pre-visit summary for doctor

**Features**:
- Symptom-based specialty recommendations
- Urgency level assessment (THUONG, NEN_DI_SOM, KHAN)
- Follow-up questions generation
- Pre-visit summary generation

**Key Classes**:
- `AiService`: AI logic (currently mock, ready for LLM integration)
- `AiController`: REST endpoints
- `TriageRequestDto`, `PrevisitSummaryRequestDto`: Input validation

**Mock Implementation**:
```typescript
// Keyword-based matching for demo
Input: "chest pain" → Output:
{
  recommended_specialties: ["Tim mạch", "Tổng quát"],
  urgency_level: "KHAN",
  follow_up_questions: [...]
}
```

**Integration Points**:
- OpenAI GPT-4 API
- Anthropic Claude API
- Local LLM models

---

### 10. Notifications Module (`/notifications`)

**Purpose**: Push notifications and reminders

**Endpoints**:
- `POST /notifications/fcm-token` - Save Firebase Cloud Messaging token

**Features**:
- FCM token management
- Appointment reminders (cron job)
- Push notification delivery
- Token rotation handling

**Key Classes**:
- `NotificationsService`: Notification logic with scheduled reminders
- `NotificationsController`: REST endpoints
- `SaveFcmTokenDto`: Token validation

**Database Models**:
- FcmToken
- Appointment (referenced for reminders)

**Scheduled Tasks**:
```typescript
// Every 5 minutes
- Check upcoming appointments (next 1 hour)
- Send push notifications to patients and doctors
- Log notification attempts
```

**Future Implementation**:
- Firebase Admin SDK integration
- Email notifications
- SMS notifications via Twilio

---

## 🔐 Authorization Patterns

### JwtGuard (Authentication)
Protects all endpoints requiring authentication

```typescript
@UseGuards(JwtGuard)
async method() { }
```

### RolesGuard (Authorization)
Restricts endpoints to specific roles

```typescript
@UseGuards(JwtGuard, RolesGuard)
@Roles(UserRole.ADMIN)
async method() { }
```

### Custom Decorator
Extract current user from token

```typescript
@CurrentUser('sub') userId: string
@CurrentUser() user: JwtPayload
```

---

## 📊 Common Data Patterns

### Pagination
```typescript
{
  skip: number;
  take: number;
}
```

### Filtering
```typescript
where: {
  status: AppointmentStatus.PENDING,
  doctorId: string,
  patientId: string,
  createdAt: { gte: Date, lte: Date }
}
```

### Error Handling
```typescript
throw new NotFoundException('Resource not found');
throw new BadRequestException('Invalid input');
throw new ForbiddenException('Access denied');
throw new UnauthorizedException('Invalid credentials');
```

---

## 🧩 Module Dependencies

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

## 💡 Implementation Notes

1. **DTOs**: All API requests/responses use DTOs for validation
2. **Services**: Business logic isolated in service classes
3. **Prisma**: Database operations through Prisma ORM
4. **Error Handling**: Consistent exception throwing
5. **Decorators**: Custom decorators for common patterns
6. **Guards**: Reusable guards for security
7. **Validation**: Global ValidationPipe + class-validator decorators
