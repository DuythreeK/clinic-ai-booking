import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { UpdateUserDto } from './dto/user.dto';
import { MobileProfileDto, UpdateMobileProfileDto } from './dto/mobile-profile.dto';
import { okResponse } from '@/common/utils/api-response';
import { formatDateOnly, splitFullName, toNumberId } from '@/common/utils/formatters';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  private toBigIntId(id: string): bigint {
    return BigInt(id);
  }

  private toCurrentUserResponse(user: any) {
    return {
      id: toNumberId(user.user_id),
      fullName: user.full_name,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatar_url,
      status: user.status,
    };
  }

  private mapGender(gender?: string | null) {
    if (!gender) return null;
    if (gender === 'male') return 'Nam';
    if (gender === 'female') return 'Nữ';
    return 'Khác';
  }

  private toMobileProfileResponse(user: any, profile?: any): MobileProfileDto {
    const name = splitFullName(user.full_name);

    return {
      userId: toNumberId(user.user_id)!,
      profileId: profile ? toNumberId(profile.patient_id) : null,
      ecoreId: `PF-${toNumberId(profile?.patient_id ?? user.user_id)}`,
      username: user.email.split('@')[0],
      fullName: user.full_name,
      firstName: name.firstName,
      lastName: name.lastName,
      email: user.email,
      phone: profile?.phone_number ?? user.phone,
      dateOfBirth: formatDateOnly(profile?.date_of_birth),
      gender: this.mapGender(profile?.gender),
      city: profile?.province ?? null,
      district: profile?.district ?? null,
      ward: profile?.ward ?? null,
      address: profile?.address_detail ?? null,
      occupation: profile?.occupation ?? null,
      emergencyContact: profile?.emergency_contact ?? null,
      citizenId: null,
      nationality: profile?.nationality ?? null,
      ethnicity: profile?.ethnicity ?? null,
      relationshipToUser: profile?.relationship_to_user ?? null,
      avatarUrl: user.avatar_url,
    };
  }

  async getUserById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { user_id: this.toBigIntId(id) },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return okResponse('Get current user successfully', this.toCurrentUserResponse(user));
  }

  async getMobileProfile(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { user_id: this.toBigIntId(id) },
      include: {
        patient_profiles: {
          where: { is_primary: 1 },
          take: 1,
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return okResponse(
      'Get mobile profile successfully',
      this.toMobileProfileResponse(user, user.patient_profiles[0]),
    );
  }

  async updateUser(id: string, dto: UpdateUserDto) {
    const existing = await this.prisma.user.findUnique({
      where: { user_id: this.toBigIntId(id) },
    });

    if (!existing) {
      throw new NotFoundException('User not found');
    }

    const user = await this.prisma.user.update({
      where: { user_id: this.toBigIntId(id) },
      data: {
        full_name: dto.fullName,
        phone: dto.phone,
        avatar_url: dto.avatarUrl,
      },
    });

    return okResponse('Update profile successfully', {
      id: toNumberId(user.user_id),
      fullName: user.full_name,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatar_url,
    });
  }

  async updateMobileProfile(id: string, dto: UpdateMobileProfileDto) {
    const userId = this.toBigIntId(id);
    const existing = await this.prisma.user.findUnique({
      where: { user_id: userId },
      include: {
        patient_profiles: {
          where: { is_primary: 1 },
          take: 1,
        },
      },
    });

    if (!existing) {
      throw new NotFoundException('User not found');
    }

    const genderMap: Record<string, 'male' | 'female' | 'other'> = {
      Nam: 'male',
      Nữ: 'female',
      Khác: 'other',
    };

    const [user, profile] = await this.prisma.$transaction(async (tx) => {
      const updatedUser = await tx.user.update({
        where: { user_id: userId },
        data: {
          full_name: dto.fullName ?? existing.full_name,
          phone: dto.phone ?? existing.phone,
          avatar_url: dto.avatarUrl ?? existing.avatar_url,
        },
      });

      const currentProfile = existing.patient_profiles[0];
      let updatedProfile = currentProfile;

      if (currentProfile) {
        updatedProfile = await tx.patientProfile.update({
          where: { patient_id: currentProfile.patient_id },
          data: {
            full_name: dto.fullName ?? currentProfile.full_name,
            phone_number: dto.phone ?? currentProfile.phone_number,
            date_of_birth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : undefined,
            gender: dto.gender ? genderMap[dto.gender] ?? undefined : undefined,
            occupation: dto.occupation ?? currentProfile.occupation,
            nationality: dto.nationality ?? currentProfile.nationality,
            ethnicity: dto.ethnicity ?? currentProfile.ethnicity,
            province: dto.city ?? currentProfile.province,
            district: dto.district ?? currentProfile.district,
            ward: dto.ward ?? currentProfile.ward,
            address_detail: dto.address ?? currentProfile.address_detail,
            emergency_contact: dto.emergencyContact ?? currentProfile.emergency_contact,
            relationship_to_user:
              dto.relationshipToUser ?? currentProfile.relationship_to_user,
          },
        });
      }

      return [updatedUser, updatedProfile];
    });

    return okResponse(
      'Update mobile profile successfully',
      this.toMobileProfileResponse(user, profile),
    );
  }
}
