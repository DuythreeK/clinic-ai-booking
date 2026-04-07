import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import {
  PrevisitSummaryRequestDto,
  PrevisitSummaryResultDto,
  TriageResultDto,
} from './dto/ai.dto';

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);

  async triageSymptoms(userId: string, symptoms: string): Promise<TriageResultDto> {
    const normalized = symptoms.trim();

    if (!normalized) {
      throw new BadRequestException('Symptoms are required for triage.');
    }

    const lower = normalized.toLowerCase();
    let urgency: TriageResultDto['urgency'] = 'Routine';
    let specialty = 'Tiem chung';
    let reasoning = 'Chua ghi nhan dau hieu khan cap, co the dat lich kham thong thuong.';

    if (
      lower.includes('kho tho') ||
      lower.includes('ngat') ||
      lower.includes('dau nguc') ||
      lower.includes('co giat')
    ) {
      urgency = 'Emergency';
      specialty = 'Cap cuu';
      reasoning = 'Trieu chung co the nguy hiem, can duoc danh gia y te ngay.';
    } else if (
      lower.includes('sot cao') ||
      lower.includes('phat ban') ||
      lower.includes('non') ||
      lower.includes('dau nhieu')
    ) {
      urgency = 'Urgent';
      specialty = 'Noi tong quat';
      reasoning = 'Trieu chung can duoc bac si tham kham som trong 24-48 gio.';
    }

    this.logger.log(`Mock triage generated for userId=${userId}`);

    return {
      urgency,
      specialty,
      reasoning,
    };
  }

  async generatePrevisitSummary(
    dto: PrevisitSummaryRequestDto,
  ): Promise<PrevisitSummaryResultDto> {
    const patientData = dto.patientData ?? {};
    const fullName =
      patientData.fullName ||
      [patientData.firstName, patientData.lastName].filter(Boolean).join(' ') ||
      'Benh nhan';

    return {
      summary: [
        `${fullName} can duoc xac nhan lai thong tin truoc buoi kham.`,
        `So lan kham truoc do: ${dto.previousAppointments?.length ?? 0}.`,
      ],
      keyPoints: [
        'Kiem tra di ung, tien su benh va thuoc dang su dung.',
        'Doi chieu thong tin nguoi benh voi ho so hien co.',
      ],
      recommendations: [
        'Chuan bi giay to ca nhan va ho so benh an lien quan.',
        'Den co so y te truoc gio hen 10-15 phut.',
      ],
    };
  }
}
