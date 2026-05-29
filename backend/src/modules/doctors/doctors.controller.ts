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
  /**
   * GET /doctors
   * Query: page, limit, search, specialtyId, facilityId
   * Trả về danh sách bác sĩ (paginated)
   */
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

  @Get('mobile/featured')
  /**
   * GET /doctors/mobile/featured
   * Query: limit, search, specialty
   * Trả về danh sách bác sĩ nổi bật (mobile)
   */
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
  /**
   * GET /doctors/mobile/my
   * Requires JWT. Trả về các bác sĩ đã tương tác bởi user (appointments/reviews)
   */
  async getMyDoctors(
    @CurrentUser('sub') userId: string,
    @Query('search') search?: string,
  ) {
    return this.doctorsService.getMyDoctors(userId, search);
  }

  @Get('profile/current')
  @UseGuards(JwtGuard)
  @Roles(UserRole.doctor)
  /**
   * GET /doctors/profile/current
   * Requires JWT and role doctor. Trả profile doctor hiện tại theo userId.
   */
  async getCurrentDoctorProfile(@CurrentUser('sub') userId: string) {
    return this.doctorsService.getDoctorByUserId(userId);
  }

  @Get(':id')
  /**
   * GET /doctors/:id
   * Trả về chi tiết bác sĩ theo id
   */
  async getDoctorById(@Param('id') id: string) {
    return this.doctorsService.getDoctorById(id);
  }

  @Get(':id/reviews')
  /**
   * GET /doctors/:id/reviews
   * Trả về các đánh giá hiển thị cho bác sĩ
   */
  async getDoctorReviews(@Param('id') id: string) {
    return this.doctorsService.getDoctorReviews(id);
  }

  @Post()
  @UseGuards(JwtGuard)
  @Roles(UserRole.doctor)
  /**
   * POST /doctors
   * Requires JWT and role doctor. Tạo hồ sơ doctor mới liên kết với user
   */
  async createDoctor(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateDoctorDto,
  ) {
    return this.doctorsService.createDoctor(userId, dto);
  }

  @Patch(':id')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.admin, UserRole.doctor)
  /**
   * PATCH /doctors/:id
   * Requires JWT and role admin/doctor. Cập nhật thông tin bác sĩ
   */
  async updateDoctor(
    @Param('id') id: string,
    @Body() dto: UpdateDoctorDto,
  ) {
    return this.doctorsService.updateDoctor(id, dto);
  }
}
