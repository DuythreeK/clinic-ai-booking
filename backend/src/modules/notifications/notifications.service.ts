import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '@/prisma/prisma.service';
import { SaveFcmTokenDto } from './dto/notification.dto';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(private prisma: PrismaService) {}

  async saveFcmToken(userId: string, dto: SaveFcmTokenDto) {
    // Check if token already exists
    const existing = await this.prisma.fcmToken.findUnique({
      where: { token: dto.token },
    });

    if (existing && existing.userId !== userId) {
      // Token moved to new user, delete old
      await this.prisma.fcmToken.delete({
        where: { id: existing.id },
      });
    }

    return this.prisma.fcmToken.upsert({
      where: { token: dto.token },
      update: { updatedAt: new Date() },
      create: {
        token: dto.token,
        userId,
      },
    });
  }

  /**
   * Cron job: Send appointment reminders 1 hour before appointment
   * Placeholder implementation - replace with actual Firebase Cloud Messaging
   */
  @Cron(CronExpression.EVERY_15_MINUTES)
  async sendAppointmentReminders() {
    this.logger.log('🔔 Checking for upcoming appointments...');

    const now = new Date();
    const oneHourLater = new Date(now.getTime() + 60 * 60 * 1000);

    try {
      const upcomingAppointments = await this.prisma.appointment.findMany({
        where: {
          slot: {
            startAt: {
              gte: now,
              lte: oneHourLater,
            },
          },
          status: {
            in: ['PENDING', 'CONFIRMED'],
          },
        },
        include: {
          patient: { include: { user: true } },
          slot: true,
          doctor: { include: { user: true } },
        },
      });

      for (const appointment of upcomingAppointments) {
        this.logger.log(
          `📢 Would send reminder to patient: ${appointment.patient.user.email} for appointment at ${appointment.slot.startAt}`,
        );

        // TODO: Implement actual Firebase Cloud Messaging
        // await this.sendPushNotification({
        //   userId: appointment.patientId,
        //   title: 'Appointment Reminder',
        //   body: `Your appointment with Dr. ${appointment.doctor.user.firstName} is in 1 hour`,
        // });

        this.logger.log(`✅ Reminder sent for appointment ${appointment.id}`);
      }

      if (upcomingAppointments.length === 0) {
        this.logger.log('No upcoming appointments to remind');
      }
    } catch (error) {
      this.logger.error('Error sending reminders:', error);
    }
  }

  /**
   * Placeholder for Firebase Cloud Messaging integration
   */
  private async sendPushNotification(payload: {
    userId: string;
    title: string;
    body: string;
  }) {
    // TODO: Implement FCM sending using Firebase Admin SDK
    // const fcmTokens = await this.prisma.fcmToken.findMany({
    //   where: { userId: payload.userId },
    // });
    // 
    // for (const tokenRecord of fcmTokens) {
    //   await admin.messaging().send({
    //     token: tokenRecord.token,
    //     notification: {
    //       title: payload.title,
    //       body: payload.body,
    //     },
    //   });
    // }
  }
}
