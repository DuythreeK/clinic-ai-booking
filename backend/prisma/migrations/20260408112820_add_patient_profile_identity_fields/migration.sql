-- CreateTable
CREATE TABLE `tblUser` (
    `user_id` BIGINT NOT NULL AUTO_INCREMENT,
    `role` ENUM('admin', 'doctor', 'patient') NOT NULL,
    `full_name` VARCHAR(150) NOT NULL,
    `email` VARCHAR(150) NOT NULL,
    `phone` VARCHAR(20) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `avatar_url` VARCHAR(255) NULL,
    `status` ENUM('active', 'inactive', 'blocked') NOT NULL DEFAULT 'active',
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblUser_email_key`(`email`),
    UNIQUE INDEX `tblUser_phone_key`(`phone`),
    PRIMARY KEY (`user_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblRefreshTokens` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `token` VARCHAR(512) NOT NULL,
    `expires_at` DATETIME(3) NOT NULL,
    `is_revoked` TINYINT NOT NULL DEFAULT 0,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `tblRefreshTokens_token_key`(`token`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblPasswordResetTokens` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `token` VARCHAR(512) NOT NULL,
    `status` ENUM('PENDING', 'USED', 'EXPIRED') NOT NULL DEFAULT 'PENDING',
    `expires_at` DATETIME(3) NOT NULL,
    `used_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `tblPasswordResetTokens_token_key`(`token`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblPatientProfile` (
    `patient_id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `full_name` VARCHAR(150) NOT NULL,
    `phone_number` VARCHAR(20) NULL,
    `citizen_id` VARCHAR(30) NULL,
    `insurance_number` VARCHAR(50) NULL,
    `email` VARCHAR(150) NULL,
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
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblPatientProfile_phone_number_key`(`phone_number`),
    UNIQUE INDEX `tblPatientProfile_citizen_id_key`(`citizen_id`),
    PRIMARY KEY (`patient_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblSpecialty` (
    `specialty_id` BIGINT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(150) NOT NULL,
    `description` TEXT NULL,
    `is_active` TINYINT NOT NULL DEFAULT 1,

    UNIQUE INDEX `tblSpecialty_name_key`(`name`),
    PRIMARY KEY (`specialty_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblFacility` (
    `facility_id` BIGINT NOT NULL AUTO_INCREMENT,
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
    `is_active` TINYINT NOT NULL DEFAULT 1,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    PRIMARY KEY (`facility_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblDoctor` (
    `doctor_id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `full_name` VARCHAR(150) NOT NULL,
    `specialty_id` BIGINT NOT NULL,
    `facility_id` BIGINT NOT NULL,
    `title` VARCHAR(100) NULL,
    `bio` TEXT NULL,
    `experience_years` INTEGER NULL,
    `avatar_url` VARCHAR(255) NULL,
    `consultation_fee` DECIMAL(12, 2) NULL,
    `is_active` TINYINT NOT NULL DEFAULT 1,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblDoctor_user_id_key`(`user_id`),
    PRIMARY KEY (`doctor_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblService` (
    `service_id` BIGINT NOT NULL AUTO_INCREMENT,
    `facility_id` BIGINT NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `description` TEXT NULL,
    `price` DECIMAL(12, 2) NOT NULL,
    `duration_minutes` INTEGER NULL,
    `is_active` TINYINT NOT NULL DEFAULT 1,

    PRIMARY KEY (`service_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblVaccine` (
    `vaccine_id` BIGINT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(200) NOT NULL,
    `manufacturer` VARCHAR(150) NULL,
    `country_of_origin` VARCHAR(100) NULL,
    `dose_count` INTEGER NULL,
    `description` TEXT NULL,
    `is_active` TINYINT NOT NULL DEFAULT 1,

    UNIQUE INDEX `tblVaccine_name_key`(`name`),
    PRIMARY KEY (`vaccine_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblServiceVaccine` (
    `service_id` BIGINT NOT NULL,
    `vaccine_id` BIGINT NOT NULL,
    `quantity` INTEGER NOT NULL DEFAULT 1,

    PRIMARY KEY (`service_id`, `vaccine_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblSlots` (
    `slot_id` BIGINT NOT NULL AUTO_INCREMENT,
    `facility_id` BIGINT NOT NULL,
    `doctor_id` BIGINT NOT NULL,
    `slot_date` DATE NOT NULL,
    `start_time` TIME NOT NULL,
    `end_time` TIME NOT NULL,
    `duration_minutes` INTEGER NOT NULL DEFAULT 30,
    `available_count` INTEGER NOT NULL DEFAULT 10,
    `status` ENUM('AVAILABLE', 'FULL', 'CANCELLED', 'INACTIVE') NOT NULL DEFAULT 'AVAILABLE',
    `is_active` TINYINT NOT NULL DEFAULT 1,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    PRIMARY KEY (`slot_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblAppointment` (
    `appointment_id` BIGINT NOT NULL AUTO_INCREMENT,
    `appointment_code` VARCHAR(30) NOT NULL,
    `user_id` BIGINT NOT NULL,
    `patient_id` BIGINT NOT NULL,
    `facility_id` BIGINT NOT NULL,
    `doctor_id` BIGINT NULL,
    `slot_id` BIGINT NOT NULL,
    `service_id` BIGINT NULL,
    `pre_visit_form_id` BIGINT NULL,
    `appointment_type` ENUM('consultation', 'vaccination') NOT NULL,
    `appointment_date` DATE NOT NULL,
    `appointment_time` TIME NOT NULL,
    `status` ENUM('pending', 'confirmed', 'completed', 'cancelled', 'no_show') NOT NULL DEFAULT 'pending',
    `symptoms_note` TEXT NULL,
    `note` TEXT NULL,
    `total_amount` DECIMAL(12, 2) NOT NULL,
    `cancellation_reason` VARCHAR(255) NULL,
    `cancellation_requested_by` BIGINT NULL,
    `cancellation_requested_at` DATETIME(3) NULL,
    `cancellation_approved_by` BIGINT NULL,
    `cancellation_approved_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblAppointment_appointment_code_key`(`appointment_code`),
    UNIQUE INDEX `tblAppointment_slot_id_key`(`slot_id`),
    UNIQUE INDEX `tblAppointment_pre_visit_form_id_key`(`pre_visit_form_id`),
    PRIMARY KEY (`appointment_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblAppointmentStatusLogs` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `appointment_id` BIGINT NOT NULL,
    `changed_by` BIGINT NOT NULL,
    `changed_by_role` ENUM('patient', 'doctor', 'admin', 'receptionist') NOT NULL,
    `from_status` VARCHAR(191) NULL,
    `to_status` VARCHAR(191) NOT NULL,
    `reason` VARCHAR(255) NULL,
    `metadata` JSON NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblPayment` (
    `payment_id` BIGINT NOT NULL AUTO_INCREMENT,
    `appointment_id` BIGINT NOT NULL,
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
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblPayment_transaction_code_key`(`transaction_code`),
    PRIMARY KEY (`payment_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblNotifications` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `appointment_id` BIGINT NULL,
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
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblMedicalRecord` (
    `record_id` BIGINT NOT NULL AUTO_INCREMENT,
    `appointment_id` BIGINT NOT NULL,
    `patient_id` BIGINT NOT NULL,
    `doctor_id` BIGINT NOT NULL,
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
    `locked_by_user_id` BIGINT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblMedicalRecord_appointment_id_key`(`appointment_id`),
    PRIMARY KEY (`record_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblDoctorReview` (
    `review_id` BIGINT NOT NULL AUTO_INCREMENT,
    `doctor_id` BIGINT NOT NULL,
    `user_id` BIGINT NOT NULL,
    `appointment_id` BIGINT NULL,
    `rating` TINYINT NOT NULL,
    `comment` TEXT NULL,
    `is_visible` TINYINT NOT NULL DEFAULT 1,
    `admin_reply` TEXT NULL,
    `admin_reply_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblDoctorReview_appointment_id_key`(`appointment_id`),
    PRIMARY KEY (`review_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblPreVisitForms` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `appointment_id` BIGINT NOT NULL,
    `form_version` VARCHAR(10) NOT NULL DEFAULT '1.0',
    `chief_complaint` TEXT NOT NULL,
    `symptoms` TEXT NULL,
    `medical_history` TEXT NULL,
    `current_medications` TEXT NULL,
    `allergies` TEXT NULL,
    `extra_notes` TEXT NULL,
    `status` ENUM('DRAFT', 'SUBMITTED', 'REVIEWED') NOT NULL DEFAULT 'DRAFT',
    `submitted_by_user_id` BIGINT NULL,
    `submitted_at` DATETIME(3) NULL,
    `reviewed_by_user_id` BIGINT NULL,
    `reviewed_at` DATETIME(3) NULL,
    `review_notes` TEXT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblPreVisitForms_appointment_id_key`(`appointment_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblVaccinationRegistration` (
    `vaccination_registration_id` BIGINT NOT NULL AUTO_INCREMENT,
    `appointment_id` BIGINT NOT NULL,
    `contact_phone` VARCHAR(20) NOT NULL,
    `contact_email` VARCHAR(150) NULL,
    `screening_status` ENUM('pending', 'in_progress', 'eligible', 'ineligible', 'need_review', 'approved') NOT NULL DEFAULT 'pending',
    `allergy_history` TEXT NULL,
    `underlying_disease` TEXT NULL,
    `current_medications` TEXT NULL,
    `previous_vaccination_history` TEXT NULL,
    `screening_result` TEXT NULL,
    `screened_by_user_id` BIGINT NULL,
    `screened_at` DATETIME(3) NULL,
    `is_eligible_approved` TINYINT NOT NULL DEFAULT 0,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblVaccinationRegistration_appointment_id_key`(`appointment_id`),
    PRIMARY KEY (`vaccination_registration_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblAiTriageSessions` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `appointment_id` BIGINT NULL,
    `status` ENUM('IN_PROGRESS', 'COMPLETED', 'ABANDONED') NOT NULL DEFAULT 'IN_PROGRESS',
    `symptoms_input` TEXT NULL,
    `urgency_level` ENUM('NORMAL', 'SOON', 'URGENT') NULL,
    `recommended_specialties` JSON NULL,
    `pre_visit_summary` JSON NULL,
    `total_messages` INTEGER NOT NULL DEFAULT 0,
    `is_completed` TINYINT NOT NULL DEFAULT 0,
    `abandoned_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblAiTriageSessions_appointment_id_key`(`appointment_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblAiTriageMessages` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `session_id` BIGINT NOT NULL,
    `sender` ENUM('PATIENT', 'AI') NOT NULL,
    `content` TEXT NOT NULL,
    `metadata` JSON NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `tblRefreshTokens` ADD CONSTRAINT `tblRefreshTokens_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `tblUser`(`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblPasswordResetTokens` ADD CONSTRAINT `tblPasswordResetTokens_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `tblUser`(`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblPatientProfile` ADD CONSTRAINT `tblPatientProfile_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `tblUser`(`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblDoctor` ADD CONSTRAINT `tblDoctor_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `tblUser`(`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblDoctor` ADD CONSTRAINT `tblDoctor_specialty_id_fkey` FOREIGN KEY (`specialty_id`) REFERENCES `tblSpecialty`(`specialty_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblDoctor` ADD CONSTRAINT `tblDoctor_facility_id_fkey` FOREIGN KEY (`facility_id`) REFERENCES `tblFacility`(`facility_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblService` ADD CONSTRAINT `tblService_facility_id_fkey` FOREIGN KEY (`facility_id`) REFERENCES `tblFacility`(`facility_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblServiceVaccine` ADD CONSTRAINT `tblServiceVaccine_service_id_fkey` FOREIGN KEY (`service_id`) REFERENCES `tblService`(`service_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblServiceVaccine` ADD CONSTRAINT `tblServiceVaccine_vaccine_id_fkey` FOREIGN KEY (`vaccine_id`) REFERENCES `tblVaccine`(`vaccine_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblSlots` ADD CONSTRAINT `tblSlots_facility_id_fkey` FOREIGN KEY (`facility_id`) REFERENCES `tblFacility`(`facility_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblSlots` ADD CONSTRAINT `tblSlots_doctor_id_fkey` FOREIGN KEY (`doctor_id`) REFERENCES `tblDoctor`(`doctor_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointment` ADD CONSTRAINT `tblAppointment_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `tblUser`(`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointment` ADD CONSTRAINT `tblAppointment_patient_id_fkey` FOREIGN KEY (`patient_id`) REFERENCES `tblPatientProfile`(`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointment` ADD CONSTRAINT `tblAppointment_facility_id_fkey` FOREIGN KEY (`facility_id`) REFERENCES `tblFacility`(`facility_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointment` ADD CONSTRAINT `tblAppointment_doctor_id_fkey` FOREIGN KEY (`doctor_id`) REFERENCES `tblDoctor`(`doctor_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointment` ADD CONSTRAINT `tblAppointment_slot_id_fkey` FOREIGN KEY (`slot_id`) REFERENCES `tblSlots`(`slot_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointment` ADD CONSTRAINT `tblAppointment_service_id_fkey` FOREIGN KEY (`service_id`) REFERENCES `tblService`(`service_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointmentStatusLogs` ADD CONSTRAINT `tblAppointmentStatusLogs_appointment_id_fkey` FOREIGN KEY (`appointment_id`) REFERENCES `tblAppointment`(`appointment_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAppointmentStatusLogs` ADD CONSTRAINT `tblAppointmentStatusLogs_changed_by_fkey` FOREIGN KEY (`changed_by`) REFERENCES `tblUser`(`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblPayment` ADD CONSTRAINT `tblPayment_appointment_id_fkey` FOREIGN KEY (`appointment_id`) REFERENCES `tblAppointment`(`appointment_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblNotifications` ADD CONSTRAINT `tblNotifications_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `tblUser`(`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblNotifications` ADD CONSTRAINT `tblNotifications_appointment_id_fkey` FOREIGN KEY (`appointment_id`) REFERENCES `tblAppointment`(`appointment_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblMedicalRecord` ADD CONSTRAINT `tblMedicalRecord_appointment_id_fkey` FOREIGN KEY (`appointment_id`) REFERENCES `tblAppointment`(`appointment_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblMedicalRecord` ADD CONSTRAINT `tblMedicalRecord_patient_id_fkey` FOREIGN KEY (`patient_id`) REFERENCES `tblPatientProfile`(`patient_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblMedicalRecord` ADD CONSTRAINT `tblMedicalRecord_doctor_id_fkey` FOREIGN KEY (`doctor_id`) REFERENCES `tblDoctor`(`doctor_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblDoctorReview` ADD CONSTRAINT `tblDoctorReview_doctor_id_fkey` FOREIGN KEY (`doctor_id`) REFERENCES `tblDoctor`(`doctor_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblDoctorReview` ADD CONSTRAINT `tblDoctorReview_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `tblUser`(`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblDoctorReview` ADD CONSTRAINT `tblDoctorReview_appointment_id_fkey` FOREIGN KEY (`appointment_id`) REFERENCES `tblAppointment`(`appointment_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblPreVisitForms` ADD CONSTRAINT `tblPreVisitForms_appointment_id_fkey` FOREIGN KEY (`appointment_id`) REFERENCES `tblAppointment`(`appointment_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblPreVisitForms` ADD CONSTRAINT `tblPreVisitForms_submitted_by_user_id_fkey` FOREIGN KEY (`submitted_by_user_id`) REFERENCES `tblUser`(`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblPreVisitForms` ADD CONSTRAINT `tblPreVisitForms_reviewed_by_user_id_fkey` FOREIGN KEY (`reviewed_by_user_id`) REFERENCES `tblUser`(`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblVaccinationRegistration` ADD CONSTRAINT `tblVaccinationRegistration_appointment_id_fkey` FOREIGN KEY (`appointment_id`) REFERENCES `tblAppointment`(`appointment_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAiTriageSessions` ADD CONSTRAINT `tblAiTriageSessions_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `tblUser`(`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAiTriageSessions` ADD CONSTRAINT `tblAiTriageSessions_appointment_id_fkey` FOREIGN KEY (`appointment_id`) REFERENCES `tblAppointment`(`appointment_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblAiTriageMessages` ADD CONSTRAINT `tblAiTriageMessages_session_id_fkey` FOREIGN KEY (`session_id`) REFERENCES `tblAiTriageSessions`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
