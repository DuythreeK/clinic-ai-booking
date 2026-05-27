import { BadRequestException, Injectable, InternalServerErrorException, Logger } from '@nestjs/common';
import {
  PrevisitSummaryRequestDto,
  PrevisitSummaryResultDto,
  TriageResultDto,
} from './dto/ai.dto';

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);

  async triageSymptoms(user_id: string, symptoms: string): Promise<TriageResultDto> {
    this.logger.debug(`Bắt đầu quá trình phân tích triệu chứng cho User ID: ${user_id}`);

    const normalized = symptoms.trim();

    if (!normalized || normalized.length < 5) {
      this.logger.warn(`Dữ liệu triệu chứng quá ngắn hoặc rỗng từ User: ${user_id}`);
      throw new BadRequestException('Mô tả triệu chứng quá ngắn. Vui lòng cung cấp thêm chi tiết để AI có thể phân tích chính xác hơn.');
    }

    const lower = normalized.toLowerCase();

    // Khởi tạo giá trị mặc định (Mức độ thông thường)
    let urgency: TriageResultDto['urgency'] = 'Routine';
    let specialty = 'Nội tổng quát';
    let reasoning = 'Dựa trên các triệu chứng bạn cung cấp, hệ thống chưa phát hiện dấu hiệu nguy hiểm ngay lập tức. Bạn có thể đặt lịch khám định kỳ hoặc tư vấn từ xa.';

    try {
      // 1. Kiểm tra mức độ CẤP CỨU (Emergency)
      if (
        lower.includes('kho tho') ||
        lower.includes('ngat') ||
        lower.includes('dau nguc') ||
        lower.includes('co giat') ||
        lower.includes('hon me')
      ) {
        urgency = 'Emergency';
        specialty = 'Hồi sức cấp cứu';
        reasoning = 'CẢNH BÁO: Các triệu chứng bạn đang gặp phải có dấu hiệu đe dọa tính mạng. Vui lòng di chuyển đến cơ sở y tế gần nhất hoặc gọi cấp cứu 115 ngay lập tức.';
      }

      // 2. Kiểm tra mức độ KHẨN CẤP (Urgent)
      else if (
        lower.includes('sot cao') ||
        lower.includes('phat ban') ||
        lower.includes('non') ||
        lower.includes('dau nhieu') ||
        lower.includes('chan thuong')
      ) {
        urgency = 'Urgent';
        specialty = 'Khoa khám bệnh';
        reasoning = 'Triệu chứng của bạn cần được bác sĩ chuyên khoa thăm khám và đánh giá trong vòng 24 giờ tới để tránh biến chứng xấu hơn.';
      }

      // 3. Kiểm tra chuyên khoa TIÊM CHỦNG
      else if (
        lower.includes('tiem chung') ||
        lower.includes('vaccine') ||
        lower.includes('ngua')
      ) {
        urgency = 'Routine';
        specialty = 'Trung tâm Tiêm chủng';
        reasoning = 'Yêu cầu của bạn liên quan đến dịch vụ dự phòng. Bạn có thể chủ động chọn ca khám tại trung tâm tiêm chủng gần nhất.';
      }

      // 4. Kiểm tra chuyên khoa NHI KHOA
      else if (
        lower.includes('tre em') ||
        lower.includes('be') ||
        lower.includes('nhi')
      ) {
        specialty = 'Nhi khoa';
        reasoning = 'Triệu chứng ở trẻ em cần sự theo dõi sát sao từ bác sĩ Nhi. Vui lòng đặt hẹn để được tư vấn lộ trình chăm sóc phù hợp cho bé.';
      }

      this.logger.log(`Hoàn tất phân tích AI cho User ${user_id}. Kết quả: ${urgency} - ${specialty}`);

      return {
        urgency,
        specialty,
        reasoning,
      };
    } catch (error) {
      // Xử lý an toàn kiểu unknown của error bằng toán tử ba ngôi và instanceof
      const errorMessage = error instanceof Error ? error.message : String(error);
      this.logger.error(`Lỗi hệ thống trong quá trình phân tích AI: ${errorMessage}`);
      
      throw new InternalServerErrorException('Dịch vụ phân tích AI đang gặp sự cố tạm thời. Vui lòng thử lại sau ít phút.');
    }

    // Điểm chặn cuối cùng để TypeScript compiler hiểu rằng hàm luôn luôn bẻ luồng bằng Exception nếu không thể return
    throw new InternalServerErrorException('Lỗi luồng xử lý phân tích AI không xác định.');
  }

  async generatePrevisitSummary(
    dto: PrevisitSummaryRequestDto,
  ): Promise<PrevisitSummaryResultDto> {
    this.logger.log(`Đang khởi tạo tóm tắt trước buổi khám cho bệnh nhân.`);

    const patientData = dto.patientData ?? {};
    const full_name =
      patientData.full_name ||
      [patientData.firstName, patientData.lastName].filter(Boolean).join(' ') ||
      'Quý khách';

    return {
      summary: [
        `Hệ thống xác nhận bệnh nhân ${full_name} đã hoàn tất đăng ký thông tin trực tuyến.`,
        `Ghi nhận lịch sử: Bệnh nhân đã thực hiện ${dto.previousAppointments?.length ?? 0} lần thăm khám trước đây tại hệ thống của chúng tôi.`,
        `Mục đích buổi khám: Tư vấn chuyên sâu và kiểm tra các chỉ số sức khỏe dựa trên triệu chứng đã khai báo.`,
      ],
      keyPoints: [
        'Xác minh lại danh sách các loại thuốc đang sử dụng (nếu có) để tránh tương tác thuốc.',
        'Kiểm tra tiền sử dị ứng thực phẩm hoặc dược phẩm để đảm bảo an toàn trong quy trình chẩn đoán.',
        'Đối chiếu dữ liệu bảo hiểm y tế và căn cước công dân để tối ưu hóa thủ tục hành chính.',
        'Lưu ý các chỉ số sinh tồn cơ bản cần thực hiện đo đạc ngay khi tiếp nhận bệnh nhân.',
      ],
      recommendations: [
        'Vui lòng mang theo kết quả xét nghiệm hoặc đơn thuốc cũ trong vòng 6 tháng gần nhất (nếu có).',
        'Nên nhịn ăn sáng đối với các gói khám yêu cầu xét nghiệm máu hoặc siêu âm ổ bụng.',
        'Có mặt tại quầy lễ tân trước giờ hẹn ít nhất 15 phút để làm thủ tục check-in nhanh.',
        'Tải sẵn mã QR lịch hẹn trên ứng dụng để quét mã tự động tại phòng khám.',
      ],
    };
  }
}