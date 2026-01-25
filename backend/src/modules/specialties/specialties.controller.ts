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
import { SpecialtiesService } from './specialties.service';
import { CreateSpecialtyDto, UpdateSpecialtyDto } from './dto/specialty.dto';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@Controller('specialties')
export class SpecialtiesController {
  constructor(private specialtiesService: SpecialtiesService) {}

  @Get()
  async getSpecialties() {
    return this.specialtiesService.getSpecialties();
  }

  @Get(':id')
  async getSpecialtyById(@Param('id') id: string) {
    return this.specialtiesService.getSpecialtyById(id);
  }

  @Post()
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async createSpecialty(@Body() dto: CreateSpecialtyDto) {
    return this.specialtiesService.createSpecialty(dto);
  }

  @Patch(':id')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async updateSpecialty(
    @Param('id') id: string,
    @Body() dto: UpdateSpecialtyDto,
  ) {
    return this.specialtiesService.updateSpecialty(id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async deleteSpecialty(@Param('id') id: string) {
    return this.specialtiesService.deleteSpecialty(id);
  }
}
