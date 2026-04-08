# Backend Modules Checklist

## ✅ Implemented Modules

### 1. **Auth Module** ✅ COMPLETE
**File**: `src/modules/auth/`

**Features**:
- Register new patient
- Login with email/password
- JWT access token + refresh token
- Token refresh endpoint
- Logout with token revocation
- Password bcrypt hashing
- Token storage in database

**Endpoints**:
- `POST /auth/register` - Create patient account
- `POST /auth/login` - Login, get tokens
- `POST /auth/refresh` - Refresh expired access token
- `POST /auth/logout` - Logout, revoke token

**Security**:
- bcryptjs for password hashing (10 rounds)
- JWT signing with HS256
- Refresh token hashing (SHA256)
- Token expiry validation
- Request validation (class-validator)

**Status**: ✅ Fully implemented, compiles & works

---

### 2. **Appointments Module** ✅ COMPLETE
**File**: `src/modules/appointments/`

**Features**:
- Create appointment (anti-collision booking with transaction)
- Get my appointments (patient view)
- Get doctor appointments (doctor view)
- Update appointment status/notes
- Cancel appointment
- Status workflow: PENDING → CONFIRMED → COMPLETED/NO_SHOW

**Endpoints**:
- `POST /appointments` - Create (requires PATIENT role)
- `GET /appointments/my` - My appointments (PATIENT only)
- `GET /appointments/doctor` - Doctor's appointments (DOCTOR only)
- `PATCH /appointments/:id` - Update status/notes
- `DELETE /appointments/:id` - Cancel appointment

**Key Feature**: **Anti-collision booking**
```typescript
// Transaction ensures:
1. Check slot exists & not blocked
2. Check NO appointment for this slot yet
3. Create appointment atomically
// Race condition handled by DB constraint
```

**Security**:
- Role-based access (only own appointments)
- Appointment authorization check

**Status**: ✅ Fully implemented, compiles & works

---

### 3. **AI Module** ✅ COMPLETE
**File**: `src/modules/ai/`

**Features**:
- Triage analysis (symptom → specialty + urgency)
- Pre-visit summary generation
- JSON schema validation
- Mock LLM implementation (keyword-based)

**Endpoints**:
- `POST /ai/triage` - Analyze symptoms
- `POST /ai/previsit-summary` - Generate doctor summary

**Input/Output**:

**Triage Request**:
```json
{
  "symptoms": ["headache", "fever"],
  "duration": "3 days",
  "severity": "moderate"
}
```

**Triage Response**:
```json
{
  "recommended_specialties": ["Tổng quát", "Nhi khoa"],
  "urgency_level": "NEN_DI_SOM",
  "follow_up_questions": ["Bạn đã dùng thuốc gì?", "..."],
  "disclaimer": "Vui lòng tư vấn bác sĩ..."
}
```

**Pre-visit Summary Request**:
```json
{
  "patientData": {"firstName": "Nguyễn", "age": 30},
  "appointmentId": "appt-123"
}
```

**Response**:
```json
{
  "summary": ["• Bệnh nhân: Nguyễn...", ...],
  "keyPoints": ["Chuẩn bị khám chi tiết"],
  "recommendations": ["Khám toàn diện"]
}
```

**Status**: 
- ✅ Framework complete
- 🔲 Mock implementation (keyword matching)
- 🔲 TODO: Replace with real OpenAI/Anthropic API

**Placeholder Logic**:
- "chest" → Tim mạch (urgency: KHAN)
- "fever" → Tổng quát (urgency: NEN_DI_SOM)
- "anxiety" → Tâm thần (urgency: THUONG)

**Status**: ✅ Compiles & works with mock data

---

### 4. **Notifications Module** ✅ FRAMEWORK READY
**File**: `src/modules/notifications/`

**Features**:
- Save FCM token for push notifications
- Cron scheduler (every 15 minutes)
- Check upcoming appointments
- Placeholder for Firebase Cloud Messaging

**Endpoints**:
- `POST /notifications/fcm-token` - Save device token

**Cron Job**:
```typescript
@Cron(CronExpression.EVERY_15_MINUTES)
async sendAppointmentReminders() {
  // Query appointments starting in next 1 hour
  // For each: call sendPushNotification()
  // Currently logs only (TODO: FCM integration)
}
```

**FCM Integration Checklist**:
- [ ] Setup Firebase Admin SDK
- [ ] Import credentials JSON
- [ ] Implement `sendPushNotification()`
- [ ] Test with Firebase Console
- [ ] Mobile: Implement Firebase Messaging listener

**Status**: 
- ✅ Framework complete + Cron setup
- 🔲 TODO: Firebase Admin SDK integration

---

### 5. **Doctors Module** 🔲 PLACEHOLDER
**File**: `src/modules/doctors/`

**Planned Features**:
- List doctors with filtering (specialty, clinic, rating)
- Get doctor detail + availability
- Doctor approval workflow (admin)
- Doctor rating/reviews

**Planned Endpoints**:
- `GET /doctors` - List with filters
- `GET /doctors/:id` - Detail
- `PATCH /doctors/:id/approve` - Admin approval

**Status**: 🔲 Placeholder module only

**TODO**:
1. Create DoctorsController
2. Create DoctorsService with queries
3. Add filtering (specialtyId, clinicId, isApproved)
4. Add pagination

---

