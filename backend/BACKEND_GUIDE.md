# Backend Complete Documentation

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- MySQL 8.0+
- npm or yarn

### Installation

```bash
cd backend

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Set up database
npx prisma migrate dev

# Seed database (optional)
npx prisma db seed

# Run development server
npm run start:dev

# Build for production
npm run build
npm run start:prod
```

## 📚 API Documentation

### Access Swagger UI
Once the server is running, visit:
```
http://localhost:3000/api/docs
```

## 🏗️ Project Structure

```
backend/
├── src/
│   ├── app.module.ts                 # Main application module
│   ├── main.ts                       # Application entry point
│   ├── common/
│   │   ├── decorators/               # Custom decorators
│   │   │   ├── current-user.decorator.ts
│   │   │   └── roles.decorator.ts
│   │   └── guards/                   # Route guards
│   │       ├── jwt.guard.ts
│   │       └── roles.guard.ts
│   ├── modules/
│   │   ├── auth/                     # Authentication & authorization
│   │   ├── appointments/             # Appointment booking & management
│   │   ├── doctors/                  # Doctor profiles
│   │   ├── clinics/                  # Clinic management
│   │   ├── slots/                    # Time slot management
│   │   ├── specialties/              # Medical specialties
│   │   ├── patients/                 # Patient profiles
│   │   ├── users/                    # User account management
│   │   ├── ai/                       # AI triage & summaries
│   │   └── notifications/            # Push notifications
│   └── prisma/
│       ├── prisma.module.ts
│       └── prisma.service.ts
├── prisma/
│   ├── schema.prisma                 # Database schema
│   └── seed.ts                       # Database seeding
├── nest-cli.json
├── tsconfig.json
└── package.json
```

## 🔐 Authentication

All API endpoints (except `/auth/register` and `/auth/login`) require Bearer token authentication:

```bash
Authorization: Bearer <access_token>
```

### Roles-based Access Control

- **PATIENT**: Can manage own appointments and profile
- **DOCTOR**: Can view appointments, add notes, manage availability
- **ADMIN**: Full access to all resources

## 📋 API Endpoints Overview

### Authentication (`/auth`)
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login user
- `POST /auth/refresh` - Refresh access token
- `POST /auth/logout` - Logout user

### Doctors (`/doctors`)
- `POST /doctors` - Create doctor profile (admin only)
- `GET /doctors` - List all doctors
- `GET /doctors/:id` - Get doctor details
- `PATCH /doctors/:id` - Update doctor profile
- `PATCH /doctors/:id/approve` - Approve doctor (admin only)
- `GET /doctors/availability/:id` - Get doctor availability

### Appointments (`/appointments`)
- `POST /appointments` - Book appointment
- `GET /appointments` - List appointments (filtered by user)
- `GET /appointments/:id` - Get appointment details
- `PATCH /appointments/:id` - Update appointment (PENDING only)
- `PATCH /appointments/:id/status` - Update status
- `POST /appointments/:id/reschedule` - Reschedule appointment
- `POST /appointments/:id/cancel` - Cancel appointment
- `POST /appointments/:id/doctor-notes` - Add doctor notes
- `DELETE /appointments/:id` - Delete appointment (admin only)

### Clinics (`/clinics`)
- `POST /clinics` - Create clinic (admin only)
- `GET /clinics` - List all clinics
- `GET /clinics/:id` - Get clinic details
- `PATCH /clinics/:id` - Update clinic (admin only)
- `DELETE /clinics/:id` - Delete clinic (admin only)

### Slots (`/slots`)
- `POST /slots` - Create time slot
- `POST /slots/bulk` - Create multiple slots
- `GET /slots` - List slots with filters
- `GET /slots/available` - Get available slots
- `PATCH /slots/:id` - Update slot
- `DELETE /slots/:id` - Delete slot

### Specialties (`/specialties`)
- `POST /specialties` - Create specialty (admin only)
- `GET /specialties` - List all specialties
- `GET /specialties/:id` - Get specialty details
- `PATCH /specialties/:id` - Update specialty (admin only)
- `DELETE /specialties/:id` - Delete specialty (admin only)

