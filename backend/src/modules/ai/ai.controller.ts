import { Controller, Post, Body, Logger, UseGuards } from '@nestjs/common';
import { AiService } from './ai.service';
import { TriageRequestDto, PrevisitSummaryRequestDto } from './dto/ai.dto';
import { JwtGuard } from '@/common/guards/jwt.guard';
import { CurrentUser } from '@/common/decorators/current-user.decorator';

@Controller('ai')
@UseGuards(JwtGuard)
export class AiController {
  private readonly logger = new Logger(AiController.name);

  constructor(private aiService: AiService) {}

  @Post('triage')
  async triage(
    @CurrentUser('sub') user_id: string,
    @Body() dto: TriageRequestDto,
  ) {
    this.logger.log(
      `POST /ai/triage user_id=${user_id}, symptomsLength=${dto.symptoms?.length ?? 0}`,
    );

    try {
      return await this.aiService.triageSymptoms(user_id, dto.symptoms);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`POST /ai/triage failed user_id=${user_id}, error=${message}`);
      throw error;
    }
  }

  @Post('previsit-summary')
  async previsitSummary(@Body() dto: PrevisitSummaryRequestDto) {
    return this.aiService.generatePrevisitSummary(dto);
  }
}
