import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '@/common/decorators/roles.decorator';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import {
  CreateSpecialtyDto,
  SpecialtyListQueryDto,
  UpdateSpecialtyDto,
} from './dto/specialty.dto';
import { SpecialtiesService } from './specialties.service';

@Controller('admin/specialties')
@UseGuards(JwtGuard, RolesGuard)
export class SpecialtiesController {
  constructor(private readonly specialtiesService: SpecialtiesService) {}

  @Get()
  @Roles(UserRole.admin, UserRole.receptionist, UserRole.doctor)
  findAll(@Query() query: SpecialtyListQueryDto) {
    return this.specialtiesService.findAll(query);
  }

  @Get(':id')
  @Roles(UserRole.admin, UserRole.receptionist, UserRole.doctor)
  findOne(@Param('id') id: string) {
    return this.specialtiesService.findOne(id);
  }

  @Post()
  @Roles(UserRole.admin)
  create(@Body() dto: CreateSpecialtyDto) {
    return this.specialtiesService.create(dto);
  }

  @Patch(':id')
  @Roles(UserRole.admin)
  update(@Param('id') id: string, @Body() dto: UpdateSpecialtyDto) {
    return this.specialtiesService.update(id, dto);
  }
}
