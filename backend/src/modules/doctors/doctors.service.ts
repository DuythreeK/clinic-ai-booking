import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreateDoctorDto, UpdateDoctorDto } from './dto/doctor.dto';
import { okResponse, paginatedResponse } from '@/common/utils/api-response';

@Injectable()
export class DoctorsService {
  constructor(private prisma: PrismaService) {}

  private toBigIntId(id: string): bigint {
    return BigInt(id);
  }

  private toResponse(doctor: any) {
    return {
      doctorId: doctor.doctorId.toString(),
      userId: doctor.userId.toString(),
      fullName: doctor.fullName,
      title: doctor.title,
      bio: doctor.bio,
      experienceYears: doctor.experience_years,
      avatarUrl: doctor.avatar_url,
      consultationFee: doctor.consultation_fee ? Number(doctor.consultation_fee) : null,
      isActive: doctor.isActive === 1,
      specialty: doctor.specialty
        ? {
            specialtyId: doctor.specialty.specialty_id.toString(),
            name: doctor.specialty.name,
            description: doctor.specialty.description,
          }
        : null,
      facility: doctor.facility
        ? {
            facilityId: doctor.facility.facilityId.toString(),
            name: doctor.facility.name,
            facilityType: doctor.facility.facility_type,
            addressDetail: doctor.facility.address_detail,
          }
        : null,
      createdAt: doctor.createdAt,
      updatedAt: doctor.updated_at,
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
      isActive: 1,
      specialty_id: specialtyId ? this.toBigIntId(specialtyId) : undefined,
      facilityId: facilityId ? this.toBigIntId(facilityId) : undefined,
      fullName: search
        ? {
            contains: search,
          }
        : undefined,
    };

    const [doctors, totalItems] = await Promise.all([
      this.prisma.doctor.findMany({
        where,
        include: {
          specialty: true,
          facility: true,
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.doctor.count({ where }),
    ]);

    const items = doctors.map((doctor) => ({
      id: Number(doctor.doctorId),
      fullName: doctor.fullName,
      avatarUrl: doctor.avatar_url,
      title: doctor.title,
      experienceYears: doctor.experience_years,
      consultationFee: doctor.consultation_fee ? Number(doctor.consultation_fee) : null,
      specialty: doctor.specialty
        ? {
            id: Number(doctor.specialty.specialty_id),
            name: doctor.specialty.name,
          }
        : null,
      facility: doctor.facility
        ? {
            id: Number(doctor.facility.facilityId),
            name: doctor.facility.name,
          }
        : null,
      ratingAvg: 4.8,
    }));

    return paginatedResponse('Get doctors successfully', items, page, limit, totalItems);
  }

  async getDoctorById(id: string) {
    const doctor = await this.prisma.doctor.findUnique({
      where: { doctorId: this.toBigIntId(id) },
      include: {
        specialty: true,
        facility: true,
      },
    });

    if (!doctor || doctor.isActive !== 1) {
      throw new NotFoundException('Doctor not found');
    }

    return okResponse('Get doctor detail successfully', {
      id: Number(doctor.doctorId),
      fullName: doctor.fullName,
      title: doctor.title,
      bio: doctor.bio,
      experienceYears: doctor.experience_years,
      consultationFee: doctor.consultation_fee ? Number(doctor.consultation_fee) : null,
      specialty: doctor.specialty
        ? {
            id: Number(doctor.specialty.specialty_id),
            name: doctor.specialty.name,
          }
        : null,
      facility: doctor.facility
        ? {
            id: Number(doctor.facility.facilityId),
            name: doctor.facility.name,
          }
        : null,
      ratingAvg: 4.8,
      reviewCount: await this.prisma.doctorReview.count({
        where: { doctorId: doctor.doctorId, is_visible: 1 },
      }),
    });
  }

  async getDoctorReviews(id: string) {
    await this.getDoctorById(id);

    const reviews = await this.prisma.doctorReview.findMany({
      where: {
        doctorId: this.toBigIntId(id),
        is_visible: 1,
      },
      include: {
        user: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    const items = reviews.map((review) => ({
      id: Number(review.review_id),
      rating: review.rating,
      comment: review.comment,
      createdAt: review.createdAt,
      user: {
        id: Number(review.userId),
        fullName: review.user.fullName,
      },
    }));

    return paginatedResponse('Get doctor reviews successfully', items, 1, 10, items.length);
  }

  async createDoctor(userId: string, dto: CreateDoctorDto) {
    const doctor = await this.prisma.doctor.create({
      data: {
        userId: this.toBigIntId(userId),
        fullName: dto.fullName,
        specialty_id: this.toBigIntId(dto.specialtyId),
        facilityId: this.toBigIntId(dto.facilityId),
        title: dto.title,
        bio: dto.bio,
        experience_years: dto.yearsExperience,
      },
      include: {
        specialty: true,
        facility: true,
      },
    });

    return this.toResponse(doctor);
  }

  async updateDoctor(id: string, dto: UpdateDoctorDto) {
    await this.getDoctorById(id);

    const doctor = await this.prisma.doctor.update({
      where: { doctorId: this.toBigIntId(id) },
      data: {
        fullName: dto.fullName,
        specialty_id: dto.specialtyId ? this.toBigIntId(dto.specialtyId) : undefined,
        facilityId: dto.facilityId ? this.toBigIntId(dto.facilityId) : undefined,
        title: dto.title,
        bio: dto.bio,
        experience_years: dto.yearsExperience,
      },
      include: {
        specialty: true,
        facility: true,
      },
    });

    return this.toResponse(doctor);
  }
}
