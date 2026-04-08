/*
  Warnings:

  - You are about to drop the `admin_profiles` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `appointments` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `audit_logs` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `clinics` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `doctor_clinics` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `doctors` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `fcm_tokens` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `patient_profiles` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `refresh_tokens` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `slots` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `specialties` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `triage_results` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `users` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE `admin_profiles` DROP FOREIGN KEY `admin_profiles_userId_fkey`;

-- DropForeignKey
ALTER TABLE `appointments` DROP FOREIGN KEY `appointments_doctorId_fkey`;

-- DropForeignKey
ALTER TABLE `appointments` DROP FOREIGN KEY `appointments_patientId_fkey`;

-- DropForeignKey
ALTER TABLE `appointments` DROP FOREIGN KEY `appointments_slotId_fkey`;

-- DropForeignKey
ALTER TABLE `doctor_clinics` DROP FOREIGN KEY `doctor_clinics_clinicId_fkey`;

-- DropForeignKey
ALTER TABLE `doctor_clinics` DROP FOREIGN KEY `doctor_clinics_doctorId_fkey`;

-- DropForeignKey
ALTER TABLE `doctors` DROP FOREIGN KEY `doctors_specialtyId_fkey`;

-- DropForeignKey
ALTER TABLE `doctors` DROP FOREIGN KEY `doctors_userId_fkey`;

-- DropForeignKey
ALTER TABLE `fcm_tokens` DROP FOREIGN KEY `fcm_tokens_userId_fkey`;

-- DropForeignKey
ALTER TABLE `patient_profiles` DROP FOREIGN KEY `patient_profiles_userId_fkey`;

-- DropForeignKey
ALTER TABLE `refresh_tokens` DROP FOREIGN KEY `refresh_tokens_userId_fkey`;

-- DropForeignKey
ALTER TABLE `slots` DROP FOREIGN KEY `slots_clinicId_fkey`;

-- DropForeignKey
ALTER TABLE `slots` DROP FOREIGN KEY `slots_doctorId_fkey`;

-- DropTable
DROP TABLE `admin_profiles`;

-- DropTable
DROP TABLE `appointments`;

-- DropTable
DROP TABLE `audit_logs`;

-- DropTable
DROP TABLE `clinics`;

-- DropTable
DROP TABLE `doctor_clinics`;

-- DropTable
DROP TABLE `doctors`;

-- DropTable
DROP TABLE `fcm_tokens`;

-- DropTable
DROP TABLE `patient_profiles`;

-- DropTable
DROP TABLE `refresh_tokens`;

-- DropTable
DROP TABLE `slots`;

-- DropTable
DROP TABLE `specialties`;

-- DropTable
DROP TABLE `triage_results`;

-- DropTable
DROP TABLE `users`;

-- CreateTable
CREATE TABLE `tblUser` (
    `userId` BIGINT NOT NULL AUTO_INCREMENT,
    `role` ENUM('admin', 'doctor', 'patient') NOT NULL,
    `fullName` VARCHAR(150) NOT NULL,
    `email` VARCHAR(150) NOT NULL,
    `phone` VARCHAR(20) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `avatar_url` VARCHAR(255) NULL,
    `status` ENUM('active', 'inactive', 'blocked') NOT NULL DEFAULT 'active',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblUser_email_key`(`email`),
    UNIQUE INDEX `tblUser_phone_key`(`phone`),
    PRIMARY KEY (`userId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblRefreshTokens` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `userId` BIGINT NOT NULL,
    `token` VARCHAR(512) NOT NULL,
    `expiresAt` DATETIME(3) NOT NULL,
    `is_revoked` TINYINT NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `tblRefreshTokens_token_key`(`token`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblPasswordResetTokens` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `userId` BIGINT NOT NULL,
    `token` VARCHAR(512) NOT NULL,
    `status` ENUM('PENDING', 'USED', 'EXPIRED') NOT NULL DEFAULT 'PENDING',
    `expiresAt` DATETIME(3) NOT NULL,
    `used_at` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `tblPasswordResetTokens_token_key`(`token`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblPatientProfile` (
    `patientId` BIGINT NOT NULL AUTO_INCREMENT,
    `userId` BIGINT NOT NULL,
    `fullName` VARCHAR(150) NOT NULL,
    `phone_number` VARCHAR(20) NULL,
    `gender` ENUM('male', 'female', 'other') NULL,
    `date_of_birth` DATE NULL,
    `blood_type` VARCHAR(10) NULL,
    `occupation` VARCHAR(100) NULL,
    `ethnicity` VARCHAR(100) NULL,
    `nationality` VARCHAR(100) NULL,
    `address_detail` VARCHAR(255) NULL,
    `province` VARCHAR(100) NULL,
    `district` VARCHAR(100) NULL,
    `ward` VARCHAR(100) NULL,
    `medical_conditions` TEXT NULL,
    `allergies` TEXT NULL,
    `emergency_contact` VARCHAR(100) NULL,
    `relationship_to_user` VARCHAR(50) NULL,
    `is_primary` TINYINT NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblPatientProfile_phone_number_key`(`phone_number`),
    PRIMARY KEY (`patientId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblSpecialty` (
    `specialty_id` BIGINT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(150) NOT NULL,
    `description` TEXT NULL,
    `isActive` TINYINT NOT NULL DEFAULT 1,

    UNIQUE INDEX `tblSpecialty_name_key`(`name`),
    PRIMARY KEY (`specialty_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblFacility` (
    `facilityId` BIGINT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(200) NOT NULL,
    `facility_type` ENUM('hospital', 'clinic', 'vaccination_center') NOT NULL,
    `phone` VARCHAR(20) NULL,
    `email` VARCHAR(150) NULL,
    `address_detail` VARCHAR(255) NOT NULL,
    `province` VARCHAR(100) NULL,
    `district` VARCHAR(100) NULL,
    `ward` VARCHAR(100) NULL,
    `opening_hours` VARCHAR(255) NULL,
    `rating_avg` DECIMAL(2, 1) NOT NULL DEFAULT 0.0,
    `isActive` TINYINT NOT NULL DEFAULT 1,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    PRIMARY KEY (`facilityId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblDoctor` (
    `doctorId` BIGINT NOT NULL AUTO_INCREMENT,
    `userId` BIGINT NOT NULL,
    `fullName` VARCHAR(150) NOT NULL,
    `specialty_id` BIGINT NOT NULL,
    `facilityId` BIGINT NOT NULL,
    `title` VARCHAR(100) NULL,
    `bio` TEXT NULL,
    `experience_years` INTEGER NULL,
    `avatar_url` VARCHAR(255) NULL,
    `consultation_fee` DECIMAL(12, 2) NULL,
    `isActive` TINYINT NOT NULL DEFAULT 1,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblDoctor_userId_key`(`userId`),
    PRIMARY KEY (`doctorId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblService` (
    `serviceId` BIGINT NOT NULL AUTO_INCREMENT,
    `facilityId` BIGINT NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `description` TEXT NULL,
    `price` DECIMAL(12, 2) NOT NULL,
    `duration_minutes` INTEGER NULL,
    `isActive` TINYINT NOT NULL DEFAULT 1,

    PRIMARY KEY (`serviceId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblVaccine` (
    `vaccine_id` BIGINT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(200) NOT NULL,
    `manufacturer` VARCHAR(150) NULL,
    `country_of_origin` VARCHAR(100) NULL,
    `dose_count` INTEGER NULL,
    `description` TEXT NULL,
    `isActive` TINYINT NOT NULL DEFAULT 1,

    UNIQUE INDEX `tblVaccine_name_key`(`name`),
    PRIMARY KEY (`vaccine_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblServiceVaccine` (
    `serviceId` BIGINT NOT NULL,
    `vaccine_id` BIGINT NOT NULL,
    `quantity` INTEGER NOT NULL DEFAULT 1,

    PRIMARY KEY (`serviceId`, `vaccine_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblSlots` (
    `slotId` BIGINT NOT NULL AUTO_INCREMENT,
    `facilityId` BIGINT NOT NULL,
    `doctorId` BIGINT NOT NULL,
    `slotDate` DATE NOT NULL,
    `startTime` TIME NOT NULL,
    `endTime` TIME NOT NULL,
    `duration_minutes` INTEGER NOT NULL DEFAULT 30,
    `available_count` INTEGER NOT NULL DEFAULT 10,
    `status` ENUM('AVAILABLE', 'FULL', 'CANCELLED', 'INACTIVE') NOT NULL DEFAULT 'AVAILABLE',
    `isActive` TINYINT NOT NULL DEFAULT 1,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    PRIMARY KEY (`slotId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblAppointment` (
    `appointmentId` BIGINT NOT NULL AUTO_INCREMENT,
    `appointmentCode` VARCHAR(30) NOT NULL,
    `userId` BIGINT NOT NULL,
    `patientId` BIGINT NOT NULL,
    `facilityId` BIGINT NOT NULL,
    `doctorId` BIGINT NULL,
    `slotId` BIGINT NOT NULL,
    `serviceId` BIGINT NULL,
    `pre_visit_form_id` BIGINT NULL,
    `appointment_type` ENUM('consultation', 'vaccination') NOT NULL,
    `appointmentDate` DATE NOT NULL,
    `appointmentTime` TIME NOT NULL,
    `status` ENUM('pending', 'confirmed', 'completed', 'cancelled', 'no_show') NOT NULL DEFAULT 'pending',
    `symptoms_note` TEXT NULL,
    `note` TEXT NULL,
    `totalAmount` DECIMAL(12, 2) NOT NULL,
    `cancellation_reason` VARCHAR(255) NULL,
    `cancellation_requested_by` BIGINT NULL,
    `cancellation_requested_at` DATETIME(3) NULL,
    `cancellation_approved_by` BIGINT NULL,
    `cancellation_approved_at` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblAppointment_appointmentCode_key`(`appointmentCode`),
    UNIQUE INDEX `tblAppointment_slotId_key`(`slotId`),
    UNIQUE INDEX `tblAppointment_pre_visit_form_id_key`(`pre_visit_form_id`),
    PRIMARY KEY (`appointmentId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblAppointmentStatusLogs` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `appointmentId` BIGINT NOT NULL,
    `changed_by` BIGINT NOT NULL,
    `changed_by_role` ENUM('patient', 'doctor', 'admin', 'receptionist') NOT NULL,
    `from_status` VARCHAR(191) NULL,
    `to_status` VARCHAR(191) NOT NULL,
    `reason` VARCHAR(255) NULL,
    `metadata` JSON NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblPayment` (
    `payment_id` BIGINT NOT NULL AUTO_INCREMENT,
    `appointmentId` BIGINT NOT NULL,
    `payment_method` ENUM('cash', 'vnpay', 'momo', 'zalopay', 'credit_card', 'bank_transfer') NOT NULL,
    `amount` DECIMAL(12, 2) NOT NULL,
    `transaction_code` VARCHAR(100) NULL,
    `status` ENUM('pending', 'success', 'failed', 'refunded', 'refunding') NOT NULL DEFAULT 'pending',
    `paid_at` DATETIME(3) NULL,
    `refund_amount` DECIMAL(12, 2) NULL DEFAULT 0,
    `refund_reason` VARCHAR(255) NULL,
    `refunded_at` DATETIME(3) NULL,
    `retry_count` INTEGER NOT NULL DEFAULT 0,
    `last_retry_at` DATETIME(3) NULL,
    `error_message` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblPayment_transaction_code_key`(`transaction_code`),
    PRIMARY KEY (`payment_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblNotifications` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `userId` BIGINT NOT NULL,
    `appointmentId` BIGINT NULL,
    `type` ENUM('appointment_reminder', 'appointment_confirmed', 'appointment_cancelled', 'appointment_completed', 'system', 'promotional') NOT NULL,
    `channel` ENUM('sms', 'email', 'push', 'in_app') NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `message` TEXT NOT NULL,
    `delivery_status` ENUM('pending', 'sent', 'delivered', 'failed') NOT NULL DEFAULT 'pending',
    `is_read` TINYINT NOT NULL DEFAULT 0,
    `read_at` DATETIME(3) NULL,
    `sent_at` DATETIME(3) NULL,
    `retry_count` INTEGER NOT NULL DEFAULT 0,
    `last_retry_at` DATETIME(3) NULL,
    `error_message` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblMedicalRecord` (
    `record_id` BIGINT NOT NULL AUTO_INCREMENT,
    `appointmentId` BIGINT NOT NULL,
    `patientId` BIGINT NOT NULL,
    `doctorId` BIGINT NOT NULL,
    `pre_visit_form_id` BIGINT NULL,
    `symptoms` TEXT NULL,
    `diagnosis` TEXT NOT NULL,
    `icd10_codes` TEXT NULL,
    `vital_signs` JSON NULL,
    `treatment_plan` TEXT NULL,
    `prescription` JSON NULL,
    `follow_up_date` DATE NULL,
    `attachments` JSON NULL,
    `is_locked` TINYINT NOT NULL DEFAULT 0,
    `locked_at` DATETIME(3) NULL,
    `locked_by_userId` BIGINT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblMedicalRecord_appointmentId_key`(`appointmentId`),
    PRIMARY KEY (`record_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblDoctorReview` (
    `review_id` BIGINT NOT NULL AUTO_INCREMENT,
    `doctorId` BIGINT NOT NULL,
    `userId` BIGINT NOT NULL,
    `appointmentId` BIGINT NULL,
    `rating` TINYINT NOT NULL,
    `comment` TEXT NULL,
    `is_visible` TINYINT NOT NULL DEFAULT 1,
    `admin_reply` TEXT NULL,
    `admin_reply_at` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblDoctorReview_appointmentId_key`(`appointmentId`),
    PRIMARY KEY (`review_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblPreVisitForms` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `appointmentId` BIGINT NOT NULL,
    `form_version` VARCHAR(10) NOT NULL DEFAULT '1.0',
    `chief_complaint` TEXT NOT NULL,
    `symptoms` TEXT NULL,
    `medical_history` TEXT NULL,
    `current_medications` TEXT NULL,
    `allergies` TEXT NULL,
    `extra_notes` TEXT NULL,
    `status` ENUM('DRAFT', 'SUBMITTED', 'REVIEWED') NOT NULL DEFAULT 'DRAFT',
    `submitted_by_userId` BIGINT NULL,
    `submitted_at` DATETIME(3) NULL,
    `reviewed_by_userId` BIGINT NULL,
    `reviewed_at` DATETIME(3) NULL,
    `review_notes` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblPreVisitForms_appointmentId_key`(`appointmentId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblVaccinationRegistration` (
    `vaccination_registration_id` BIGINT NOT NULL AUTO_INCREMENT,
    `appointmentId` BIGINT NOT NULL,
    `contact_phone` VARCHAR(20) NOT NULL,
    `contact_email` VARCHAR(150) NULL,
    `screening_status` ENUM('pending', 'in_progress', 'eligible', 'ineligible', 'need_review', 'approved') NOT NULL DEFAULT 'pending',
    `allergy_history` TEXT NULL,
    `underlying_disease` TEXT NULL,
    `current_medications` TEXT NULL,
    `previous_vaccination_history` TEXT NULL,
    `screening_result` TEXT NULL,
    `screened_by_userId` BIGINT NULL,
    `screened_at` DATETIME(3) NULL,
    `is_eligible_approved` TINYINT NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblVaccinationRegistration_appointmentId_key`(`appointmentId`),
    PRIMARY KEY (`vaccination_registration_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblAiTriageSessions` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `userId` BIGINT NOT NULL,
    `appointmentId` BIGINT NULL,
    `status` ENUM('IN_PROGRESS', 'COMPLETED', 'ABANDONED') NOT NULL DEFAULT 'IN_PROGRESS',
    `symptoms_input` TEXT NULL,
    `urgency_level` ENUM('NORMAL', 'SOON', 'URGENT') NULL,
    `recommended_specialties` JSON NULL,
    `pre_visit_summary` JSON NULL,
    `total_messages` INTEGER NOT NULL DEFAULT 0,
    `is_completed` TINYINT NOT NULL DEFAULT 0,
    `abandoned_at` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblAiTriageSessions_appointmentId_key`(`appointmentId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblAiTriageMessages` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `session_id` BIGINT NOT NULL,
    `sender` ENUM('PATIENT', 'AI') NOT NULL,
    `content` TEXT NOT NULL,
    `metadata` JSON NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `tblRefreshTokens` ADD CONSTRAINT `tblRefreshTokens_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `tblUser`(`userId`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblPasswordResetTokens` ADD CONSTRAINT `tblPasswordResetTokens_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `tblUser`(`userId`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblPatientProfile` ADD CONSTRAINT `tblPatientProfile_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `tblUser`(`userId`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblDoctor` ADD CONSTRAINT `tblDoctor_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `tblUser`(`userId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblDoctor` ADD CONSTRAINT `tblDoctor_specialty_id_fkey` FOREIGN KEY (`specialty_id`) REFERENCES `tblSpecialty`(`specialty_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblDoctor` ADD CONSTRAINT `tblDoctor_facilityId_fkey` FOREIGN KEY (`facilityId`) REFERENCES `tblFacility`(`facilityId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblService` ADD CONSTRAINT `tblService_facilityId_fkey` FOREIGN KEY (`facilityId`) REFERENCES `tblFacility`(`facilityId`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblServiceVaccine` ADD CONSTRAINT `tblServiceVaccine_serviceId_fkey` FOREIGN KEY (`serviceId`) REFERENCES `tblService`(`serviceId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblServiceVaccine` ADD CONSTRAINT `tblServiceVaccine_vaccine_id_fkey` FOREIGN KEY (`vaccine_id`) REFERENCES `tblVaccine`(`vaccine_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblSlots` ADD CONSTRAINT `tblSlots_facilityId_fkey` FOREIGN KEY (`facilityId`) REFERENCES `tblFacility`(`facilityId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblSlots` ADD CONSTRAINT `tblSlots_doctorId_fkey` FOREIGN KEY (`doctorId`) REFERENCES `tblDoctor`(`doctorId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointment` ADD CONSTRAINT `tblAppointment_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `tblUser`(`userId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointment` ADD CONSTRAINT `tblAppointment_patientId_fkey` FOREIGN KEY (`patientId`) REFERENCES `tblPatientProfile`(`patientId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointment` ADD CONSTRAINT `tblAppointment_facilityId_fkey` FOREIGN KEY (`facilityId`) REFERENCES `tblFacility`(`facilityId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointment` ADD CONSTRAINT `tblAppointment_doctorId_fkey` FOREIGN KEY (`doctorId`) REFERENCES `tblDoctor`(`doctorId`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointment` ADD CONSTRAINT `tblAppointment_slotId_fkey` FOREIGN KEY (`slotId`) REFERENCES `tblSlots`(`slotId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointment` ADD CONSTRAINT `tblAppointment_serviceId_fkey` FOREIGN KEY (`serviceId`) REFERENCES `tblService`(`serviceId`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointmentStatusLogs` ADD CONSTRAINT `tblAppointmentStatusLogs_appointmentId_fkey` FOREIGN KEY (`appointmentId`) REFERENCES `tblAppointment`(`appointmentId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointmentStatusLogs` ADD CONSTRAINT `tblAppointmentStatusLogs_changed_by_fkey` FOREIGN KEY (`changed_by`) REFERENCES `tblUser`(`userId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblPayment` ADD CONSTRAINT `tblPayment_appointmentId_fkey` FOREIGN KEY (`appointmentId`) REFERENCES `tblAppointment`(`appointmentId`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblNotifications` ADD CONSTRAINT `tblNotifications_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `tblUser`(`userId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblNotifications` ADD CONSTRAINT `tblNotifications_appointmentId_fkey` FOREIGN KEY (`appointmentId`) REFERENCES `tblAppointment`(`appointmentId`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblMedicalRecord` ADD CONSTRAINT `tblMedicalRecord_appointmentId_fkey` FOREIGN KEY (`appointmentId`) REFERENCES `tblAppointment`(`appointmentId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblMedicalRecord` ADD CONSTRAINT `tblMedicalRecord_patientId_fkey` FOREIGN KEY (`patientId`) REFERENCES `tblPatientProfile`(`patientId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblMedicalRecord` ADD CONSTRAINT `tblMedicalRecord_doctorId_fkey` FOREIGN KEY (`doctorId`) REFERENCES `tblDoctor`(`doctorId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblDoctorReview` ADD CONSTRAINT `tblDoctorReview_doctorId_fkey` FOREIGN KEY (`doctorId`) REFERENCES `tblDoctor`(`doctorId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblDoctorReview` ADD CONSTRAINT `tblDoctorReview_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `tblUser`(`userId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblDoctorReview` ADD CONSTRAINT `tblDoctorReview_appointmentId_fkey` FOREIGN KEY (`appointmentId`) REFERENCES `tblAppointment`(`appointmentId`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblPreVisitForms` ADD CONSTRAINT `tblPreVisitForms_appointmentId_fkey` FOREIGN KEY (`appointmentId`) REFERENCES `tblAppointment`(`appointmentId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblPreVisitForms` ADD CONSTRAINT `tblPreVisitForms_submitted_by_userId_fkey` FOREIGN KEY (`submitted_by_userId`) REFERENCES `tblUser`(`userId`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblPreVisitForms` ADD CONSTRAINT `tblPreVisitForms_reviewed_by_userId_fkey` FOREIGN KEY (`reviewed_by_userId`) REFERENCES `tblUser`(`userId`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblVaccinationRegistration` ADD CONSTRAINT `tblVaccinationRegistration_appointmentId_fkey` FOREIGN KEY (`appointmentId`) REFERENCES `tblAppointment`(`appointmentId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAiTriageSessions` ADD CONSTRAINT `tblAiTriageSessions_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `tblUser`(`userId`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAiTriageSessions` ADD CONSTRAINT `tblAiTriageSessions_appointmentId_fkey` FOREIGN KEY (`appointmentId`) REFERENCES `tblAppointment`(`appointmentId`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAiTriageMessages` ADD CONSTRAINT `tblAiTriageMessages_session_id_fkey` FOREIGN KEY (`session_id`) REFERENCES `tblAiTriageSessions`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
