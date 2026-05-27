/**
 * ClinicsService
 * - Đọc dữ liệu cơ sở y tế từ Prisma và chuyển thành response phù hợp.
 * - Gom phần format response về một chỗ để controller gọn hơn.
 */
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { okResponse, paginatedResponse } from '@/common/utils/api-response';
import { toNumberId } from '@/common/utils/formatters';

@Injectable()
export class ClinicsService {
  constructor(private prisma: PrismaService) {}

  // Chuẩn hoá dữ liệu facility sang response dùng chung cho list/detail.
  private toResponse(facility: any) {
    return {
      id: toNumberId(facility.facility_id),
      name: facility.name,
      facilityType: facility.facility_type,
      phone: facility.phone,
      email: facility.email,
      addressDetail: facility.address_detail,
      province: facility.province,
      district: facility.district,
      ward: facility.ward,
      address: [
        facility.address_detail,
        facility.ward,
        facility.district,
        facility.province,
      ]
        .filter(Boolean)
        .join(', '),
      ratingAvg: Number(facility.rating_avg),
      is_active: facility.is_active === 1,
    };
  }

  // Response rút gọn cho mobile, chỉ giữ thông tin cần thiết.
  async getMobileFacilities(search?: string, facilityType?: string) {
    const facilities = await this.prisma.facility.findMany({
      where: {
        is_active: 1,
        facility_type: facilityType as any,
        name: search ? { contains: search } : undefined,
      },
      orderBy: [{ rating_avg: 'desc' }, { created_at: 'desc' }],
    });

    return okResponse(
      'Get mobile facilities successfully',
      facilities.map((facility) => ({
        id: toNumberId(facility.facility_id),
        name: facility.name,
        type: facility.facility_type,
        address: [
          facility.address_detail,
          facility.ward,
          facility.district,
          facility.province,
        ]
          .filter(Boolean)
          .join(', '),
        phone: facility.phone,
        email: facility.email,
        rating: Number(facility.rating_avg),
      })),
    );
  }

  // API danh sách phòng khám có phân trang.
  async getClinics(page = 1, limit = 10, search?: string, facilityType?: string) {
    const where = {
      is_active: 1,
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
        orderBy: { created_at: 'desc' },
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

  // API chi tiết phòng khám cho màn detail.
  async getClinicById(id: string) {
    const facility = await this.prisma.facility.findUnique({
      where: { facility_id: BigInt(id) },
    });

    if (!facility || facility.is_active !== 1) {
      throw new NotFoundException('Facility not found');
    }

    return okResponse('Get facility detail successfully', {
      ...this.toResponse(facility),
      email: facility.email,
      openingHours: facility.opening_hours,
    });
  }
}
