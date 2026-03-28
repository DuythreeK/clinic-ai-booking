import { Injectable } from '@nestjs/common';
import { TriageRequestDto, TriageResultDto, PrevisitSummaryResultDto, PrevisitSummaryRequestDto } from './dto/ai.dto';
import { PrismaService } from '@/prisma/prisma.service';
import { UrgencyLevel } from '@prisma/client';

/**
 * AI Service - Placeholder for LLM integration
 * Currently mocks AI responses, can be replaced with real OpenAI/Anthropic calls
 */
@Injectable()
export class AiService {
  constructor(private prisma: PrismaService) {}

  /**
   * AI Triage: Analyzes symptoms and recommends specialties
   * TODO: Replace with actual LLM call (OpenAI, Anthropic, etc.)
   */
  async performTriage(dto: TriageRequestDto): Promise<TriageResultDto> {
    // MOCK IMPLEMENTATION
    const specialtyMap: Record<string, string[]> = {
      'headache|đau_đầu': ['Tổng quát', 'Tâm thần'],
      'fever|sốt': ['Tổng quát', 'Nhi khoa'],
      'chest_pain|đau_ngực': ['Tim mạch', 'Tổng quát'],
      'skin_rash|phát_ban': ['Da liễu'],
      'anxiety|lo_âu': ['Tâm thần'],
    };

    let recommendedSpecialties = ['Tổng quát'];
    let urgencyLevel: UrgencyLevel = UrgencyLevel.NORMAL;

    // Simple keyword matching for demo
    const symptomString = dto.symptoms.join(' ').toLowerCase();

    if (symptomString.includes('chest') || symptomString.includes('ngực')) {
      recommendedSpecialties = ['Tim mạch', 'Tổng quát'];
      urgencyLevel = UrgencyLevel.URGENT;
    } else if (
      symptomString.includes('fever') ||
      symptomString.includes('sốt')
    ) {
      recommendedSpecialties = ['Tổng quát', 'Nhi khoa'];
      urgencyLevel = UrgencyLevel.SOON;
    } else if (
      symptomString.includes('anxiety') ||
      symptomString.includes('lo_âu')
    ) {
      recommendedSpecialties = ['Tâm thần'];
      urgencyLevel = UrgencyLevel.NORMAL;
    } else if (
      symptomString.includes('skin') ||
      symptomString.includes('rash')
    ) {
      recommendedSpecialties = ['Da liễu'];
      urgencyLevel = UrgencyLevel.NORMAL;
    }

    const result: TriageResultDto = {
      recommended_specialties: recommendedSpecialties,
      urgency_level: urgencyLevel,
      follow_up_questions: [
        'Bạn đã có bất kỳ phương pháp điều trị nào chưa?',
        'Các triệu chứng kéo dài bao lâu?',
        'Bạn đã dùng thuốc gì?',
      ],
      disclaimer:
        'Đây là kết quả phân tích tự động. Vui lòng tư vấn bác sĩ để có chẩn đoán chính xác.',
    };

    return result;
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

  /**
   * Validate and sanitize triage output
   */
  validateTriageOutput(data: any): boolean {
    // Check required fields
    if (
      !data.recommended_specialties ||
      !Array.isArray(data.recommended_specialties)
    ) {
      return false;
    }

    if (
      !['NORMAL', 'SOON', 'URGENT'].includes(data.urgency_level)
    ) {
      return false;
    }

    if (
      !data.follow_up_questions ||
      !Array.isArray(data.follow_up_questions)
    ) {
      return false;
    }

    return true;
  }
}
