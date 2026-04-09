-- DropForeignKey
ALTER TABLE `tblappointment` DROP FOREIGN KEY `tblAppointment_slot_id_fkey`;

-- DropIndex
DROP INDEX `tblAppointment_slot_id_key` ON `tblappointment`;

-- AlterTable
ALTER TABLE `tblappointment` MODIFY `status` ENUM('pending', 'confirmed', 'checked_in', 'in_progress', 'completed', 'cancelled', 'no_show') NOT NULL DEFAULT 'pending';

-- CreateTable
CREATE TABLE `tblAdminNotificationSettings` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `push_enabled` TINYINT NOT NULL DEFAULT 1,
    `sound_enabled` TINYINT NOT NULL DEFAULT 1,
    `appointment_reminder` TINYINT NOT NULL DEFAULT 0,
    `status_updates` TINYINT NOT NULL DEFAULT 1,
    `reminder_lead_minutes` INTEGER NOT NULL DEFAULT 30,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblAdminNotificationSettings_user_id_key`(`user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblRoom` (
    `room_id` BIGINT NOT NULL AUTO_INCREMENT,
    `specialty_id` BIGINT NULL,
    `name` VARCHAR(100) NOT NULL,
    `code` VARCHAR(20) NOT NULL,
    `floor` SMALLINT NULL,
    `description` TEXT NULL,
    `is_active` TINYINT NOT NULL DEFAULT 1,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `tblRoom_code_key`(`code`),
    PRIMARY KEY (`room_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tblSchedule` (
    `schedule_id` BIGINT NOT NULL AUTO_INCREMENT,
    `doctor_id` BIGINT NOT NULL,
    `room_id` BIGINT NULL,
    `work_date` DATE NOT NULL,
    `start_time` TIME NOT NULL,
    `end_time` TIME NOT NULL,
    `slot_duration` INTEGER NOT NULL DEFAULT 30,
    `max_slots` INTEGER NOT NULL,
    `is_available` TINYINT NOT NULL DEFAULT 1,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    PRIMARY KEY (`schedule_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateIndex
CREATE INDEX `tblAppointment_slot_id_idx` ON `tblappointment`(`slot_id`);

-- AddForeignKey
ALTER TABLE `tblAdminNotificationSettings` ADD CONSTRAINT `tblAdminNotificationSettings_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `tblUser`(`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblRoom` ADD CONSTRAINT `tblRoom_specialty_id_fkey` FOREIGN KEY (`specialty_id`) REFERENCES `tblSpecialty`(`specialty_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblSchedule` ADD CONSTRAINT `tblSchedule_doctor_id_fkey` FOREIGN KEY (`doctor_id`) REFERENCES `tblDoctor`(`doctor_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblSchedule` ADD CONSTRAINT `tblSchedule_room_id_fkey` FOREIGN KEY (`room_id`) REFERENCES `tblRoom`(`room_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblappointment` ADD CONSTRAINT `tblAppointment_slot_id_fkey` FOREIGN KEY (`slot_id`) REFERENCES `tblSlots`(`slot_id`) ON DELETE RESTRICT ON UPDATE CASCADE;
