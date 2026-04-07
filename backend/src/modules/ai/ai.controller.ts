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
    @CurrentUser('sub') userId: string,
    @Body() dto: TriageRequestDto,
  ) {
    this.logger.log(
      `POST /ai/triage userId=${userId}, symptomsLength=${dto.symptoms?.length ?? 0}`,
    );

    try {
      return await this.aiService.triageSymptoms(userId, dto.symptoms);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`POST /ai/triage failed userId=${userId}, error=${message}`);
      throw error;
    }
  }

  @Post('previsit-summary')
  async previsitSummary(@Body() dto: PrevisitSummaryRequestDto) {
    return this.aiService.generatePrevisitSummary(dto);
  }
}
