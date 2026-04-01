import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { DoctorReviewsService } from './doctor-reviews.service';
import { CreateDoctorReviewDto } from './dto/doctor-review.dto';

@Controller('doctor-reviews')
@UseGuards(JwtGuard)
export class DoctorReviewsController {
  constructor(private doctorReviewsService: DoctorReviewsService) {}

  @Post()
  async create(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateDoctorReviewDto,
  ) {
    return this.doctorReviewsService.createReview(userId, dto);
  }
}
