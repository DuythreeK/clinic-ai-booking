import { Injectable, Logger } from '@nestjs/common';
import {
  PrevisitSummaryRequestDto,
  PrevisitSummaryResultDto,
  TriageRequestDto,
  TriageResultDto,
} from './dto/ai.dto';
import { PrismaService } from '@/prisma/prisma.service';
import { UrgencyLevel } from '@prisma/client';

type LlmProvider = 'openai' | 'anthropic';

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private readonly provider = (process.env.AI_PROVIDER || 'openai') as LlmProvider;
  private readonly openaiApiKey = process.env.OPENAI_API_KEY;
  private readonly anthropicApiKey = process.env.ANTHROPIC_API_KEY;
  private readonly openaiModel = process.env.OPENAI_MODEL || 'gpt-4o-mini';
  private readonly anthropicModel =
    process.env.ANTHROPIC_MODEL || 'claude-3-5-sonnet-20240620';

  constructor(private prisma: PrismaService) {}

  async performTriage(dto: TriageRequestDto): Promise<TriageResultDto> {
    const llmResult = await this.tryLlmTriage(dto);
    if (llmResult) {
      return llmResult;
    }

    return this.mockTriage(dto);
  }

  async generatePrevisitSummary(
    dto: PrevisitSummaryRequestDto,
  ): Promise<PrevisitSummaryResultDto> {
    const llmResult = await this.tryLlmPrevisitSummary(dto);
    const result = llmResult ?? this.mockPrevisitSummary(dto);

    if (dto.appointmentId) {
      await this.prisma.appointment.update({
        where: { id: dto.appointmentId },
        data: {
          previsitSummary: JSON.stringify(result),
        },
      });
    }

    return result;
  }

  validateTriageOutput(data: any): boolean {
    if (!data?.recommended_specialties || !Array.isArray(data.recommended_specialties)) {
      return false;
    }

    if (!['THUONG', 'NEN_DI_SOM', 'KHAN'].includes(data.urgency_level)) {
      return false;
    }

    if (!data.follow_up_questions || !Array.isArray(data.follow_up_questions)) {
      return false;
    }

    if (!data.disclaimer || typeof data.disclaimer !== 'string') {
      return false;
    }

    return true;
  }

  private async tryLlmTriage(dto: TriageRequestDto): Promise<TriageResultDto | null> {
    const system = [
      'You are a clinical triage assistant for a clinic booking app.',
      'Return ONLY valid JSON with the following keys:',
      'recommended_specialties (string[]), urgency_level (THUONG|NEN_DI_SOM|KHAN),',
      'follow_up_questions (string[]), disclaimer (string).',
      'Use Vietnamese for specialties and questions when appropriate.',
    ].join(' ');
    const user = JSON.stringify({ task: 'triage', input: dto });

    const raw = await this.callLlm(system, user, 600);
    if (!raw) {
      return null;
    }

    const parsed = this.extractJson(raw);
    if (!parsed) {
      return null;
    }

    const normalized = {
      recommended_specialties: parsed.recommended_specialties,
      urgency_level: String(parsed.urgency_level || '').toUpperCase(),
      follow_up_questions: parsed.follow_up_questions,
      disclaimer: parsed.disclaimer,
    };

    if (!this.validateTriageOutput(normalized)) {
      return null;
    }

    return normalized as TriageResultDto;
  }

  private async tryLlmPrevisitSummary(
    dto: PrevisitSummaryRequestDto,
  ): Promise<PrevisitSummaryResultDto | null> {
    const system = [
      'You are a medical assistant preparing a pre-visit summary for a doctor.',
      'Return ONLY valid JSON with keys: summary (string[]), keyPoints (string[]),',
      'recommendations (string[]). Use Vietnamese for bullets when appropriate.',
    ].join(' ');
    const user = JSON.stringify({ task: 'previsit_summary', input: dto });

    const raw = await this.callLlm(system, user, 700);
    if (!raw) {
      return null;
    }

    const parsed = this.extractJson(raw);
    if (!parsed) {
      return null;
    }

    if (
      !Array.isArray(parsed.summary) ||
      !Array.isArray(parsed.keyPoints) ||
      !Array.isArray(parsed.recommendations)
    ) {
      return null;
    }

    return parsed as PrevisitSummaryResultDto;
  }

  private async callLlm(
    system: string,
    user: string,
    maxTokens: number,
  ): Promise<string | null> {
    try {
      if (this.provider === 'anthropic') {
        if (!this.anthropicApiKey) {
          this.logger.warn('ANTHROPIC_API_KEY is missing; falling back to mock.');
          return null;
        }
        return await this.callAnthropic(system, user, maxTokens);
      }

      if (!this.openaiApiKey) {
        this.logger.warn('OPENAI_API_KEY is missing; falling back to mock.');
        return null;
      }
      return await this.callOpenAi(system, user, maxTokens);
    } catch (error) {
      this.logger.warn(`LLM call failed; falling back to mock. ${String(error)}`);
      return null;
    }
  }

  private async callOpenAi(
    system: string,
    user: string,
    maxTokens: number,
  ): Promise<string> {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: this.openaiModel,
        temperature: 0.2,
        max_tokens: maxTokens,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: user },
        ],
      }),
    });

    const json = (await response.json()) as any;
    if (!response.ok) {
      throw new Error(
        `OpenAI error: ${json?.error?.message || response.statusText}`,
      );
    }

    return json?.choices?.[0]?.message?.content || '';
  }

  private async callAnthropic(
    system: string,
    user: string,
    maxTokens: number,
  ): Promise<string> {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': this.anthropicApiKey as string,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: this.anthropicModel,
        system,
        max_tokens: maxTokens,
        temperature: 0.2,
        messages: [{ role: 'user', content: user }],
      }),
    });

    const json = (await response.json()) as any;
    if (!response.ok) {
      throw new Error(
        `Anthropic error: ${json?.error?.message || response.statusText}`,
      );
    }

    return json?.content?.[0]?.text || '';
  }

  private extractJson(text: string): any | null {
    if (!text) {
      return null;
    }

    const first = text.indexOf('{');
    const last = text.lastIndexOf('}');
    if (first === -1 || last === -1 || last <= first) {
      return null;
    }

    const slice = text.slice(first, last + 1);
    try {
      return JSON.parse(slice);
    } catch {
      return null;
    }
  }

  private mockTriage(dto: TriageRequestDto): TriageResultDto {
    const symptomString = dto.symptoms.join(' ').toLowerCase();

    let recommendedSpecialties = ['General'];
    let urgencyLevel: UrgencyLevel = UrgencyLevel.THUONG;

    if (symptomString.includes('chest') || symptomString.includes('nguc')) {
      recommendedSpecialties = ['Cardiology', 'General'];
      urgencyLevel = UrgencyLevel.KHAN;
    } else if (symptomString.includes('fever') || symptomString.includes('sot')) {
      recommendedSpecialties = ['General', 'Pediatrics'];
      urgencyLevel = UrgencyLevel.NEN_DI_SOM;
    } else if (symptomString.includes('anxiety') || symptomString.includes('lo')) {
      recommendedSpecialties = ['Mental Health'];
      urgencyLevel = UrgencyLevel.THUONG;
    } else if (symptomString.includes('skin') || symptomString.includes('rash')) {
      recommendedSpecialties = ['Dermatology'];
      urgencyLevel = UrgencyLevel.THUONG;
    }

    return {
      recommended_specialties: recommendedSpecialties,
      urgency_level: urgencyLevel,
      follow_up_questions: [
        'Symptoms started when?',
        'How severe are the symptoms?',
        'Any medications taken?',
      ],
      disclaimer:
        'This is an automated suggestion. Please consult a doctor for diagnosis.',
    };
  }

  private mockPrevisitSummary(
    dto: PrevisitSummaryRequestDto,
  ): PrevisitSummaryResultDto {
    const firstName = dto.patientData?.firstName || 'Unknown';
    const lastName = dto.patientData?.lastName || '';
    const age = dto.patientData?.age || 'N/A';

    return {
      summary: [
        `Patient: ${firstName} ${lastName}`.trim(),
        `Age: ${age}`,
        'General health: stable',
      ],
      keyPoints: ['Review chief complaint', 'Check past medical history'],
      recommendations: ['Consider basic labs if needed'],
    };
  }
}
