import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { CreatePatientProfileDto } from './dto/patient.dto';
import { okResponse } from '@/common/utils/api-response';

@Injectable()
export class PatientsService {
  constructor(private prisma: PrismaService) {}

  private toBigIntId(id: string): bigint {
    return BigInt(id);
  }

  private toResponse(profile: any) {
    return {
      patientId: profile.patientId.toString(),
      userId: profile.userId.toString(),
      fullName: profile.fullName,
      phoneNumber: profile.phone_number,
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
      createdAt: profile.createdAt,
      updatedAt: profile.updated_at,
    };
  }

  async createPatientProfile(userId: string, dto: CreatePatientProfileDto) {
    const profile = await this.prisma.patientProfile.create({
      data: {
        userId: this.toBigIntId(userId),
        fullName: dto.fullName,
        phone_number: dto.phoneNumber,
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
        is_primary: dto.isPrimary === undefined ? undefined : dto.isPrimary ? 1 : 0,
      },
    });

    return okResponse(
      'Create patient profile successfully',
      {
        id: Number(profile.patientId),
        fullName: profile.fullName,
        phoneNumber: profile.phone_number,
        gender: profile.gender,
        dateOfBirth: profile.date_of_birth,
        occupation: profile.occupation,
        ethnicity: profile.ethnicity,
        nationality: profile.nationality,
        province: profile.province,
        district: profile.district,
        ward: profile.ward,
        addressDetail: profile.address_detail,
        relationshipToUser: profile.relationship_to_user,
        isPrimary: profile.is_primary === 1,
      },
    );
  }

  async getPatientProfiles(userId: string) {
    const profiles = await this.prisma.patientProfile.findMany({
      where: { userId: this.toBigIntId(userId) },
      orderBy: [{ is_primary: 'desc' }, { createdAt: 'desc' }],
    });

    return okResponse(
      'Get patient profiles successfully',
      profiles.map((profile) => ({
        id: Number(profile.patientId),
        fullName: profile.fullName,
        phoneNumber: profile.phone_number,
        gender: profile.gender,
        dateOfBirth: profile.date_of_birth,
        isPrimary: profile.is_primary === 1,
      })),
    );
  }
}
