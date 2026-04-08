import { Injectable } from '@nestjs/common';
import { AppointmentStatus } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { DashboardOverviewQueryDto } from './dto/stats.dto';

type DashboardActivityAction =
  | 'created'
  | 'confirmed'
  | 'cancelled'
  | 'completed';

@Injectable()
export class StatsService {
  constructor(private readonly prisma: PrismaService) {}

  async getOverview(query: DashboardOverviewQueryDto) {
    const { from, to } = this.resolveRange(query);
    const { start, end, labels } = this.getWeekRange();
    const dateFilter =
      query.from || query.to
        ? {
            appointment_date: {
              gte: from,
              lte: to,
            },
          }
        : undefined;

    const [
      totalAppointments,
      pendingAppointments,
      activeDoctors,
      totalPatients,
      weeklyAppointments,
      recentAppointments,
    ] = await Promise.all([
      this.prisma.appointment.count({
        where: dateFilter,
      }),
      this.prisma.appointment.count({
        where: {
          status: AppointmentStatus.pending,
          ...(dateFilter ?? {}),
        },
      }),
      this.prisma.doctor.count({
        where: { is_active: 1 },
      }),
      this.prisma.patientProfile.count(),
      this.prisma.appointment.findMany({
        where: {
          appointment_date: {
            gte: start,
            lte: end,
          },
        },
        select: {
          appointment_date: true,
        },
      }),
      this.prisma.appointment.findMany({
        take: 5,
        orderBy: {
          updated_at: 'desc',
        },
        include: {
          patient: true, // Relation name in Appointment model is "patient" but points to PatientProfile
        },
      }),
    ]);

    const weeklyCounts = new Map<string, number>();
    for (const label of labels) {
      weeklyCounts.set(label.label, 0);
    }

    for (const item of weeklyAppointments) {
      const label = this.toWeekLabel(item.appointment_date);
      weeklyCounts.set(label, (weeklyCounts.get(label) ?? 0) + 1);
    }

    return {
      metrics: {
        totalAppointments,
        pendingAppointments,
        activeDoctors,
        totalPatients,
      },
      weeklyAppointments: labels
        .map((entry) => ({
          label: entry.label,
          date: entry.date.toISOString(),
          count: weeklyCounts.get(entry.label) ?? 0,
        })),
      recentActivities: recentAppointments.map((appointment) => {
        const action = this.resolveAction(appointment.status);
        return {
          id: appointment.appointment_id.toString(),
          patientName: appointment.patient.full_name,
          patientInitial: this.toInitial(appointment.patient.full_name),
          action,
          actionLabel: this.toActionLabel(action),
          occurredAt: appointment.updated_at.toISOString(),
        };
      }),
    };
  }

  private resolveRange(query: DashboardOverviewQueryDto) {
    const to = query.to ? new Date(query.to) : new Date();
    const from = query.from
      ? new Date(query.from)
      : new Date(new Date().setMonth(new Date().getMonth() - 3));

    return {
      from: this.startOfDay(from),
      to: this.endOfDay(to),
    };
  }

  private getWeekRange() {
    const now = new Date();
    const today = this.startOfDay(now);
    const day = today.getDay();
    const diffToMonday = day === 0 ? -6 : 1 - day;
    const start = new Date(today);
    start.setDate(today.getDate() + diffToMonday);
    const end = new Date(start);
    end.setDate(start.getDate() + 6);
    end.setHours(23, 59, 59, 999);

    const labels = Array.from({ length: 7 }, (_, index) => {
      const date = new Date(start);
      date.setDate(start.getDate() + index);
      return {
        label: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][index],
        date,
      };
    });

    return { start, end, labels };
  }

  private toWeekLabel(date: Date) {
    const weekday = date.getDay();
    switch (weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      default:
        return 'CN';
    }
  }

  private resolveAction(status: AppointmentStatus): DashboardActivityAction {
    switch (status) {
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      default:
        return 'created';
    }
  }

  private toActionLabel(action: DashboardActivityAction) {
    switch (action) {
      case 'cancelled':
        return 'Hủy lịch hẹn';
      case 'completed':
        return 'Hoàn thành khám';
      case 'confirmed':
        return 'Xác nhận lịch hẹn';
      default:
        return 'Đặt lịch khám';
    }
  }

  private toInitial(fullName: string) {
    const normalized = fullName.trim();
    if (!normalized) {
      return 'N';
    }

    return normalized.substring(0, 1).toUpperCase();
  }

  private startOfDay(date: Date) {
    const copy = new Date(date);
    copy.setHours(0, 0, 0, 0);
    return copy;
  }

  private endOfDay(date: Date) {
    const copy = new Date(date);
    copy.setHours(23, 59, 59, 999);
    return copy;
  }
}
