import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { AiService } from './ai.service';
import { TriageRequestDto, PrevisitSummaryRequestDto } from './dto/ai.dto';
import { JwtGuard } from '@/common/guards/jwt.guard';

@Controller('ai')
@UseGuards(JwtGuard)
export class AiController {
  constructor(private aiService: AiService) {}

  @Post('triage')
  async triage(@Body() dto: TriageRequestDto) {
    return this.aiService.performTriage(dto);
  }

  @Post('previsit-summary')
  async previsitSummary(@Body() dto: PrevisitSummaryRequestDto) {
    return this.aiService.generatePrevisitSummary(dto);
  }
}
