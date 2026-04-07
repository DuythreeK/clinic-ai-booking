import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { StatsQueryDto, SlotFillQueryDto, StatPeriod } from '../dto/stats.dto';

@Injectable()
export class StatsService {
  constructor(private prisma: PrismaService) {}

  /** Lấy khoảng thời gian mặc định nếu không truyền from/to */
  private getDateRange(query: StatsQueryDto): { from: Date; to: Date } {
    const to = query.to ? new Date(query.to) : new Date();
    const from = query.from
      ? new Date(query.from)
      : new Date(new Date().setMonth(new Date().getMonth() - 3));
    return { from, to };
  }

  /** FORMAT label theo period */
  private getDateFormat(period: StatPeriod): string {
    switch (period) {
      case StatPeriod.day:
        return '%Y-%m-%d';
      case StatPeriod.year:
        return '%Y';
      default:
        return '%Y-%m';
    }
  }

  // ─── 1. Doanh thu ────────────────────────────────────────────
  async getRevenue(query: StatsQueryDto) {
    const { from, to } = this.getDateRange(query);
    const fmt = this.getDateFormat(query.period ?? StatPeriod.month);

    const rows = await this.prisma.$queryRaw<
      { label: string; total_revenue: string; appointment_count: string }[]
    >`
      SELECT
        DATE_FORMAT(p.paid_at, ${fmt})    AS label,
        SUM(p.amount)                     AS total_revenue,
        COUNT(DISTINCT p.appointment_id)  AS appointment_count
      FROM tblPayment p
      WHERE p.status = 'success'
        AND p.paid_at BETWEEN ${from} AND ${to}
      GROUP BY label
      ORDER BY label ASC
    `;

    const data = rows.map((r) => ({
      label: r.label,
      totalRevenue: Number(r.total_revenue),
      appointmentCount: Number(r.appointment_count),
    }));

    const total = data.reduce((s, r) => s + r.totalRevenue, 0);
    const avg = data.length ? total / data.length : 0;

    return {
      period: query.period,
      data,
      summary: { total, avgPerPeriod: Math.round(avg) },
    };
  }

  // ─── 2. Hiệu suất bác sĩ ─────────────────────────────────────
  async getDoctorPerformance(query: StatsQueryDto) {
    const { from, to } = this.getDateRange(query);

    const rows = await this.prisma.$queryRaw<
      {
        doctor_id: string;
        full_name: string;
        specialty: string;
        completed: string;
        cancelled: string;
        no_show: string;
        total: string;
      }[]
    >`
      SELECT
        d.doctor_id,
        d.full_name,
        sp.name                                         AS specialty,
        SUM(a.status = 'completed')                     AS completed,
        SUM(a.status = 'cancelled')                     AS cancelled,
        SUM(a.status = 'no_show')                       AS no_show,
        COUNT(a.appointment_id)                         AS total
      FROM tblDoctor d
      LEFT JOIN tblAppointment a
             ON a.doctor_id = d.doctor_id
            AND a.appointment_date BETWEEN ${from} AND ${to}
      JOIN tblSpecialty sp ON d.specialty_id = sp.specialty_id
      GROUP BY d.doctor_id, d.full_name, sp.name
      ORDER BY completed DESC
    `;

    return {
      data: rows.map((r) => ({
        doctorId: Number(r.doctor_id),
        name: r.full_name,
        specialty: r.specialty,
        completed: Number(r.completed),
        cancelled: Number(r.cancelled),
        noShow: Number(r.no_show),
        total: Number(r.total),
        completionRate:
          Number(r.total) > 0
            ? Math.round((Number(r.completed) / Number(r.total)) * 1000) / 10
            : 0,
      })),
    };
  }

  // ─── 3. Tỷ lệ lấp đầy Slot ───────────────────────────────────
  async getSlotFillRate(query: SlotFillQueryDto) {
    const { from, to } = this.getDateRange(query);

    const rows = await this.prisma.$queryRaw<
      {
        doctor_id: string;
        full_name: string;
        facility_name: string;
        total_capacity: string;
        total_booked: string;
      }[]
    >`
      SELECT
        d.doctor_id,
        d.full_name,
        f.name                                              AS facility_name,
        SUM(sl.available_count + (
          SELECT COUNT(*) FROM tblAppointment a2
          WHERE a2.slot_id = sl.slot_id
        ))                                                  AS total_capacity,
        SUM(
          SELECT COUNT(*) FROM tblAppointment a3
          WHERE a3.slot_id = sl.slot_id
            AND a3.status NOT IN ('cancelled','no_show')
        )                                                   AS total_booked
      FROM tblSlots sl
      JOIN tblDoctor d ON sl.doctor_id = d.doctor_id
      JOIN tblFacility f ON sl.facility_id = f.facility_id
      WHERE sl.slot_date BETWEEN ${from} AND ${to}
        ${query.facility_id ? this.prisma.$queryRaw`AND sl.facility_id = ${Number(query.facility_id)}` : this.prisma.$queryRaw``}
      GROUP BY d.doctor_id, d.full_name, f.name
    `;

    // Dùng approach đơn giản hơn
    const simpleRows = await this.prisma.$queryRaw<
      {
        doctor_id: string;
        full_name: string;
        facility_name: string;
        slot_count: string;
        booked_count: string;
      }[]
    >`
      SELECT
        d.doctor_id,
        d.full_name,
        f.name                                       AS facility_name,
        COUNT(sl.slot_id)                            AS slot_count,
        SUM(CASE WHEN sl.status = 'FULL' THEN 1 ELSE 0 END) AS booked_count
      FROM tblSlots sl
      JOIN tblDoctor d ON sl.doctor_id = d.doctor_id
      JOIN tblFacility f ON sl.facility_id = f.facility_id
      WHERE sl.slot_date BETWEEN ${from} AND ${to}
        AND sl.is_active = 1
      GROUP BY d.doctor_id, d.full_name, f.name
      ORDER BY booked_count DESC
    `;

    return {
      data: simpleRows.map((r) => ({
        doctorId: Number(r.doctor_id),
        name: r.full_name,
        facility: r.facility_name,
        totalSlots: Number(r.slot_count),
        bookedSlots: Number(r.booked_count),
        fillRate:
          Number(r.slot_count) > 0
            ? Math.round((Number(r.booked_count) / Number(r.slot_count)) * 1000) / 10
            : 0,
      })),
    };
  }

