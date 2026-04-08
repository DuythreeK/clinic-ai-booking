import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateDoctorDto, UpdateDoctorDto } from './dto/doctor.dto';
import { MobileDoctorCardDto, MobileDoctorReviewDto } from './dto/mobile-doctor.dto';
import { okResponse, paginatedResponse } from '@/common/utils/api-response';
import {
  formatCurrencyVnd,
  formatDateOnly,
  formatTimeOnly,
  toNumberId,
} from '@/common/utils/formatters';

@Injectable()
export class DoctorsService {
  constructor(private prisma: PrismaService) {}

  private toBigIntId(id: string) {
    return BigInt(id);
  }

  private getTodayRange() {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const end = new Date(start);
    end.setHours(23, 59, 59, 999);
    return { start, end };
  }

  private getTomorrowDate() {
    const date = new Date();
    date.setDate(date.getDate() + 1);
    date.setHours(0, 0, 0, 0);
    return date;
  }

  private formatAvailability(slotDate?: Date | null, startTime?: Date | null) {
    if (!slotDate || !startTime) {
      return null;
    }

    const time = formatTimeOnly(startTime);
    const today = this.getTodayRange().start;
    const tomorrow = this.getTomorrowDate();
    const slotDay = new Date(slotDate);
    slotDay.setHours(0, 0, 0, 0);

    let suffix = formatDateOnly(slotDate);
    if (slotDay.getTime() === today.getTime()) {
      suffix = 'hôm nay';
    } else if (slotDay.getTime() === tomorrow.getTime()) {
      suffix = 'ngày mai';
    }

    return `${time} ${suffix}`;
  }

  private initials(fullName: string) {
    return fullName
      .trim()
      .split(/\s+/)
      .slice(0, 2)
      .map((part) => part[0]?.toUpperCase() ?? '')
      .join('');
  }

  private async buildDoctorStats(doctorIds: bigint[]) {
    if (!doctorIds.length) {
      return {
        bookingMap: new Map<string, number>(),
        reviewMap: new Map<string, { count: number; rating: number }>(),
        slotMap: new Map<string, { slot_date: Date; start_time: Date }>(),
      };
    }

    const { start, end } = this.getTodayRange();

    const [todayBookings, reviewGroups, upcomingSlots] = await Promise.all([
      this.prisma.appointment.groupBy({
        by: ['doctor_id'],
        where: {
          doctor_id: { in: doctorIds },
          appointment_date: {
            gte: start,
            lte: end,
          },
          status: {
            not: 'cancelled',
          },
        },
        _count: { doctor_id: true },
      }),
      this.prisma.doctorReview.groupBy({
        by: ['doctor_id'],
        where: {
          doctor_id: { in: doctorIds },
          is_visible: 1,
        },
        _count: { doctor_id: true },
        _avg: { rating: true },
      }),
      this.prisma.slot.findMany({
        where: {
          doctor_id: { in: doctorIds },
          is_active: 1,
          status: 'AVAILABLE',
          slot_date: {
            gte: start,
          },
        },
        orderBy: [{ slot_date: 'asc' }, { start_time: 'asc' }],
        select: {
          doctor_id: true,
          slot_date: true,
          start_time: true,
        },
      }),
    ]);

    const bookingMap = new Map<string, number>();
    todayBookings.forEach((item) => {
      bookingMap.set(item.doctor_id?.toString() ?? '', item._count.doctor_id);
    });

    const reviewMap = new Map<string, { count: number; rating: number }>();
    reviewGroups.forEach((item) => {
      reviewMap.set(item.doctor_id?.toString() ?? '', {
        count: item._count.doctor_id,
        rating: Number(item._avg.rating ?? 0),
      });
    });

    const slotMap = new Map<string, { slot_date: Date; start_time: Date }>();
    for (const slot of upcomingSlots) {
      const key = slot.doctor_id.toString();
      if (!slotMap.has(key)) {
        slotMap.set(key, slot);
      }
    }

    return { bookingMap, reviewMap, slotMap };
  }

