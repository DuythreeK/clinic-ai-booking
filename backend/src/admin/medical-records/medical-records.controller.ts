import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '@/common/decorators/roles.decorator';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import {
  CreateMedicalRecordDto,
  MedicalRecordListQueryDto,
  UpdateMedicalRecordDto,
} from './dto/medical-record.dto';
import { MedicalRecordsService } from './medical-records.service';

@Controller('admin/medical-records')
@UseGuards(JwtGuard, RolesGuard)
export class MedicalRecordsController {
  constructor(private readonly medicalRecordsService: MedicalRecordsService) {}

  @Get()
  @Roles(UserRole.admin, UserRole.receptionist, UserRole.doctor)
  findAll(@Query() query: MedicalRecordListQueryDto) {
    return this.medicalRecordsService.findAll(query);
  }

  @Get(':id')
  @Roles(UserRole.admin, UserRole.receptionist, UserRole.doctor)
  findOne(@Param('id') id: string) {
    return this.medicalRecordsService.findOne(id);
  }

  @Post()
  @Roles(UserRole.admin, UserRole.doctor)
  create(@Body() dto: CreateMedicalRecordDto) {
    return this.medicalRecordsService.create(dto);
  }

  @Patch(':id')
  @Roles(UserRole.admin, UserRole.doctor)
  update(@Param('id') id: string, @Body() dto: UpdateMedicalRecordDto) {
    return this.medicalRecordsService.update(id, dto);
  }

  @Patch(':id/lock')
  @Roles(UserRole.admin, UserRole.doctor)
  lock(@Param('id') id: string) {
    return this.medicalRecordsService.lock(id);
  }
}