  // ─── 4. Phân tích bệnh nhân ──────────────────────────────────
  async getPatientAnalysis(query: StatsQueryDto) {
    const { from, to } = this.getDateRange(query);
    const fmt = this.getDateFormat(query.period ?? StatPeriod.month);

    // Bệnh nhân mới (lần đầu có appointment)
    const newPatientsRows = await this.prisma.$queryRaw<
      { label: string; new_patients: string }[]
    >`
      SELECT
        DATE_FORMAT(MIN(a.created_at), ${fmt}) AS label,
        COUNT(DISTINCT a.patient_id)           AS new_patients
      FROM tblAppointment a
      WHERE a.created_at BETWEEN ${from} AND ${to}
      GROUP BY DATE_FORMAT(a.created_at, ${fmt})
      ORDER BY label ASC
    `;

    // Top specialties
    const topSpecialties = await this.prisma.$queryRaw<
      { specialty_name: string; booking_count: string }[]
    >`
      SELECT
        sp.name        AS specialty_name,
        COUNT(*)       AS booking_count
      FROM tblAppointment a
      JOIN tblDoctor d ON a.doctor_id = d.doctor_id
      JOIN tblSpecialty sp ON d.specialty_id = sp.specialty_id
      WHERE a.appointment_date BETWEEN ${from} AND ${to}
        AND a.status != 'cancelled'
      GROUP BY sp.specialty_id, sp.name
      ORDER BY booking_count DESC
      LIMIT 5
    `;

    const totalNew = newPatientsRows.reduce(
      (s, r) => s + Number(r.new_patients),
      0,
    );

    return {
      newPatients: {
        total: totalNew,
        trend: newPatientsRows.map((r) => ({
          label: r.label,
          count: Number(r.new_patients),
        })),
      },
      topSpecialties: topSpecialties.map((r) => ({
        name: r.specialty_name,
        bookingCount: Number(r.booking_count),
      })),
    };
  }

  // ─── 5. Dashboard tổng hợp ───────────────────────────────────
  async getOverview(query: StatsQueryDto) {
    const { from, to } = this.getDateRange(query);

    const [revenueResult, appointmentCounts, slotStats, patientStats] =
      await Promise.all([
        // Tổng doanh thu
        this.prisma.$queryRaw<{ total: string }[]>`
          SELECT COALESCE(SUM(p.amount), 0) AS total
          FROM tblPayment p
          WHERE p.status = 'success' AND p.paid_at BETWEEN ${from} AND ${to}
        `,
        // Số lượng lịch hẹn theo status
        this.prisma.$queryRaw<
          { status: string; cnt: string }[]
        >`
          SELECT status, COUNT(*) AS cnt
          FROM tblAppointment
          WHERE appointment_date BETWEEN ${from} AND ${to}
          GROUP BY status
        `,
        // Avg fill rate
        this.prisma.$queryRaw<{ avg_fill: string }[]>`
          SELECT ROUND(
            AVG(CASE WHEN status = 'FULL' THEN 100 ELSE 0 END), 1
          ) AS avg_fill
          FROM tblSlots
          WHERE slot_date BETWEEN ${from} AND ${to} AND is_active = 1
        `,
        // Bệnh nhân mới
        this.prisma.$queryRaw<{ cnt: string }[]>`
          SELECT COUNT(DISTINCT patient_id) AS cnt
          FROM tblAppointment
          WHERE created_at BETWEEN ${from} AND ${to}
        `,
      ]);

    const apptMap: Record<string, number> = {};
    for (const row of appointmentCounts) {
      apptMap[row.status] = Number(row.cnt);
    }

    return {
      revenue: {
        total: Number(revenueResult[0]?.total ?? 0),
      },
      appointments: {
        total: Object.values(apptMap).reduce((s, v) => s + v, 0),
        completed: apptMap['completed'] ?? 0,
        confirmed: apptMap['confirmed'] ?? 0,
        pending: apptMap['pending'] ?? 0,
        cancelled: apptMap['cancelled'] ?? 0,
        noShow: apptMap['no_show'] ?? 0,
      },
      slotFillRate: {
        avg: Number(slotStats[0]?.avg_fill ?? 0),
      },
      patients: {
        newInPeriod: Number(patientStats[0]?.cnt ?? 0),
      },
    };
  }
}
