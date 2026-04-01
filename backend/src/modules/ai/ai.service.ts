import {
  BadRequestException,
  GatewayTimeoutException,
  Injectable,
  InternalServerErrorException,
  Logger,
  OnModuleInit,
  ServiceUnavailableException,
} from '@nestjs/common';
import { GoogleGenerativeAI } from '@google/generative-ai';
import {
  TriageRequestDto,
  TriageResultDto,
  PrevisitSummaryResultDto,
  PrevisitSummaryRequestDto,
} from './dto/ai.dto';
import { PrismaService } from '@/prisma/prisma.service';
import { TriageStatus, UrgencyLevel } from '@prisma/client';

@Injectable()
export class AiService implements OnModuleInit {
  private readonly logger = new Logger(AiService.name);
  private readonly configuredModel = process.env.GEMINI_MODEL || 'gemini-flash-latest';
  private readonly modelName =
    this.configuredModel === 'gemini-1.5-flash'
      ? 'gemini-flash-latest'
      : this.configuredModel;
  private readonly requestTimeoutMs = Number(process.env.GEMINI_TIMEOUT_MS || 20000);
  private readonly systemPrompt = [
    'Ban la y ta phan luong (triage nurse) cho phong kham.',
    'Nhiem vu: phan tich trieu chung benh nhan va phan loai muc do uu tien.',
    'Bat buoc tra ve DUY NHAT mot JSON hop le, khong them giai thich, khong markdown, khong code block.',
    'JSON bat buoc dung cau truc:',
    '{"urgency":"Emergency|Urgent|Routine","specialty":"<ten chuyen khoa>","reasoning":"<giai thich ngan gon bang tieng Viet>"}',
    'Quy tac muc do:',
    '- Emergency: nguy co de doa tinh mang/can cap cuu ngay.',
    '- Urgent: can kham som trong 24-48 gio.',
    '- Routine: chua co dau hieu cap cuu, co the kham thong thuong.',
    'reasoning phai viet bang tieng Viet, ngan gon, ro rang, khong qua 2 cau.',
  ].join('\n');

  constructor(private prisma: PrismaService) {}

  /**
   * Initialize service and log configuration
   */
  async onModuleInit() {
    this.logger.log(
      `AiService initialized. Model: ${this.modelName}, Timeout: ${this.requestTimeoutMs}ms`,
    );
    if (this.configuredModel !== this.modelName) {
      this.logger.warn(
        `Configured model '${this.configuredModel}' is unavailable for this API key. Using '${this.modelName}' instead.`,
      );
    }
  }

  async triageSymptoms(userId: string, symptoms: string): Promise<TriageResultDto> {
    this.logger.log(
      `Triage request received userId=${userId}, symptomsLength=${symptoms?.length ?? 0}`,
    );

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      this.logger.error('GEMINI_API_KEY is missing.');
      throw new ServiceUnavailableException(
        'AI service is not configured. Missing GEMINI_API_KEY.',
      );
    }

    const sanitizedSymptoms = symptoms.trim();
    if (!sanitizedSymptoms) {
      this.logger.warn(`Empty symptoms after sanitization for userId=${userId}`);
      throw new BadRequestException('Symptoms are required for triage.');
    }

    const gemini = new GoogleGenerativeAI(apiKey);

    let aiResult: TriageResultDto;