### Patients (`/patients`)
- `GET /patients/profile` - Get own patient profile
- `PATCH /patients/profile` - Update own profile
- `DELETE /patients/profile` - Delete own profile

### Users (`/users`)
- `GET /users` - List users (admin only)
- `GET /users/:id` - Get user details
- `PATCH /users/:id` - Update user
- `POST /users/:id/change-password` - Change password
- `PATCH /users/:id/toggle-active` - Toggle user active status (admin only)
- `DELETE /users/:id` - Delete user (admin only)

### AI (`/ai`)
- `POST /ai/triage` - AI-powered symptom triage
- `POST /ai/previsit-summary` - Generate pre-visit summary for doctor

### Notifications (`/notifications`)
- `POST /notifications/fcm-token` - Save Firebase Cloud Messaging token

## 🗄️ Database Schema

### Key Models

#### User
- Authentication and authorization
- Related to Doctor, PatientProfile, AdminProfile

#### Doctor
- Doctor profile with license and specialty
- Relationships with User, Clinic (via DoctorClinic), Appointment

#### PatientProfile
- Patient medical information
- Related to User, Appointment

#### Appointment
- Booking with status state machine (PENDING → CONFIRMED → COMPLETED)
- Links Patient, Doctor, Slot
- Tracks reschedule history

#### Slot
- Doctor availability time slots
- Has conflict prevention mechanism
- Can be blocked

#### Clinic
- Physical clinic locations
- Links to multiple Doctors via DoctorClinic junction table

#### FcmToken
- Firebase Cloud Messaging tokens for push notifications

## 🛡️ Security Features

1. **JWT Authentication**: Secure token-based authentication
2. **Password Hashing**: bcrypt for password security
3. **Role-Based Access Control**: PATIENT, DOCTOR, ADMIN roles
4. **Input Validation**: Global ValidationPipe with class-validator
5. **CORS Configuration**: Configurable origin whitelist
6. **Refresh Token Rotation**: Secure token refresh mechanism
7. **Rate Limiting**: Built-in with NestJS tools

## 📝 DTOs (Data Transfer Objects)

All API requests/responses use DTOs for validation and documentation:

```typescript
// Example: CreateAppointmentDto
export class CreateAppointmentDto {
  patientId: string;
  doctorId: string;
  slotId: string;
  reason: string;
  attachments?: string[];
}
```

## 🚀 Deployment

### Environment Variables for Production

```bash
NODE_ENV=production
JWT_SECRET=<strong-random-secret>
DATABASE_URL=mysql://user:password@prod-host:3306/clinic_booking
CORS_ORIGIN=https://your-domain.com
```

### Docker Deployment

```bash
docker build -t clinic-booking-backend .
docker run -e DATABASE_URL=... -p 3000:3000 clinic-booking-backend
```

### Database Migration

```bash
npx prisma migrate deploy
npx prisma db push
```

## 🧪 Testing

```bash
# Run unit tests
npm run test

# Run e2e tests
npm run test:e2e

# Coverage
npm run test:cov
```

## 📦 Development Commands

```bash
# Start dev server with auto-reload
npm run start:dev

# Start production server
npm start

# Build for production
npm run build

# Format code
npm run format

# Lint code
npm run lint

# Generate Prisma client
npx prisma generate

# Open Prisma Studio (interactive database browser)
npx prisma studio

# Run database migrations
npx prisma migrate dev --name migration_name
npx prisma migrate deploy
```

## 🐛 Troubleshooting

### Database Connection Issues
- Ensure MySQL is running
- Check DATABASE_URL in .env
- Verify MySQL user permissions

### JWT Errors
- Ensure JWT_SECRET is set in .env
- Check token hasn't expired
- Verify token format in Authorization header

### CORS Issues
- Update CORS_ORIGIN in .env
- Ensure proper header configuration

## 📞 Support

For issues or questions:
1. Check Swagger documentation at `/api/docs`
2. Review error messages in console
3. Check `.env` configuration
4. Review Prisma schema documentation

## 📄 License

MIT