  private mapDoctorToMobile(
    doctor: any,
    stats: {
      bookingMap: Map<string, number>;
      reviewMap: Map<string, { count: number; rating: number }>;
      slotMap: Map<string, { slot_date: Date; start_time: Date }>;
    },
  ): MobileDoctorCardDto {
    const doctorId = doctor.doctor_id.toString();
    const bookingToday = stats.bookingMap.get(doctorId) ?? 0;
    const reviewStats = stats.reviewMap.get(doctorId) ?? { count: 0, rating: 0 };
    const nextSlot = stats.slotMap.get(doctorId);

    return {
      id: toNumberId(doctor.doctor_id)!,
      name: doctor.full_name,
      specialty: doctor.specialty?.name ?? 'Chưa cập nhật',
      focus: doctor.title ?? doctor.specialty?.name ?? 'Khám tổng quát',
      imageUrl: doctor.avatar_url,
      rating: reviewStats.count ? Number(reviewStats.rating.toFixed(1)) : 0,
      reviewCount: reviewStats.count,
      priceValue: Number(doctor.consultation_fee ?? 0),
      priceLabel:
        formatCurrencyVnd(Number(doctor.consultation_fee ?? 0), 'đ/lần') ?? '0đ/lần',
      bookingToday,
      yearsExperience: doctor.experience_years ?? 0,
      patientsLabel: reviewStats.count
        ? `${reviewStats.count} quan tâm`
        : `${bookingToday} người đã đặt hôm nay`,
      nextAvailable: this.formatAvailability(nextSlot?.slot_date, nextSlot?.start_time),
      gender: 'Không rõ',
      email: doctor.user?.email ?? null,
      phone: doctor.user?.phone ?? null,
      about: doctor.bio ?? '',
      certifications: [],
      facility: doctor.facility
        ? {
            id: toNumberId(doctor.facility.facility_id)!,
            name: doctor.facility.name,
            type: doctor.facility.facility_type,
            address: [
              doctor.facility.address_detail,
              doctor.facility.ward,
              doctor.facility.district,
              doctor.facility.province,
            ]
              .filter(Boolean)
              .join(', '),
          }
        : null,
    };
  }

