import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreatePatientProfileDto, UpdatePatientProfileDto } from './dto/patient.dto';
import { okResponse } from '@/common/utils/api-response';
import { formatDateOnly } from '@/common/utils/formatters';

@Injectable()
export class PatientsService {
  constructor(private prisma: PrismaService) {}

  private toBigIntId(id: string): bigint {
    return BigInt(id);
  }

  private toResponse(profile: any) {
    return {
      patientId: profile.patient_id.toString(),
      userId: profile.user_id.toString(),
      fullName: profile.full_name,
      phoneNumber: profile.phone_number,
      citizenId: profile.citizen_id,
      insuranceNumber: profile.insurance_number,
      email: profile.email,
      gender: profile.gender,
      dateOfBirth: profile.date_of_birth,
      addressDetail: profile.address_detail,
      province: profile.province,
      district: profile.district,
      ward: profile.ward,
      medicalConditions: profile.medical_conditions,
      allergies: profile.allergies,
      emergencyContact: profile.emergency_contact,
      relationshipToUser: profile.relationship_to_user,
      isPrimary: profile.is_primary === 1,
      createdAt: profile.created_at,
      updatedAt: profile.updated_at,
    };
  }

  async createPatientProfile(userId: string, dto: CreatePatientProfileDto) {
    /**
     * Tạo hồ sơ bệnh nhân cho user
     * - Nếu chưa có hồ sơ chính sẽ tự đánh dấu is_primary
     * - Nếu dto.isPrimary === true sẽ unset các hồ sơ khác
     * Input: userId, CreatePatientProfileDto
     * Output: thông tin profile đã tạo
     */
    const userBigIntId = this.toBigIntId(userId);
    const existingPrimary = await this.prisma.patientProfile.findFirst({
      where: { user_id: userBigIntId, is_primary: 1 },
    });

    const profile = await this.prisma.patientProfile.create({
      data: {
        user_id: userBigIntId,
        full_name: dto.fullName,
        phone_number: dto.phoneNumber,
        citizen_id: dto.citizenId,
        insurance_number: dto.insuranceNumber,
        email: dto.email,
        occupation: dto.occupation,
        ethnicity: dto.ethnicity,
        nationality: dto.nationality,
        gender: dto.gender as any,
        date_of_birth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : undefined,
        address_detail: dto.addressDetail,
        province: dto.province,
        district: dto.district,
        ward: dto.ward,
        medical_conditions: dto.medicalConditions,
        allergies: dto.allergies,
        emergency_contact: dto.emergencyContact,
        relationship_to_user: dto.relationshipToUser,
        is_primary:
          dto.isPrimary === true || !existingPrimary
            ? 1
            : dto.isPrimary === false
              ? 0
              : undefined,
      },
    });

    if (dto.isPrimary === true) {
      await this.prisma.patientProfile.updateMany({
        where: {
          user_id: userBigIntId,
          patient_id: { not: profile.patient_id },
        },
        data: { is_primary: 0 },
      });
    }

    return okResponse('Create patient profile successfully', {
      id: Number(profile.patient_id),
      fullName: profile.full_name,
      phoneNumber: profile.phone_number,
      citizenId: profile.citizen_id,
      insuranceNumber: profile.insurance_number,
      email: profile.email,
      gender: profile.gender,
      dateOfBirth: profile.date_of_birth,
      birthDate: formatDateOnly(profile.date_of_birth),
      occupation: profile.occupation,
      ethnicity: profile.ethnicity,
      nationality: profile.nationality,
      province: profile.province,
      district: profile.district,
      ward: profile.ward,
      addressDetail: profile.address_detail,
      relationshipToUser: profile.relationship_to_user,
      isPrimary: profile.is_primary === 1,
    });
  }

  async updatePatientProfile(userId: string, id: string, dto: UpdatePatientProfileDto) {
    /**
     * Cập nhật hồ sơ bệnh nhân
     * - Kiểm tra quyền sở hữu profile
     * - Nếu thay đổi isPrimary cần đảm bảo tồn tại ít nhất 1 hồ sơ chính
     */
    const profileId = this.toBigIntId(id);
    const userBigIntId = this.toBigIntId(userId);
    const existingProfile = await this.prisma.patientProfile.findUnique({
      where: { patient_id: profileId },
    });

    if (!existingProfile || existingProfile.user_id !== userBigIntId) {
      throw new NotFoundException('Patient profile not found');
    }

    if (dto.isPrimary === false && existingProfile.is_primary === 1) {
      const otherPrimary = await this.prisma.patientProfile.findFirst({
        where: {
          user_id: userBigIntId,
          patient_id: { not: profileId },
          is_primary: 1,
        },
      });
      if (!otherPrimary) {
        throw new BadRequestException('Cần ít nhất một hồ sơ chính');
      }
    }

    const profile = await this.prisma.patientProfile.update({
      where: { patient_id: profileId },
      data: {
        full_name: dto.fullName,
        phone_number: dto.phoneNumber,
        citizen_id: dto.citizenId,
        insurance_number: dto.insuranceNumber,
        email: dto.email,
        occupation: dto.occupation,
        ethnicity: dto.ethnicity,
        nationality: dto.nationality,
        gender: dto.gender as any,
        date_of_birth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : undefined,
        address_detail: dto.addressDetail,
        province: dto.province,
        district: dto.district,
        ward: dto.ward,
        medical_conditions: dto.medicalConditions,
        allergies: dto.allergies,
        emergency_contact: dto.emergencyContact,
        relationship_to_user: dto.relationshipToUser,
        is_primary:
          dto.isPrimary === true
            ? 1
            : dto.isPrimary === false
              ? 0
              : undefined,
      },
    });

    if (dto.isPrimary === true) {
      await this.prisma.patientProfile.updateMany({
        where: {
          user_id: userBigIntId,
          patient_id: { not: profileId },
        },
        data: { is_primary: 0 },
      });
    }

    return okResponse('Update patient profile successfully', {
      id: Number(profile.patient_id),
      fullName: profile.full_name,
      phoneNumber: profile.phone_number,
      citizenId: profile.citizen_id,
      insuranceNumber: profile.insurance_number,
      email: profile.email,
      gender: profile.gender,
      dateOfBirth: profile.date_of_birth,
      birthDate: formatDateOnly(profile.date_of_birth),
      occupation: profile.occupation,
      ethnicity: profile.ethnicity,
      nationality: profile.nationality,
      province: profile.province,
      district: profile.district,
      ward: profile.ward,
      addressDetail: profile.address_detail,
      relationshipToUser: profile.relationship_to_user,
      isPrimary: profile.is_primary === 1,
    });
  }

