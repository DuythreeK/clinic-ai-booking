import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { DoctorsService } from './doctors.service';
import { CreateDoctorDto, UpdateDoctorDto } from './dto/doctor.dto';
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
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('search') search?: string,
    @Query('specialtyId') specialtyId?: string,
    @Query('facility_id') facility_id?: string,
  ) {
    return this.doctorsService.getDoctors(
      Number(page || 1),
      Number(limit || 10),
      search,
      specialtyId,
      facility_id,
    );
  }

  @Get('mobile/featured')
  async getFeaturedDoctors(
    @Query('limit') limit?: string,
    @Query('search') search?: string,
    @Query('specialty') specialty?: string,
  ) {
    return this.doctorsService.getFeaturedDoctors(
      Number(limit || 10),
      search,
      specialty,
    );
  }

  @Get('mobile/my')
  @UseGuards(JwtGuard)
  async getMyDoctors(
    @CurrentUser('sub') user_id: string,
    @Query('search') search?: string,
  ) {
    return this.doctorsService.getMyDoctors(user_id, search);
  }

  @Get('profile/current')
  @UseGuards(JwtGuard)
  @Roles(UserRole.doctor)
  async getCurrentDoctorProfile(@CurrentUser('sub') user_id: string) {
    return this.doctorsService.getDoctorByuser_id(user_id);
  }

  @Get(':id')
  async getDoctorById(@Param('id') id: string) {
    return this.doctorsService.getDoctorById(id);
  }

  @Get(':id/reviews')
  async getDoctorReviews(@Param('id') id: string) {
    return this.doctorsService.getDoctorReviews(id);
  }

  @Post()
  @UseGuards(JwtGuard)
  @Roles(UserRole.doctor)
  async createDoctor(
    @CurrentUser('sub') user_id: string,
    @Body() dto: CreateDoctorDto,
  ) {
    return this.doctorsService.createDoctor(user_id, dto);
  }

  @Patch(':id')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.doctor)
  async updateDoctor(
    @Param('id') id: string,
    @Body() dto: UpdateDoctorDto,
  ) {
    return this.doctorsService.updateDoctor(id, dto);
  }
}