  async getDoctors(
    page = 1,
    limit = 10,
    search?: string,
    specialtyId?: string,
    facilityId?: string,
  ) {
    const where = {
      is_active: 1,
      specialty_id: specialtyId ? this.toBigIntId(specialtyId) : undefined,
      facility_id: facilityId ? this.toBigIntId(facilityId) : undefined,
      full_name: search ? { contains: search } : undefined,
    };

    const [doctors, totalItems] = await Promise.all([
      this.prisma.doctor.findMany({
        where,
        include: {
          specialty: true,
          facility: true,
          user: true,
        },
        orderBy: { created_at: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.doctor.count({ where }),
    ]);

    const stats = await this.buildDoctorStats(doctors.map((doctor) => doctor.doctor_id));
    const items = doctors.map((doctor) => this.mapDoctorToMobile(doctor, stats));

    return paginatedResponse('Get doctors successfully', items, page, limit, totalItems);
  }

  async getFeaturedDoctors(limit = 10, search?: string, specialty?: string) {
    const doctors = await this.prisma.doctor.findMany({
      where: {
        is_active: 1,
        full_name: search ? { contains: search } : undefined,
        specialty: specialty ? { name: specialty } : undefined,
      },
      include: {
        specialty: true,
        facility: true,
        user: true,
      },
    });

    const stats = await this.buildDoctorStats(doctors.map((doctor) => doctor.doctor_id));
    const items = doctors
      .map((doctor) => this.mapDoctorToMobile(doctor, stats))
      .sort((a, b) => b.bookingToday - a.bookingToday)
      .slice(0, limit);

    return okResponse('Get featured doctors successfully', items);
  }

  async getMyDoctors(userId: string, search?: string) {
    const parsedUserId = this.toBigIntId(userId);

    const [appointments, reviews] = await Promise.all([
      this.prisma.appointment.findMany({
        where: {
          user_id: parsedUserId,
          doctor_id: { not: null },
        },
        select: { doctor_id: true },
      }),
      this.prisma.doctorReview.findMany({
        where: { user_id: parsedUserId },
        select: { doctor_id: true },
      }),
    ]);

    const doctorIds = [
      ...new Set(
        [...appointments, ...reviews]
          .map((item) => item.doctor_id?.toString())
          .filter((value): value is string => Boolean(value)),
      ),
    ].map((value) => BigInt(value));

    if (!doctorIds.length) {
      return okResponse('Get my doctors successfully', [] as MobileDoctorCardDto[]);
    }

    const doctors = await this.prisma.doctor.findMany({
      where: {
        doctor_id: { in: doctorIds },
        is_active: 1,
        full_name: search ? { contains: search } : undefined,
      },
      include: {
        specialty: true,
        facility: true,
        user: true,
      },
    });

    const stats = await this.buildDoctorStats(doctors.map((doctor) => doctor.doctor_id));
    const items = doctors
      .map((doctor) => this.mapDoctorToMobile(doctor, stats))
      .sort((a, b) => b.rating - a.rating);

    return okResponse('Get my doctors successfully', items);
  }

  async getDoctorById(id: string) {
    const doctor = await this.prisma.doctor.findUnique({
      where: { doctor_id: this.toBigIntId(id) },
      include: {
        specialty: true,
        facility: true,
        user: true,
      },
    });

    if (!doctor || doctor.is_active !== 1) {
      throw new NotFoundException('Doctor not found');
    }

    const stats = await this.buildDoctorStats([doctor.doctor_id]);
    return okResponse('Get doctor detail successfully', this.mapDoctorToMobile(doctor, stats));
  }

  async getDoctorByUserId(userId: string) {
    const doctor = await this.prisma.doctor.findUnique({
      where: { user_id: this.toBigIntId(userId) },
      include: {
        specialty: true,
        facility: true,
        user: true,
      },
    });

    if (!doctor || doctor.is_active !== 1) {
      throw new NotFoundException('Doctor not found');
    }

    const stats = await this.buildDoctorStats([doctor.doctor_id]);
    return okResponse(
      'Get current doctor profile successfully',
      this.mapDoctorToMobile(doctor, stats),
    );
  }

  async getDoctorReviews(id: string) {
    await this.getDoctorById(id);

    const reviews = await this.prisma.doctorReview.findMany({
      where: {
        doctor_id: this.toBigIntId(id),
        is_visible: 1,
      },
      include: {
        user: true,
      },
      orderBy: { created_at: 'desc' },
    });

    const items: MobileDoctorReviewDto[] = reviews.map((review) => ({
      id: toNumberId(review.review_id)!,
      reviewerName: review.user.full_name,
      reviewerAvatar: this.initials(review.user.full_name),
      rating: review.rating,
      comment: review.comment,
      createdAt: review.created_at,
    }));

    return paginatedResponse('Get doctor reviews successfully', items, 1, 10, items.length);
  }

  async createDoctor(userId: string, dto: CreateDoctorDto) {
    const doctor = await this.prisma.doctor.create({
      data: {
        user_id: this.toBigIntId(userId),
        full_name: dto.fullName,
        specialty_id: this.toBigIntId(dto.specialtyId),
        facility_id: this.toBigIntId(dto.facilityId),
        title: dto.title,
        bio: dto.bio,
        experience_years: dto.yearsExperience,
      },
      include: {
        specialty: true,
        facility: true,
        user: true,
      },
    });

    const stats = await this.buildDoctorStats([doctor.doctor_id]);
    return okResponse('Create doctor successfully', this.mapDoctorToMobile(doctor, stats));
  }

  async updateDoctor(id: string, dto: UpdateDoctorDto) {
    await this.getDoctorById(id);

    const doctor = await this.prisma.doctor.update({
      where: { doctor_id: this.toBigIntId(id) },
      data: {
        full_name: dto.fullName,
        specialty_id: dto.specialtyId ? this.toBigIntId(dto.specialtyId) : undefined,
        facility_id: dto.facilityId ? this.toBigIntId(dto.facilityId) : undefined,
        title: dto.title,
        bio: dto.bio,
        experience_years: dto.yearsExperience,
      },
      include: {
        specialty: true,
        facility: true,
        user: true,
      },
    });

    const stats = await this.buildDoctorStats([doctor.doctor_id]);
    return okResponse('Update doctor successfully', this.mapDoctorToMobile(doctor, stats));
  }
}
