-- CreateTable
CREATE TABLE `tblSlotCapacityLogs` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `slot_id` BIGINT NOT NULL,
    `updated_by` BIGINT NOT NULL,
    `old_available_count` INTEGER NOT NULL,
    `new_available_count` INTEGER NOT NULL,
    `reason` VARCHAR(255) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `tblSlotCapacityLogs_slot_id_created_at_idx`(`slot_id`, `created_at`),
    INDEX `tblSlotCapacityLogs_updated_by_created_at_idx`(`updated_by`, `created_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `tblSlotCapacityLogs` ADD CONSTRAINT `tblSlotCapacityLogs_slot_id_fkey` FOREIGN KEY (`slot_id`) REFERENCES `tblSlots`(`slot_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tblSlotCapacityLogs` ADD CONSTRAINT `tblSlotCapacityLogs_updated_by_fkey` FOREIGN KEY (`updated_by`) REFERENCES `tblUser`(`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;
