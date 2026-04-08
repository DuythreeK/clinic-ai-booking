import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import {
  VaccinationBookingDetailDto,
  VaccinationPackageDto,
  VaccinationSlotGroupDto,
} from './dto/mobile-vaccination.dto';
import { okResponse, paginatedResponse } from '@/common/utils/api-response';
import {
  formatCurrencyVnd,
  formatDateOnly,
  formatTimeOnly,
  toNumberId,
} from '@/common/utils/formatters';

@Injectable()
export class ServicesService {
  constructor(private prisma: PrismaService) {}

  private toBigIntId(id: string): bigint {
    return BigInt(id);
  }

  private weekdayLabel(date: Date) {
    const labels = ['Chủ nhật', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];
    return labels[date.getDay()];
  }

  private toResponse(service: any) {
    return {
      serviceId: service.serviceId.toString(),
      facilityId: service.facilityId.toString(),
      name: service.name,
      description: service.description,
      price: Number(service.price),
      durationMinutes: service.duration_minutes,
      isActive: service.isActive === 1,
      facility: service.facility
        ? {
            facilityId: service.facility.facilityId.toString(),
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
      isActive: 1,
      facilityId: facilityId ? this.toBigIntId(facilityId) : undefined,
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
      id: Number(service.serviceId),
      facilityId: Number(service.facilityId),
      name: service.name,
      description: service.description,
      price: Number(service.price),
      durationMinutes: service.duration_minutes,
      isActive: service.isActive === 1,
    }));

    return paginatedResponse('Get services successfully', items, page, limit, totalItems);
  }

  async getServiceById(id: string) {
    const service = await this.prisma.service.findUnique({
      where: { serviceId: this.toBigIntId(id) },
      include: {
        facility: true,
        vaccines: {
          include: {
            vaccine: true,
          },
        },
      },
    });

    if (!service || service.isActive !== 1) {
      throw new NotFoundException('Service not found');
    }

    return okResponse('Get service detail successfully', {
      id: Number(service.serviceId),
      facilityId: Number(service.facilityId),
      name: service.name,
      description: service.description,
      price: Number(service.price),
      durationMinutes: service.duration_minutes,
      isActive: service.isActive === 1,
      facility: service.facility
        ? {
            id: Number(service.facility.facilityId),
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
      where: { serviceId: this.toBigIntId(id) },
    });

    if (!service || service.isActive !== 1) {
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
        facilityId: service.facilityId,
        isActive: 1,
        status: 'AVAILABLE',
        slotDate: rangeFrom || rangeTo
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
      orderBy: [{ slotDate: 'asc' }, { startTime: 'asc' }],
    });

    return okResponse('Get available slots successfully', {
      serviceId: toNumberId(service.serviceId),
      date: date ?? formatDateOnly(slots[0]?.slotDate),
      slots: slots.map((slot) => ({
        slotId: toNumberId(slot.slotId),
        startTime: formatTimeOnly(slot.startTime),
        endTime: formatTimeOnly(slot.endTime),
        availableCount: slot.available_count,
        status: slot.status === 'AVAILABLE' ? 'available' : slot.status.toLowerCase(),
      })),
    });
  }

  async getVaccinationPackages(search?: string, facilityId?: string) {
    const services = await this.prisma.service.findMany({
      where: {
        is_active: 1,
        facility_id: facilityId ? this.toBigIntId(facilityId) : undefined,
        name: search ? { contains: search } : undefined,
        vaccines: {
          some: {},
        },
      },
      include: {
        facility: true,
        vaccines: {
          include: {
            vaccine: true,
          },
        },
      },
      orderBy: [{ price: 'asc' }, { name: 'asc' }],
    });

    const items: VaccinationPackageDto[] = services.map((service) => ({
      id: toNumberId(service.service_id)!,
      title: service.name,
      facilityId: toNumberId(service.facility_id)!,
      facilityName: service.facility.name,
      facilityAddress: [
        service.facility.address_detail,
        service.facility.ward,
        service.facility.district,
        service.facility.province,
      ]
        .filter(Boolean)
        .join(', '),
      priceValue: Number(service.price),
      priceLabel: formatCurrencyVnd(Number(service.price), ' VND') ?? '0 VND',
      note: service.description ?? 'Thanh toán tại cơ sở',
      badge: service.vaccines[0]?.vaccine.name ?? 'Tiêm chủng',
    }));

    return okResponse('Get vaccination packages successfully', items);
  }

  async getVaccinationBookingDetail(
    id: string,
    date?: string,
    fromDate?: string,
    toDate?: string,
  ) {
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
      orderBy: [{ slot_date: 'asc' }, { start_time: 'asc' }],
    });

    const slotGroupMap = new Map<string, VaccinationSlotGroupDto>();
    for (const slot of slots) {
      const key = formatDateOnly(slot.slot_date) ?? '';
      if (!slotGroupMap.has(key)) {
        slotGroupMap.set(key, {
          date: key,
          weekdayLabel: this.weekdayLabel(new Date(slot.slot_date)),
          morningSlots: [],
          afternoonSlots: [],
        });
      }

      const group = slotGroupMap.get(key)!;
      const item = {
        slotId: toNumberId(slot.slot_id)!,
        startTime: formatTimeOnly(slot.start_time),
        endTime: formatTimeOnly(slot.end_time),
        availableCount: slot.available_count,
      };

      const hour = new Date(slot.start_time).getHours();
      if (hour < 12) {
        group.morningSlots.push(item);
      } else {
        group.afternoonSlots.push(item);
      }
    }

    const detail: VaccinationBookingDetailDto = {
      serviceId: toNumberId(service.service_id)!,
      serviceName: service.name,
      specialty: 'TIÊM NGỪA',
      servicePriceValue: Number(service.price),
      servicePriceLabel: formatCurrencyVnd(Number(service.price), ' VND') ?? '0 VND',
      note: service.description ?? 'Thanh toán tại cơ sở',
      facility: {
        id: toNumberId(service.facility.facility_id)!,
        name: service.facility.name,
        type: service.facility.facility_type,
        address: [
          service.facility.address_detail,
          service.facility.ward,
          service.facility.district,
          service.facility.province,
        ]
          .filter(Boolean)
          .join(', '),
        rating: Number(service.facility.rating_avg),
      },
      slots: [...slotGroupMap.values()],
    };

    return okResponse('Get vaccination booking detail successfully', detail);
  }
}

