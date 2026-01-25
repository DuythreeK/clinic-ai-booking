import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { DoctorsService } from './doctors.service';
import { CreateDoctorDto, UpdateDoctorDto, ApproveDoctorDto } from './dto/doctor.dto';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';

@Controller('doctors')
export class DoctorsController {
  constructor(private doctorsService: DoctorsService) {}

  @Get()
  async getDoctors(
    @Query('specialtyId') specialtyId?: string,
    @Query('approved') approved?: string,
  ) {
    const isApproved = approved === 'true' ? true : approved === 'false' ? false : undefined;
    return this.doctorsService.getDoctors(specialtyId, isApproved);
  }

  @Get('clinic/:clinicId')
  async getDoctorsByClinic(@Param('clinicId') clinicId: string) {
    return this.doctorsService.getDoctorsByClinic(clinicId);
  }

  @Get(':id')
  async getDoctorById(@Param('id') id: string) {
    return this.doctorsService.getDoctorById(id);
  }

  @Get('profile/current')
  @UseGuards(JwtGuard)
  @Roles(UserRole.DOCTOR)
  async getCurrentDoctorProfile(@CurrentUser('sub') userId: string) {
    return this.doctorsService.getDoctorByUserId(userId);
  }

  @Post()
  @UseGuards(JwtGuard)
  @Roles(UserRole.DOCTOR)
  async createDoctor(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateDoctorDto,
  ) {
    return this.doctorsService.createDoctor(userId, dto);
  }

  @Patch(':id')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.DOCTOR)
  async updateDoctor(
    @Param('id') id: string,
    @Body() dto: UpdateDoctorDto,
    @CurrentUser('sub') userId: string,
  ) {
    const doctor = await this.doctorsService.getDoctorById(id);
    if (doctor.userId !== userId) {
      throw new Error('You can only update your own profile');
    }
    return this.doctorsService.updateDoctor(id, dto);
  }

  @Patch(':id/approve')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async approveDoctor(
    @Param('id') id: string,
    @Body() dto: ApproveDoctorDto,
  ) {
    return this.doctorsService.approveDoctor(id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async deleteDoctor(@Param('id') id: string) {
    return this.doctorsService.deleteDoctor(id);
  }
}
