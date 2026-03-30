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

  /**
   * Pre-visit Summary: Generate summary for doctor before appointment
   * TODO: Replace with actual LLM call
   */
  async generatePrevisitSummary(
    dto: PrevisitSummaryRequestDto,
  ): Promise<PrevisitSummaryResultDto> {
    // MOCK IMPLEMENTATION
    const summary: string[] = [
      `• Bệnh nhân: ${dto.patientData.firstName || 'Unknown'} ${dto.patientData.lastName || ''}`,
      `• Tuổi: ${dto.patientData.age || 'N/A'}`,
      `• Tình trạng sức khỏe chung: Tương đối ổn định`,
      '• Bệnh sử: Không có bệnh nền đáng kể',
      '• Dị ứng: Không rõ',
    ];

    const result: PrevisitSummaryResultDto = {
      summary,
      keyPoints: [
        'Chuẩn bị thăm khám chi tiết',
        'Xem xét cận lâm sàng nếu cần',
        'Tập trung vào các triệu chứng chính',
      ],
      recommendations: [
        'Kỹ thuật khám toàn diện',
        'Hỏi tiền sử y tế chi tiết',
        'Xem xét chỉ định xét nghiệm phù hợp',
      ],
    };

    // Save to appointment if appointmentId provided
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
}