    try {
      this.logger.debug(
        `Calling Gemini model=${this.modelName}, timeoutMs=${this.requestTimeoutMs}`,
      );

      const aiResponse = await this.generateWithModel(
        gemini,
        `${this.systemPrompt}\n\n` +
          `Trieu chung benh nhan: ${sanitizedSymptoms}\n` +
          'Hay tra ve JSON theo dung schema da yeu cau.',
      );

      const text = aiResponse.response.text();
      this.logger.debug(`Gemini raw response length=${text.length}`);
      aiResult = this.parseAndValidateTriageJson(text);
      this.logger.log(
        `Triage parsed successfully urgency=${aiResult.urgency}, specialty=${aiResult.specialty}`,
      );
    } catch (error) {
      if (error instanceof GatewayTimeoutException) {
        this.logger.error(
          `Gemini timeout userId=${userId}, timeoutMs=${this.requestTimeoutMs}`,
        );
        throw error;
      }

      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Gemini triage call failed userId=${userId}, error=${message}`);

      throw new ServiceUnavailableException(
        'AI triage is temporarily unavailable. Please retry in a moment.',
      );
    }

    try {
      await this.prisma.aiTriageSession.create({
        data: {
          user_id: this.toBigIntId(userId),
          status: TriageStatus.COMPLETED,
          symptoms_input: sanitizedSymptoms,
          urgency_level: this.mapUrgencyToDb(aiResult.urgency),
          recommended_specialties: [aiResult.specialty],
          pre_visit_summary: {
            reasoning: aiResult.reasoning,
          },
          total_messages: 1,
          is_completed: 1,
        },
      });
      this.logger.log(`Triage session saved for userId=${userId}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to save triage session userId=${userId}, error=${message}`);
      throw new InternalServerErrorException(
        'Triage generated but failed to save the result. Please retry.',
      );
    }

    return aiResult;
  }

  // backend/src/modules/ai/ai.service.ts

private async generateWithModel(gemini: GoogleGenerativeAI, text: string) {
  const startTime = Date.now(); // Bấm giờ
  this.logger.debug(`[AI] Bắt đầu gọi Gemini model=${this.modelName}...`);

  const model = gemini.getGenerativeModel({ model: this.modelName });

  try {
    // 1. Gỡ bỏ Promise.race, gọi thẳng model để nó chạy đến khi xong
    const result = await model.generateContent({
      contents: [{ role: 'user', parts: [{ text }] }],
      generationConfig: {
        temperature: 0.2,
      },
    });

    const duration = (Date.now() - startTime) / 1000; // Tính số giây
    this.logger.log(`[AI] Gemini phản hồi sau ${duration}s - Thành công!`);
    
    return result;

  } catch (error) {
    const duration = (Date.now() - startTime) / 1000;
    const message = error instanceof Error ? error.message : String(error);
    this.logger.error(`[AI] Gemini tạch sau ${duration}s. Lỗi: ${message}`);
    throw error;
  }
}

  async generatePrevisitSummary(
    dto: PrevisitSummaryRequestDto,
  ): Promise<PrevisitSummaryResultDto> {
    const llmResult = await this.tryLlmPrevisitSummary(dto);
    const result = llmResult ?? this.mockPrevisitSummary(dto);

    if (dto.appointmentId) {
      const appointmentId = BigInt(dto.appointmentId);
      await this.prisma.appointment.update({
        where: { appointment_id: appointmentId },
        data: {
          note: JSON.stringify(result),
        },
      });
    }

    return result;
  }

  private parseAndValidateTriageJson(rawText: string): TriageResultDto {
    const normalized = rawText
      .trim()
      .replace(/^```json\s*/i, '')
      .replace(/^```\s*/i, '')
      .replace(/\s*```$/, '');

    let parsed: unknown;
    try {
      parsed = JSON.parse(normalized);
    } catch {
      this.logger.error(`Invalid AI JSON payload: ${normalized.slice(0, 300)}`);
      throw new InternalServerErrorException('AI returned invalid JSON format.');
    }

    const payload = parsed as Partial<TriageResultDto>;
    const urgency = payload.urgency;
    const specialty = payload.specialty;
    const reasoning = payload.reasoning;

    if (!urgency || !['Emergency', 'Urgent', 'Routine'].includes(urgency)) {
      throw new InternalServerErrorException('AI returned an invalid urgency value.');
    }

    if (!specialty || typeof specialty !== 'string' || !specialty.trim()) {
      throw new InternalServerErrorException('AI returned an invalid specialty value.');
    }

    if (!reasoning || typeof reasoning !== 'string' || !reasoning.trim()) {
      throw new InternalServerErrorException('AI returned an invalid reasoning value.');
    }

    return {
      urgency,
      specialty: specialty.trim(),
      reasoning: reasoning.trim(),
    };
  }

  private mapUrgencyToDb(urgency: TriageResultDto['urgency']): UrgencyLevel {
    if (urgency === 'Emergency') {
      return UrgencyLevel.URGENT;
    }

    if (urgency === 'Urgent') {
      return UrgencyLevel.SOON;
    }

    return UrgencyLevel.NORMAL;
  }

  private toBigIntId(value: string): bigint {
    try {
      return BigInt(value);
    } catch {
      throw new BadRequestException('Invalid user id in token.');
    }
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