### 6. **Patients Module** 🔲 PLACEHOLDER
**File**: `src/modules/patients/`

**Planned Features**:
- Get patient profile
- Update patient profile
- Medical history
- Allergies & medications

**Planned Endpoints**:
- `GET /patients/:id` - Get profile
- `PATCH /patients/:id` - Update profile

**Status**: 🔲 Placeholder module only

---

### 7. **Specialties Module** 🔲 PLACEHOLDER
**File**: `src/modules/specialties/`

**Planned Features**:
- List all medical specialties
- Filter doctors by specialty
- Specialty icons/descriptions

**Planned Endpoints**:
- `GET /specialties` - List all

**Status**: 🔲 Placeholder module only

---

### 8. **Slots Module** 🔲 PLACEHOLDER
**File**: `src/modules/slots/`

**Planned Features**:
- List available slots (doctor/clinic/date)
- Block/unblock slot (admin)
- Create bulk slots

**Planned Endpoints**:
- `GET /slots` - Query with filters (doctorId, clinicId, date)
- `POST /slots` - Create (admin)
- `PATCH /slots/:id/block` - Block slot (admin)

**Status**: 🔲 Placeholder module only

---

### 9. **Clinics Module** 🔲 PLACEHOLDER
**File**: `src/modules/clinics/`

**Planned Features**:
- List clinics
- Clinic details
- Clinic hours
- Doctors at clinic

**Planned Endpoints**:
- `GET /clinics` - List
- `GET /clinics/:id` - Detail

**Status**: 🔲 Placeholder module only

---

### 10. **Users Module** 🔲 PLACEHOLDER
**File**: `src/modules/users/`

**Planned Features**:
- User management (by admin)
- Role assignment
- User status (active/inactive)

**Status**: 🔲 Placeholder module only

---

### 11. **Admin Module** 🔲 NOT STARTED
**File**: `src/modules/admin/` (to be created)

**Planned Features**:
- Doctor approval workflow
- Clinic management CRUD
- Specialty management
- Slot management
- User management
- Audit logs

**Planned Endpoints**:
- `POST /admin/doctors` - Create doctor
- `PATCH /admin/doctors/:id` - Update
- `POST /admin/doctors/:id/approve` - Approve
- `DELETE /admin/doctors/:id` - Deactivate
- ... (clinic, specialty, slot endpoints)

**Status**: 🔲 Not started

---

## Common Guards & Decorators

**File**: `src/common/`

### JwtGuard
```typescript
@UseGuards(JwtGuard)
// Verifies JWT token in Authorization header
// If valid: req.user = payload { sub, email, role }
// If invalid/missing: throws UnauthorizedException
```

### RolesGuard
```typescript
@UseGuards(JwtGuard, RolesGuard)
@Roles(UserRole.patient)
// Checks if user.role matches required roles
// Must combine with @Roles() decorator
```

### Decorators
```typescript
@CurrentUser()  // Get entire user payload
@CurrentUser('sub')  // Get specific property (userId)
@CurrentUser('role')  // Get role
```

---

## Database Models Summary

| Model | Purpose | Key Fields |
|-------|---------|-----------|
| User | Core user account | id, email, password, role |
| RefreshToken | Token management | tokenHash, expiresAt, revokedAt |
| FcmToken | Push notifications | token, userId |
| PatientProfile | Patient specific | userId, dateOfBirth, allergies, medicalHistory |
| Doctor | Doctor info | userId, licenseNumber, specialtyId, isApproved |
| Specialty | Medical field | name, description |
| Clinic | Healthcare facility | name, address, city, phone |
| DoctorClinic | Doctor works at clinic | doctorId, clinicId (M:M junction) |
| Slot | Doctor time slot | doctorId, clinicId, startAt, endAt, isBlocked |
| Appointment | Booking | patientId, doctorId, slotId (UNIQUE), status, triageJson |
| TriageResult | AI cache | appointmentId, symptoms, recommendedSpecialties, urgencyLevel |
| AdminProfile | Admin user | userId |
| AuditLog | Audit trail | userId, action, entity, entityId |

---

## Implementation Priority

### Phase 1 (DONE ✅)
1. Auth module - register/login/refresh
2. Appointments - booking with transaction
3. AI module - mock triage
4. Notifications framework - FCM skeleton

### Phase 2 (TODO 🔲)
1. Doctors endpoints
2. Slots endpoints
3. Specialties endpoints
4. Clinics endpoints
5. Patient profiles

### Phase 3 (TODO 🔲)
1. Admin module
2. Real LLM integration (OpenAI)
3. FCM integration
4. Email notifications
5. Swagger documentation

### Phase 4 (TODO 🔲)
1. Advanced filters & search
2. Pagination
3. Rate limiting
4. Caching (Redis)
5. Logging/Monitoring

---

## Testing the Modules

### Test Auth
```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456","firstName":"Test","lastName":"User"}'
```

### Test Appointments
```bash
# Get token first, then:
curl -X GET http://localhost:3000/appointments/my \
  -H "Authorization: Bearer $TOKEN"
```

### Test AI Triage
```bash
curl -X POST http://localhost:3000/ai/triage \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"symptoms":["fever","cough"]}'
```

### Test Notifications
```bash
curl -X POST http://localhost:3000/notifications/fcm-token \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"token":"abc123xyz"}'
```

---

**All implemented modules compile and run successfully!** 🚀
