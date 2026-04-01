import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { okResponse, paginatedResponse } from '@/common/utils/api-response';
import { formatDateOnly, formatTimeOnly, toNumberId } from '@/common/utils/formatters';

@Injectable()
export class ServicesService {
  constructor(private prisma: PrismaService) {}

  private toBigIntId(id: string): bigint {
    return BigInt(id);
  }

  private toResponse(service: any) {
    return {
      serviceId: service.service_id.toString(),
      facilityId: service.facility_id.toString(),
      name: service.name,
      description: service.description,
      price: Number(service.price),
      durationMinutes: service.duration_minutes,
      isActive: service.is_active === 1,
      facility: service.facility
        ? {
            facilityId: service.facility.facility_id.toString(),
            name: service.facility.name,
          }
        : null,
      vaccines: service.vaccines?.map((item: any) => ({
        vaccineId: item.vaccine.vaccine_id.toString(),
        name: item.vaccine.name,
        manufacturer: item.vaccine.manufacturer,
        countryOfOrigin: item.vaccine.country_of_origin,
        doseCount: item.vaccine.dose_count,
        quantity: item.quantity,
      })),
    };
  }

  async getServices(page = 1, limit = 10, facilityId?: string, search?: string) {
    const where = {
      is_active: 1,
      facility_id: facilityId ? this.toBigIntId(facilityId) : undefined,
      name: search
        ? {
            contains: search,
          }
        : undefined,
    };

    const [services, totalItems] = await Promise.all([
      this.prisma.service.findMany({
        where,
        include: {
          facility: true,
          vaccines: {
            include: {
              vaccine: true,
            },
          },
        },
        orderBy: { name: 'asc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.service.count({ where }),
    ]);

    const items = services.map((service) => ({
      id: Number(service.service_id),
      facilityId: Number(service.facility_id),
      name: service.name,
      description: service.description,
      price: Number(service.price),
      durationMinutes: service.duration_minutes,
      isActive: service.is_active === 1,
    }));

    return paginatedResponse('Get services successfully', items, page, limit, totalItems);
  }

  async getServiceById(id: string) {
    const service = await this.prisma.service.findUnique({
      where: { service_id: this.toBigIntId(id) },
      include: {
        facility: true,
        vaccines: {
          include: {
            vaccine: true,
          },
        },
      },
    });

    if (!service || service.is_active !== 1) {
      throw new NotFoundException('Service not found');
    }

    return okResponse('Get service detail successfully', {
      id: Number(service.service_id),
      facilityId: Number(service.facility_id),
      name: service.name,
      description: service.description,
      price: Number(service.price),
      durationMinutes: service.duration_minutes,
      isActive: service.is_active === 1,
      facility: service.facility
        ? {
            id: Number(service.facility.facility_id),
            name: service.facility.name,
          }
        : null,
      vaccines: service.vaccines.map((item) => ({
        id: Number(item.vaccine.vaccine_id),
        name: item.vaccine.name,
        manufacturer: item.vaccine.manufacturer,
        countryOfOrigin: item.vaccine.country_of_origin,
        doseCount: item.vaccine.dose_count,
      })),
    });
  }

  async getAvailableSlots(id: string, date?: string, fromDate?: string, toDate?: string) {
    const service = await this.prisma.service.findUnique({
      where: { service_id: this.toBigIntId(id) },
    });

    if (!service || service.is_active !== 1) {
      throw new NotFoundException('Service not found');
    }

    let rangeFrom = fromDate ? new Date(fromDate) : undefined;
    let rangeTo = toDate ? new Date(toDate) : undefined;

    if (date) {
      rangeFrom = new Date(date);
      rangeTo = new Date(date);
    }

    const slots = await this.prisma.slot.findMany({
      where: {
        facility_id: service.facility_id,
        is_active: 1,
        status: 'AVAILABLE',
        slot_date: rangeFrom || rangeTo
          ? {
              gte: rangeFrom,
              lte: rangeTo,
            }
          : undefined,
      },
      include: {
        doctor: true,
        facility: true,
      },
      orderBy: [{ slot_date: 'asc' }, { start_time: 'asc' }],
    });

    return okResponse('Get available slots successfully', {
      serviceId: toNumberId(service.service_id),
      date: date ?? formatDateOnly(slots[0]?.slot_date),
      slots: slots.map((slot) => ({
        slotId: toNumberId(slot.slot_id),
        startTime: formatTimeOnly(slot.start_time),
        endTime: formatTimeOnly(slot.end_time),
        availableCount: slot.available_count,
        status: slot.status === 'AVAILABLE' ? 'available' : slot.status.toLowerCase(),
      })),
    });
  }
}
