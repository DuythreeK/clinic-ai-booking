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
    @Query('facilityId') facilityId?: string,
  ) {
    return this.doctorsService.getDoctors(
      Number(page || 1),
      Number(limit || 10),
      search,
      specialtyId,
      facilityId,
    );
  }

  @Get('profile/current')
  @UseGuards(JwtGuard)
  @Roles(UserRole.doctor)
  async getCurrentDoctorProfile(@CurrentUser('sub') userId: string) {
    return this.doctorsService.getDoctors(1, 100).then((response) =>
      response.data.items.find((doctor) => String(doctor.id) === userId) ?? null,
    );
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
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateDoctorDto,
  ) {
    return this.doctorsService.createDoctor(userId, dto);
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
