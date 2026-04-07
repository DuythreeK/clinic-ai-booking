import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '@/common/decorators/roles.decorator';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { CreateDoctorDto, DoctorListQueryDto, UpdateDoctorDto } from './dto/doctor.dto';
import { DoctorsService } from './doctors.service';

@Controller('admin/doctors')
@UseGuards(JwtGuard, RolesGuard)
export class DoctorsController {
  constructor(private readonly doctorsService: DoctorsService) {}

  @Get()
  @Roles(UserRole.admin, UserRole.receptionist, UserRole.doctor)
  findAll(@Query() query: DoctorListQueryDto) {
    return this.doctorsService.findAll(query);
  }

  @Get(':id')
  @Roles(UserRole.admin, UserRole.receptionist, UserRole.doctor)
  findOne(@Param('id') id: string) {
    return this.doctorsService.findOne(id);
  }

  @Post()
  @Roles(UserRole.admin)
  create(@Body() dto: CreateDoctorDto) {
    return this.doctorsService.create(dto);
  }

  @Patch(':id')
  @Roles(UserRole.admin)
  update(@Param('id') id: string, @Body() dto: UpdateDoctorDto) {
    return this.doctorsService.update(id, dto);
  }
}
