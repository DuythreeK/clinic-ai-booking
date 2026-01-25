import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { ClinicsService } from './clinics.service';
import { CreateClinicDto, UpdateClinicDto } from './dto/clinic.dto';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@Controller('clinics')
export class ClinicsController {
  constructor(private clinicsService: ClinicsService) {}

  @Get()
  async getClinics() {
    return this.clinicsService.getClinics();
  }

  @Get(':id')
  async getClinicById(@Param('id') id: string) {
    return this.clinicsService.getClinicById(id);
  }

  @Post()
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async createClinic(@Body() dto: CreateClinicDto) {
    return this.clinicsService.createClinic(dto);
  }

  @Patch(':id')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async updateClinic(
    @Param('id') id: string,
    @Body() dto: UpdateClinicDto,
  ) {
    return this.clinicsService.updateClinic(id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async deleteClinic(@Param('id') id: string) {
    return this.clinicsService.deleteClinic(id);
  }
}
