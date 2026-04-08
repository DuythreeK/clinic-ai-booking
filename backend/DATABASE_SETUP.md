# Database Migration & Setup Guide

## 🔄 Initial Setup

### 1. Create Database

```bash
# Using MySQL CLI
mysql -u root -p
CREATE DATABASE clinic_booking;
USE clinic_booking;
```

### 2. Configure Environment

Create `.env` file in backend directory:

```bash
DATABASE_URL="mysql://user:password@localhost:3306/clinic_booking"
JWT_SECRET="your-secret-key-minimum-32-characters"
JWT_REFRESH_SECRET="your-refresh-secret-minimum-32-characters"
NODE_ENV="development"
PORT=3000
```

### 3. Run Prisma Migrations

```bash
# Install Prisma CLI if not installed
npm install -D prisma

# Generate Prisma client
npx prisma generate

# Run initial migration
npx prisma migrate dev --name init
```

### 4. Seed Database (Optional)

```bash
npx prisma db seed
```

## 📊 Database Schema Overview

### Users Table
- Stores authentication and user profile data
- Roles: PATIENT, DOCTOR, ADMIN
- Relationships: One-to-One with PatientProfile, Doctor, AdminProfile

### Doctor Profile
- Medical license and specialty information
- Approval workflow (isApproved flag)
- Relationships: One-to-Many with Appointment and Slot

### Patient Profile
- Medical history and allergies
- Emergency contact information
- Relationships: One-to-Many with Appointment

### Clinics
- Physical locations where doctors work
- Hours of operation
- Relationships: Many-to-Many with Doctor via DoctorClinic

### Appointment
- Booking records linking Patient, Doctor, and Slot
- Status tracking with state machine
- Supports rescheduling and doctor notes

### Slot
- Doctor availability time slots
- Conflict prevention for double-booking
- Can be blocked for unavailability

### FcmToken
- Firebase Cloud Messaging tokens
- For push notifications

## 🔄 Migrations Workflow

### Create New Migration

```bash
# After changing schema.prisma
npx prisma migrate dev --name descriptive_name
```

### Check Migration Status

```bash
npx prisma migrate status
```

### Reset Database (Development Only)

```bash
# ⚠️ WARNING: This deletes all data!
npx prisma migrate reset
```

### View Database in Studio

```bash
# Opens interactive database browser
npx prisma studio
```

## 📝 Common Migration Scenarios

### Add New Column to Existing Table

1. Update `schema.prisma`:
```prisma
model User {
  // ... existing fields
  newField String?  // optional field
  updatedAt DateTime @updatedAt
}
```

2. Create and run migration:
```bash
npx prisma migrate dev --name add_new_field_to_users
```

### Create New Model/Table

1. Add to `schema.prisma`:
```prisma
model NewEntity {
  id String @id @default(cuid())
  name String
  created_at DateTime @default(now())
}
```

2. Run migration:
```bash
npx prisma migrate dev --name create_new_entity
```

### Rename Field

1. Update `schema.prisma`
2. Create migration:
```bash
npx prisma migrate dev --name rename_field
```

## 🔍 Verification

### Check Migrations Applied

```bash
npx prisma migrate status
```

### Verify Schema Matches Code

```bash
npx prisma db push --skip-generate
```

### Generate Prisma Client After Schema Changes

```bash
npx prisma generate
```

## ⚡ Performance Optimization

### Add Database Indexes

```prisma
model User {
  id String @id
  email String @unique
  created_at DateTime @default(now())
  
  @@index([created_at])
  @@index([email])
}
```

### Connection Pooling

Ensure your DATABASE_URL includes connection pool settings:

```
DATABASE_URL="mysql://user:pass@localhost:3306/clinic_booking?pool_size=10&max_overflow=20"
```

## 🛡️ Backup & Recovery

### Backup Database

```bash
# Using mysqldump
mysqldump -u user -p clinic_booking > backup.sql

# With timestamp
mysqldump -u user -p clinic_booking > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Restore Database

```bash
mysql -u user -p clinic_booking < backup.sql
```

## 📋 Pre-deployment Checklist

- [ ] All migrations applied: `npx prisma migrate status`
- [ ] No pending migrations: `npx prisma migrate deploy`
- [ ] Database connection verified
- [ ] Backup created
- [ ] Environment variables set correctly
- [ ] Run tests: `npm test`
- [ ] Build successful: `npm run build`

## 🔧 Troubleshooting

### Migration Conflicts

If migrations conflict during team development:

```bash
# Reset to specific migration
npx prisma migrate resolve --applied "migration_name"
```

### Schema Validation Errors

```bash
# Validate schema syntax
npx prisma validate
```

### Prisma Client Errors

```bash
# Regenerate client after schema changes
npx prisma generate

# Force regeneration
npx prisma generate --force
```

### Database Connection Issues

```bash
# Test connection
npx prisma db execute --stdin < test.sql

# Check database status
npx prisma db push
```

## 📞 Support

For migration issues:
1. Check `prisma/schema.prisma` syntax
2. Review migration files in `prisma/migrations/`
3. Verify DATABASE_URL is correct
4. Check MySQL service is running