  async deletePatientProfile(userId: string, id: string) {
    /**
     * Xóa hồ sơ bệnh nhân
     * - Nếu xóa hồ sơ chính sẽ promote hồ sơ mới làm is_primary nếu có
     * - Throws nếu cố xóa khi chỉ có 1 hồ sơ chính
     */
    const profileId = this.toBigIntId(id);
    const userBigIntId = this.toBigIntId(userId);
    const existingProfile = await this.prisma.patientProfile.findUnique({
      where: { patient_id: profileId },
    });

    if (!existingProfile || existingProfile.user_id !== userBigIntId) {
      throw new NotFoundException('Patient profile not found');
    }

    if (existingProfile.is_primary === 1) {
      const otherProfile = await this.prisma.patientProfile.findFirst({
        where: {
          user_id: userBigIntId,
          patient_id: { not: profileId },
        },
        orderBy: [{ created_at: 'desc' }],
      });

      if (!otherProfile) {
        throw new BadRequestException('Cần ít nhất một hồ sơ chính');
      }
    }

    await this.prisma.patientProfile.delete({
      where: { patient_id: profileId },
    });

    if (existingProfile.is_primary === 1) {
      const fallbackProfile = await this.prisma.patientProfile.findFirst({
        where: { user_id: userBigIntId },
        orderBy: [{ created_at: 'desc' }],
      });
      if (fallbackProfile) {
        await this.prisma.patientProfile.update({
          where: { patient_id: fallbackProfile.patient_id },
          data: { is_primary: 1 },
        });
      }
    }

    return okResponse('Delete patient profile successfully', {
      id: Number(profileId),
    });
  }

  async getPatientProfiles(userId: string) {
    /**
     * Lấy danh sách tất cả patient profiles của user, sắp theo is_primary và created_at
     */
    const profiles = await this.prisma.patientProfile.findMany({
      where: { user_id: this.toBigIntId(userId) },
      orderBy: [{ is_primary: 'desc' }, { created_at: 'desc' }],
    });

    return okResponse(
      'Get patient profiles successfully',
      profiles.map((profile) => ({
        id: Number(profile.patient_id),
        fullName: profile.full_name,
        phoneNumber: profile.phone_number,
        citizenId: profile.citizen_id,
        insuranceNumber: profile.insurance_number,
        email: profile.email,
        gender: profile.gender,
        dateOfBirth: profile.date_of_birth,
        occupation: profile.occupation,
        ethnicity: profile.ethnicity,
        nationality: profile.nationality,
        addressDetail: profile.address_detail,
        province: profile.province,
        district: profile.district,
        ward: profile.ward,
        medicalConditions: profile.medical_conditions,
        allergies: profile.allergies,
        emergencyContact: profile.emergency_contact,
        relationshipToUser: profile.relationship_to_user,
        isPrimary: profile.is_primary === 1,
      })),
    );
  }

  async getMobilePatientProfiles(userId: string) {
    /**
     * Phiên bản trả về cho mobile (format trường ngày/label thân thiện)
     */
    const profiles = await this.prisma.patientProfile.findMany({
      where: { user_id: this.toBigIntId(userId) },
      orderBy: [{ is_primary: 'desc' }, { created_at: 'desc' }],
    });

    return okResponse(
      'Get mobile patient profiles successfully',
      profiles.map((profile) => ({
        id: Number(profile.patient_id),
        fullName: profile.full_name,
        phoneNumber: profile.phone_number,
        citizenId: profile.citizen_id,
        insuranceNumber: profile.insurance_number,
        email: profile.email,
        gender:
          profile.gender === 'male'
            ? 'Nam'
            : profile.gender === 'female'
              ? 'Nữ'
              : profile.gender === 'other'
                ? 'Khác'
                : null,
        birthDate: formatDateOnly(profile.date_of_birth),
        occupation: profile.occupation,
        ethnicity: profile.ethnicity,
        nationality: profile.nationality,
        province: profile.province,
        district: profile.district,
        ward: profile.ward,
        addressDetail: profile.address_detail,
        emergencyContact: profile.emergency_contact,
        relationshipToUser: profile.relationship_to_user,
        isPrimary: profile.is_primary === 1,
      })),
    );
  }
}


