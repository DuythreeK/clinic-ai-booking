import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ClinicsService {
  constructor(private prisma: PrismaService) {}

  // Lấy danh sách tất cả phòng khám
  async findAll() {
    return this.prisma.clinic.findMany({
      include: {
        _count: {
          select: { doctors: true }, // Đếm xem có bao nhiêu bác sĩ
        },
      },
    });
  }

  // Lấy chi tiết 1 phòng khám
  async findOne(id: string) {
    const clinic = await this.prisma.clinic.findUnique({
      where: { id },
      include: {
        doctors: {
          include: {
            doctor: {
              include: {
                user: true,      // Lấy thông tin tên, avatar bác sĩ
                specialty: true, // Lấy chuyên khoa của bác sĩ đó
              },
            },
          },
        },
      },
    });

    if (!clinic) {
      throw new NotFoundException(`Không tìm thấy phòng khám với ID: ${id}`);
    }
    return clinic;
  }
}