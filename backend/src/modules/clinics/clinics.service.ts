import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { okResponse, paginatedResponse } from '@/common/utils/api-response';
import { toNumberId } from '@/common/utils/formatters';

@Injectable()
export class ClinicsService {
  constructor(private prisma: PrismaService) {}

  private toResponse(facility: any) {
    return {
      id: toNumberId(facility.facilityId),
      name: facility.name,
      facilityType: facility.facility_type,
      phone: facility.phone,
      addressDetail: facility.address_detail,
      province: facility.province,
      district: facility.district,
      ratingAvg: Number(facility.rating_avg),
      isActive: facility.isActive === 1,
    };
  }

  async getClinics(page = 1, limit = 10, search?: string, facilityType?: string) {
    const where = {
      isActive: 1,
      facility_type: facilityType as any,
      name: search
        ? {
            contains: search,
          }
        : undefined,
    };

    const [facilities, totalItems] = await Promise.all([
      this.prisma.facility.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.facility.count({ where }),
    ]);

    return paginatedResponse(
      'Get facilities successfully',
      facilities.map((facility) => this.toResponse(facility)),
      page,
      limit,
      totalItems,
    );
  }

  async getClinicById(id: string) {
    const facility = await this.prisma.facility.findUnique({
      where: { facilityId: BigInt(id) },
    });

    if (!facility || facility.isActive !== 1) {
      throw new NotFoundException('Facility not found');
    }

    return okResponse('Get facility detail successfully', {
      ...this.toResponse(facility),
      email: facility.email,
      openingHours: facility.opening_hours,
    });
  }
}
