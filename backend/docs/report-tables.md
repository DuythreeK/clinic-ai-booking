# Bảng Mô Tả Kiến Trúc Và Chức Năng Hệ Thống

Tài liệu này tổng hợp các bảng mô tả theo đúng code hiện có trong dự án: lớp, hàm, bảng CSDL, và API gọi ngoài.

## 1. Bảng lớp

| Lớp / module | Vai trò | Thành phần chính | Kết nối với | Giải thích |
|---|---|---|---|---|
| `MyApp` | Khởi động ứng dụng mobile | Khởi tạo router, auth service, Dio client | Backend API qua HTTP | Là điểm vào của app Flutter, dựng giao diện và điều hướng màn hình ban đầu. Xem [mobile/lib/main.dart](../../mobile/lib/main.dart). |
| `AppModule` | Module gốc của backend | Gom các module nghiệp vụ | Tất cả module backend | Đây là lớp lắp ráp trung tâm của NestJS, đưa các module vào chung một hệ thống. Xem [backend/src/app.module.ts](../src/app.module.ts). |
| `DoctorsController` | Controller bác sĩ | Nhận request, điều phối API bác sĩ | `DoctorsService` | Xử lý API danh sách bác sĩ, bác sĩ nổi bật, bác sĩ của tôi, chi tiết bác sĩ. |
| `DoctorsService` | Service bác sĩ | Query, thống kê, mapping dữ liệu | `Doctor`, `Specialty`, `Facility`, `Appointment`, `DoctorReview`, `Slot`, `User` | Tính toán dữ liệu hiển thị cho bác sĩ như rating, lượt đặt hôm nay, slot gần nhất. |
| `ServicesController` | Controller dịch vụ | Nhận request dịch vụ tiêm chủng | `ServicesService` | Cung cấp API cho danh sách gói tiêm, chi tiết gói, slot khả dụng. |
| `ServicesService` | Service dịch vụ | Lấy gói vaccine, slot, chi tiết booking | `Service`, `Vaccine`, `ServiceVaccine`, `Slot`, `Facility` | Là nơi chuẩn bị dữ liệu cho luồng đặt lịch tiêm chủng. |
| `SlotsController` | Controller slot | Nhận request slot | `SlotsService` | Quản lý slot lịch khám/tiêm, bao gồm xem, tạo, cập nhật, xóa, đổi sức chứa. |
| `SlotsService` | Service slot | Tính booking count, capacity log, cập nhật slot | `Slot`, `Appointment`, `SlotCapacityLog`, `User` | Quản lý trạng thái slot và nhật ký sức chứa. |
| `AppointmentsController` | Controller đặt lịch | Nhận yêu cầu đặt lịch | `AppointmentsService` | Là entry point cho booking. |
| `AppointmentsService` | Service đặt lịch | Kiểm tra bệnh nhân, slot, tạo appointment bằng transaction | `PatientProfile`, `Slot`, `Appointment`, `Service`, `Doctor`, `Facility` | Đây là lớp nghiệp vụ quan trọng nhất của chức năng đặt lịch tiêm chủng. |
| `PatientsController` | Controller hồ sơ bệnh nhân | CRUD hồ sơ bệnh nhân | `PatientsService` | Quản lý hồ sơ cá nhân và hồ sơ người bệnh để dùng khi đặt lịch. |
| `PatientsService` | Service hồ sơ bệnh nhân | Tạo, sửa, xoá, lấy danh sách hồ sơ | `PatientProfile`, `User` | Bảo đảm người dùng có hồ sơ chính và thông tin hợp lệ. |
| `MedicalRecordsController` | Controller hồ sơ khám | Trả dữ liệu hồ sơ khám | `MedicalRecordsService` | Phục vụ xem lịch sử khám, kết quả, đơn thuốc, thanh toán. |
| `MedicalRecordsService` | Service hồ sơ khám | Gom lịch sử khám, bác sĩ, thanh toán, đánh giá | `MedicalRecord`, `Appointment`, `Doctor`, `Payment`, `DoctorReview` | Dùng cho chức năng quản lý hồ sơ khám. |
| `PaymentsController` | Controller thanh toán | Tạo thanh toán và nhận callback | `PaymentsService` | Nhận yêu cầu tạo payment và callback trạng thái thanh toán. |
| `PaymentsService` | Service thanh toán | Tạo payment, cập nhật trạng thái callback | `Payment`, `Appointment` | Tạo liên kết thanh toán cho appointment và cập nhật kết quả từ gateway. |
| `PrismaService` | Lớp truy cập dữ liệu | PrismaClient wrapper | MySQL | Đóng vai trò cầu nối giữa service và cơ sở dữ liệu. |
| `JwtGuard` | Lớp bảo mật | Xác thực JWT | Auth token | Kiểm tra quyền truy cập cho endpoint cần đăng nhập. |

## 2. Bảng hàm

| Hàm | Nằm trong lớp | Mục đích | Input chính | Output / kết quả | Bảng CSDL sử dụng | Giải thích |
|---|---|---|---|---|---|---|
| `getDoctors` | `DoctorsService` | Xem, lọc, tìm kiếm bác sĩ | `page`, `limit`, `search`, `specialtyId`, `facilityId` | Danh sách bác sĩ có phân trang | `Doctor`, `Specialty`, `Facility`, `Appointment`, `DoctorReview`, `Slot`, `User` | Lọc theo chuyên khoa/cơ sở và tính các chỉ số hiển thị. |
| `getFeaturedDoctors` | `DoctorsService` | Lấy bác sĩ nổi bật | `limit`, `search`, `specialty` | Danh sách bác sĩ nổi bật | `Doctor`, `Appointment`, `DoctorReview`, `Slot` | Xếp bác sĩ theo lượt đặt hôm nay và rating. |
| `getMyDoctors` | `DoctorsService` | Lấy bác sĩ của tôi | `userId`, `search` | Danh sách bác sĩ liên quan đến user | `Appointment`, `DoctorReview`, `Doctor` | Suy ra từ lịch đã đặt và đánh giá của người dùng. |
| `getDoctorById` | `DoctorsService` | Xem chi tiết bác sĩ | `id` | Chi tiết bác sĩ | `Doctor`, `Specialty`, `Facility`, `User` | Trả thông tin hồ sơ, chuyên khoa, cơ sở. |
| `getDoctorReviews` | `DoctorsService` | Xem đánh giá bác sĩ | `id` | Danh sách đánh giá | `DoctorReview`, `User` | Phục vụ phần review của bác sĩ. |
| `getServices` | `ServicesService` | Danh sách dịch vụ | `page`, `limit`, `facilityId`, `search` | Danh sách dịch vụ | `Service`, `Facility`, `ServiceVaccine`, `Vaccine` | Dùng để liệt kê các dịch vụ tiêm chủng và dịch vụ thường. |
| `getVaccinationPackages` | `ServicesService` | Danh sách gói tiêm chủng | `search`, `facilityId` | Danh sách gói vaccine | `Service`, `ServiceVaccine`, `Vaccine`, `Facility` | Hiển thị gói vaccine để user chọn trước khi đặt lịch. |
| `getServiceById` | `ServicesService` | Xem chi tiết dịch vụ | `id` | Chi tiết dịch vụ | `Service`, `Facility`, `ServiceVaccine`, `Vaccine` | Trả thông tin gói/dịch vụ cụ thể. |
| `getVaccinationBookingDetail` | `ServicesService` | Chi tiết đặt lịch tiêm chủng | `id`, `date`, `fromDate`, `toDate` | Chi tiết dịch vụ + slot | `Service`, `Slot`, `Doctor`, `Facility`, `Vaccine` | Chuẩn bị dữ liệu cho màn hình booking. |
| `getAvailableSlots` | `ServicesService` | Lấy slot khả dụng cho gói | `id`, `date`, `fromDate`, `toDate` | Danh sách slot còn chỗ | `Service`, `Slot`, `Facility`, `Doctor` | Dùng để cho user chọn khung giờ. |
| `getSlots` | `SlotsService` | Danh sách slot | `doctorId`, `clinicId`, `fromDate`, `toDate` | Danh sách slot | `Slot`, `Appointment` | Tính số chỗ đã đặt và sức chứa. |
| `getSlotById` | `SlotsService` | Xem slot chi tiết | `id` | Chi tiết slot | `Slot`, `Appointment` | Kiểm tra slot trước khi thao tác. |
| `updateSlotCapacity` | `SlotsService` | Cập nhật sức chứa slot | `userId`, `id`, `newCapacity`, `reason` | Slot capacity updated | `Slot`, `SlotCapacityLog`, `Appointment` | Có transaction và log chỉnh sửa sức chứa. |
| `createAppointment` | `AppointmentsService` | Đặt lịch | `userId`, `dto` | Appointment mới | `PatientProfile`, `Slot`, `Appointment`, `Service`, `Doctor`, `Facility` | Hàm lõi của booking, có transaction để tránh trùng slot. |
| `getUserAppointments` | `AppointmentsService` | Xem lịch của user | `userId` | Danh sách appointment | `Appointment`, `PatientProfile`, `Doctor`, `Facility`, `Service`, `Slot` | Dùng cho màn hình lịch hẹn của bệnh nhân. |
| `getAppointmentById` | `AppointmentsService` | Xem chi tiết lịch hẹn | `userId`, `appointmentId` | Appointment detail | `Appointment`, `PatientProfile`, `Doctor`, `Facility`, `Service`, `Slot` | Kiểm tra quyền sở hữu trước khi trả dữ liệu. |
| `createPatientProfile` | `PatientsService` | Tạo hồ sơ bệnh nhân | `userId`, `dto` | Hồ sơ mới | `PatientProfile`, `User` | Tạo hồ sơ người bệnh và xác định hồ sơ chính. |
| `updatePatientProfile` | `PatientsService` | Sửa hồ sơ bệnh nhân | `userId`, `id`, `dto` | Hồ sơ đã cập nhật | `PatientProfile`, `User` | Cho phép đổi thông tin cá nhân, hồ sơ chính. |
| `deletePatientProfile` | `PatientsService` | Xóa hồ sơ bệnh nhân | `userId`, `id` | Kết quả xoá | `PatientProfile`, `User` | Có kiểm tra hồ sơ chính để không làm mất hồ sơ bắt buộc. |
| `getPatientProfiles` | `PatientsService` | Lấy tất cả hồ sơ | `userId` | Danh sách hồ sơ | `PatientProfile` | Dùng cho chọn hồ sơ khi đặt lịch. |
| `getMyMedicalRecords` | `MedicalRecordsService` | Lấy lịch sử khám của tôi | `userId` | Danh sách hồ sơ khám | `MedicalRecord`, `Appointment`, `Doctor`, `Payment`, `DoctorReview` | Gom toàn bộ lịch sử khám và thanh toán. |
| `getMedicalRecordById` | `MedicalRecordsService` | Xem chi tiết hồ sơ khám | `userId`, `id` | Chi tiết hồ sơ khám | `MedicalRecord`, `Appointment`, `Doctor`, `Payment`, `DoctorReview` | Trả sâu dữ liệu điều trị, thanh toán, review. |
| `createPayment` | `PaymentsService` | Tạo thanh toán | `userId`, `dto` | Payment + `paymentUrl` | `Payment`, `Appointment` | Tạo bản ghi thanh toán và trả link sang gateway. |
| `handleCallback` | `PaymentsService` | Nhận callback thanh toán | `transactionCode`, `status`, `errorMessage` | Payment updated | `Payment` | Cập nhật trạng thái thanh toán sau khi gateway phản hồi. |

## 3. Bảng CSDL

| Bảng / model | Mục đích | Khóa chính | Quan hệ chính | Chức năng sử dụng | Giải thích |
|---|---|---|---|---|---|
| `User` | Lưu tài khoản người dùng | `user_id` | 1-n với `Appointment`, `PatientProfile`, `Notification` | Đăng nhập, phân quyền | Là bảng gốc cho toàn hệ thống, chứa role, email, phone, password. |
| `Doctor` | Lưu thông tin bác sĩ | `doctor_id` | thuộc `User`, `Specialty`, `Facility`; 1-n với `Slot`, `Appointment` | Tìm bác sĩ, xem chi tiết, đặt lịch | Dùng cho danh sách bác sĩ, bác sĩ nổi bật, bác sĩ của tôi. |
| `Specialty` | Lưu chuyên khoa | `specialty_id` | 1-n với `Doctor`, `Room` | Lọc bác sĩ theo chuyên khoa | Là nhóm chuyên môn của bác sĩ. |
| `Facility` | Lưu cơ sở / bệnh viện / phòng khám | `facility_id` | 1-n với `Doctor`, `Service`, `Slot`, `Appointment` | Tìm bác sĩ theo cơ sở, đặt lịch | Là nơi thực hiện dịch vụ và booking. |
| `Service` | Lưu dịch vụ / gói tiêm | `service_id` | thuộc `Facility`; 1-n qua `ServiceVaccine`; 1-n `Appointment` | Danh sách gói tiêm, booking detail | Dùng cho màn hình tiêm chủng. |
| `Vaccine` | Lưu vaccine | `vaccine_id` | 1-n với `ServiceVaccine` | Gói vaccine | Chứa tên, hãng, số mũi. |
| `ServiceVaccine` | Bảng liên kết dịch vụ và vaccine | composite key `service_id + vaccine_id` | thuộc `Service` và `Vaccine` | Gói tiêm chủng | Cho biết một gói gồm vaccine nào và số lượng ra sao. |
| `Slot` | Lưu khung giờ đặt lịch | `slot_id` | thuộc `Facility`, `Doctor`; 1-n với `Appointment` | Lấy slot khả dụng, đặt lịch | Có `available_count`, `status` để kiểm soát số chỗ. |
| `SlotCapacityLog` | Nhật ký thay đổi sức chứa slot | `id` | thuộc `Slot`, `User` | Quản lý sức chứa | Ghi lại ai thay đổi số chỗ và thay đổi từ bao nhiêu đến bao nhiêu. |
| `Appointment` | Lưu lịch hẹn | `appointment_id` | thuộc `User`, `PatientProfile`, `Facility`, `Doctor`, `Slot`, `Service`; 1-n `Payment`, `Notification` | Đặt lịch, xem lịch hẹn | Là bảng trung tâm của booking. |
| `AppointmentStatusLog` | Nhật ký thay đổi trạng thái lịch | `id` | thuộc `Appointment`, `User` | Theo dõi trạng thái | Dùng cho audit trạng thái như pending, confirmed, cancelled. |
| `PatientProfile` | Lưu hồ sơ bệnh nhân | `patient_id` | thuộc `User`; 1-n với `Appointment`, `MedicalRecord` | Hồ sơ cá nhân, đặt lịch | Dùng để chọn người đi khám/tiêm khi book. |
| `MedicalRecord` | Lưu hồ sơ khám / kết quả điều trị | `record_id` | thuộc `Appointment`, `PatientProfile`, `Doctor` | Quản lý hồ sơ khám | Phục vụ màn hình lịch sử khám và chi tiết điều trị. |
| `Payment` | Lưu giao dịch thanh toán | `payment_id` | thuộc `Appointment` | Thanh toán | Lưu trạng thái `pending`, `success`, `failed`, `refunded`. |
| `Notification` | Lưu thông báo | `id` | thuộc `User`, `Appointment` | Nhắc lịch, xác nhận | Dùng cho push, email, thông báo trạng thái. |
| `DoctorReview` | Lưu đánh giá bác sĩ | `review_id` | thuộc `Doctor`, `User`, `Appointment` | Bác sĩ nổi bật, review | Dùng để tính rating và hiển thị đánh giá. |
| `VaccinationRegistration` | Lưu đăng ký sàng lọc tiêm chủng | `vaccination_registration_id` | thuộc `Appointment` | Tiêm chủng | Dành cho quy trình sàng lọc trước tiêm. |
| `RefreshToken` | Lưu token đăng nhập lại | `id` | thuộc `User` | Xác thực | Hỗ trợ đăng nhập an toàn. |
| `PasswordResetToken` | Lưu token đặt lại mật khẩu | `id` | thuộc `User` | Bảo mật | Dùng khi quên mật khẩu. |

## 4. Bảng API gọi ngoài

| Loại API | Endpoint / URL | Phương thức | Module / lớp | Mục đích | Request chính | Phản hồi / ghi chú |
|---|---|---|---|---|---|---|
| Client → Backend | `/api/doctors` | GET | `DoctorsController` → `DoctorsService` | Xem, lọc, tìm kiếm bác sĩ | `page`, `limit`, `search`, `specialtyId`, `facilityId` | Trả danh sách bác sĩ có phân trang. |
| Client → Backend | `/api/doctors/mobile/featured` | GET | `DoctorsController` → `DoctorsService` | Bác sĩ nổi bật | `limit`, `search`, `specialty` | Trả danh sách bác sĩ nổi bật. |
| Client → Backend | `/api/doctors/mobile/my` | GET | `DoctorsController` → `DoctorsService` | Bác sĩ của tôi | JWT `userId`, `search` | Trả danh sách bác sĩ người dùng đã đặt hoặc đánh giá. |
| Client → Backend | `/api/doctors/:id` | GET | `DoctorsController` → `DoctorsService` | Chi tiết bác sĩ | `id` | Trả hồ sơ chi tiết của bác sĩ. |
| Client → Backend | `/api/doctors/:id/reviews` | GET | `DoctorsController` → `DoctorsService` | Xem đánh giá bác sĩ | `id` | Danh sách review. |
| Client → Backend | `/api/services` | GET | `ServicesController` → `ServicesService` | Danh sách dịch vụ | `page`, `limit`, `facilityId`, `search` | Trả toàn bộ dịch vụ. |
| Client → Backend | `/api/services/mobile/vaccination-packages` | GET | `ServicesController` → `ServicesService` | Danh sách gói tiêm chủng | `search`, `facilityId` | Dùng cho màn hình chọn gói vaccine. |
| Client → Backend | `/api/services/:id` | GET | `ServicesController` → `ServicesService` | Chi tiết dịch vụ | `id` | Trả chi tiết gói/dịch vụ. |
| Client → Backend | `/api/services/:id/mobile-vaccination-detail` | GET | `ServicesController` → `ServicesService` | Chi tiết đặt lịch tiêm chủng | `id`, `date`, `fromDate`, `toDate` | Trả thông tin gói + slot + cơ sở. |
| Client → Backend | `/api/services/:id/available-slots` | GET | `ServicesController` → `ServicesService` | Lấy slot khả dụng | `id`, `date`, `fromDate`, `toDate` | Trả các slot còn chỗ. |
| Client → Backend | `/api/slots` | GET | `SlotsController` → `SlotsService` | Xem slot | `doctorId`, `clinicId`, `fromDate`, `toDate` | Dùng cho quản trị hoặc hiển thị lịch. |
| Client → Backend | `/api/slots/available` | GET | `SlotsController` → `SlotsService` | Lấy slot khả dụng | `doctorId`, `clinicId`, `fromDate`, `toDate` | Trả slot đang `AVAILABLE`. |
| Client → Backend | `/api/slots/:id` | GET | `SlotsController` → `SlotsService` | Chi tiết slot | `id` | Xem thông tin slot cụ thể. |
| Client → Backend | `/api/appointments` | POST | `AppointmentsController` → `AppointmentsService` | Đặt lịch tiêm chủng / lịch hẹn | `patientId`, `slotId`, `facilityId`, `serviceId`, `appointmentType`, `note` | Tạo appointment bằng transaction. |
| Client → Backend | `/api/appointments` | GET | `AppointmentsController` → `AppointmentsService` | Lấy lịch của tôi | JWT `userId` | Trả danh sách appointment của user. |
| Client → Backend | `/api/appointments/:id` | GET | `AppointmentsController` → `AppointmentsService` | Chi tiết lịch | `id` | Trả lịch hẹn chi tiết. |
| Client → Backend | `/api/patient-profiles` | GET | `PatientsController` → `PatientsService` | Lấy hồ sơ bệnh nhân | JWT `userId` | Trả danh sách hồ sơ người bệnh. |
| Client → Backend | `/api/patient-profiles` | POST | `PatientsController` → `PatientsService` | Tạo hồ sơ bệnh nhân | `CreatePatientProfileDto` | Tạo hồ sơ mới. |
| Client → Backend | `/api/patient-profiles/:id` | PATCH | `PatientsController` → `PatientsService` | Sửa hồ sơ bệnh nhân | `UpdatePatientProfileDto` | Cập nhật thông tin cá nhân/hồ sơ. |
| Client → Backend | `/api/patient-profiles/:id` | DELETE | `PatientsController` → `PatientsService` | Xóa hồ sơ bệnh nhân | `id` | Xóa hồ sơ, giữ ít nhất một hồ sơ chính. |
| Client → Backend | `/api/medical-records` | GET | `MedicalRecordsController` → `MedicalRecordsService` | Xem hồ sơ khám của tôi | JWT `userId` | Trả danh sách hồ sơ khám. |
| Client → Backend | `/api/medical-records/:id` | GET | `MedicalRecordsController` → `MedicalRecordsService` | Xem chi tiết hồ sơ khám | `id` | Trả chi tiết kết quả khám, thanh toán, review. |
| Client → Backend | `/api/payments` | POST | `PaymentsController` → `PaymentsService` | Tạo thanh toán | `appointmentId`, `paymentMethod` | Trả `paymentUrl` để chuyển sang gateway. |
| Client → Backend | `/api/payments/callback` | POST | `PaymentsController` → `PaymentsService` | Nhận callback thanh toán | `transactionCode`, `status`, `errorMessage` | Cập nhật trạng thái payment. |
| Backend → External | `https://sandbox.vnpay.vn/example?txnRef=...` | GET / redirect | `PaymentsService` | Mở cổng thanh toán | `transaction_code` | URL demo đang được build trong service; đây là điểm tích hợp ngoài. |
| Backend → External | Firebase Cloud Messaging | Gửi push | Notifications module / worker | Thông báo đẩy | FCM token, notification payload | Repo có mô tả module notifications và endpoint lưu token, nhưng phần gửi thực tế cần kiểm tra thêm. |

## 5. Ghi chú ngắn để đưa vào báo cáo

- Hệ thống được tổ chức theo mô hình nhiều lớp gồm **Client**, **Controller/API**, **Service**, **Prisma/Database** và **Integration ngoài**.
- Chức năng **đặt lịch tiêm chủng** là luồng trung tâm, kết hợp `ServicesService` để chọn gói vaccine, `SlotsService` để lấy slot khả dụng và `AppointmentsService` để tạo lịch bằng transaction.
- Các chức năng **bác sĩ**, **hồ sơ khám**, **hồ sơ bệnh nhân**, và **thanh toán** đều đã có module riêng trong backend, nên có thể phân tách rõ nhiệm vụ khi viết báo cáo hoặc phân công nhóm.

## 6. Mobile — File và Chức năng được giao

| File | Vai trò | Chức năng được giao |
|---|---|---|
| `mobile/lib/main.dart` | Khởi động ứng dụng | Khởi tạo router, cấu hình auth, bootstrap app, điều hướng chính |
| `mobile/lib/features/doctors/*` | Giao diện bác sĩ | Danh sách bác sĩ, tìm kiếm, bộ lọc, xem chi tiết bác sĩ, chọn bác sĩ để xem slot |
| `mobile/lib/features/appointments/*` | Giao diện đặt lịch | Toàn bộ luồng đặt lịch: chọn gói/dịch vụ, chọn slot, chọn hồ sơ bệnh nhân, trả tiền (nếu cần), xác nhận booking, xem & hủy lịch của tôi |
| `mobile/lib/features/profile/*` | Hồ sơ người dùng | Quản lý `PatientProfile`, chỉnh sửa thông tin, chọn hồ sơ chính, xem lịch sử tiêm/chăm sóc |
| `mobile/lib/core/network/dio_client.dart` | Kết nối API backend | Cấu hình HTTP client, inject `Authorization` header (JWT), retry logic, xử lý lỗi chung |
| `mobile/lib/features/services/*` | Gói dịch vụ / Tiêm chủng | Hiển thị gói vaccine, chi tiết booking, gọi API `getVaccinationBookingDetail` và `getAvailableSlots` |
| `mobile/lib/features/payments/*` (nếu có) | Thanh toán | Tạo payment, mở `paymentUrl`, theo dõi callback/redirect, cập nhật trạng thái thanh toán trong app |
| `mobile/lib/features/notifications/*` (nếu có) | Thông báo | Đăng ký FCM token, nhận push, hiển thị notification trong app |

Ghi chú: Một số thư mục (ví dụ `payments`, `notifications`) có thể không tồn tại trong repo hiện tại — bảng trên nêu các vị trí dự kiến theo chức năng được giao. Nếu muốn, tôi có thể scan `mobile/lib` và chỉnh sửa bảng chính xác theo cấu trúc hiện có.

## 7. Backend — File và Vai trò (Chi tiết)

Dưới đây là bảng kiểm tra các file controller/service chính trong `backend/src/modules` cùng mô tả ngắn về vai trò và chức năng. Bảng dựa trên code hiện có trong repo.

| File | Vai trò | Mô tả ngắn |
|---|---|---|
| `backend/src/modules/doctors/doctors.controller.ts` | Controller bác sĩ | Định nghĩa API liên quan đến bác sĩ (danh sách, chi tiết, featured, my-doctors). |
| `backend/src/modules/doctors/doctors.service.ts` | Service bác sĩ | Xử lý nghiệp vụ bác sĩ: lọc, thống kê, mapping dữ liệu hiển thị. |
| `backend/src/modules/services/services.controller.ts` | Controller dịch vụ | API gói dịch vụ và chi tiết đặt lịch tiêm chủng. |
| `backend/src/modules/services/services.service.ts` | Service dịch vụ | Lấy gói vaccine, mapping vaccine trong service, trả available slots. |
| `backend/src/modules/appointments/appointments.controller.ts` | Controller đặt lịch | Endpoint tạo/tra cứu/hủy lịch (entry point cho booking). |
| `backend/src/modules/appointments/appointments.service.ts` | Service đặt lịch | Logic tạo appointment; sử dụng `prisma.$transaction` để tránh overbooking. |
| `backend/src/modules/patients/patients.controller.ts` | Controller hồ sơ bệnh nhân | API CRUD hồ sơ bệnh nhân. |
| `backend/src/modules/patients/patients.service.ts` | Service hồ sơ bệnh nhân | Tạo/sửa/xóa/lấy hồ sơ bệnh nhân; xác định hồ sơ chính. |
| `backend/src/modules/slots/slots.controller.ts` | Controller slot | API quản lý slot (xem, tạo, cập nhật, capacity). |
| `backend/src/modules/slots/slots.service.ts` | Service slot | Tính booking count, cập nhật sức chứa, ghi `SlotCapacityLog`. |
| `backend/src/modules/payments/payments.controller.ts` | Controller thanh toán | Tạo payment, nhận callback từ gateway. |
| `backend/src/modules/payments/payments.service.ts` | Service thanh toán | Tạo `Payment` record, build `paymentUrl`, handle callback update. |
| `backend/src/modules/medical-records/medical-records.controller.ts` | Controller hồ sơ khám | Endpoint xem lịch sử khám và chi tiết hồ sơ. |
| `backend/src/modules/medical-records/medical-records.service.ts` | Service hồ sơ khám | Gom dữ liệu lịch sử khám, thanh toán, review để trả về client. |
| `backend/src/modules/users/users.controller.ts` | Controller user | Quản lý API liên quan user (profile, admin user endpoints). |
| `backend/src/modules/users/users.service.ts` | Service user | Logic quản lý user, mapping role, thông tin đăng nhập. |
| `backend/src/modules/auth/auth.controller.ts` | Controller auth | Endpoint đăng nhập/đăng ký/refresh token. |
| `backend/src/modules/auth/auth.service.ts` | Service auth | Xác thực, issue JWT, verify credentials, refresh token logic. |
| `backend/src/modules/clinics/clinics.controller.ts` | Controller cơ sở | API danh sách cơ sở, chi tiết cơ sở. |
| `backend/src/modules/clinics/clinics.service.ts` | Service cơ sở | Lấy thông tin phòng khám/clinic và mapping hiển thị. |
| `backend/src/modules/specialties/specialties.controller.ts` | Controller chuyên khoa | API danh sách chuyên khoa. |
| `backend/src/modules/specialties/specialties.service.ts` | Service chuyên khoa | Lấy, lọc chuyên khoa phục vụ filter bác sĩ. |
| `backend/src/modules/doctor-reviews/doctor-reviews.controller.ts` | Controller review | API tạo/đọc đánh giá bác sĩ. |
| `backend/src/modules/doctor-reviews/doctor-reviews.service.ts` | Service review | Xử lý lưu, tính rating, mapping review. |
| `backend/src/modules/ai/ai.controller.ts` | Controller AI | Endpoint cho các chức năng AI (nếu dùng). |
| `backend/src/modules/ai/ai.service.ts` | Service AI | Logic gọi external AI/ML hoặc xử lý nội bộ. |

Ghi chú: Bảng trên bao gồm các file `.controller.ts` và `.service.ts` chính tìm thấy trong `backend/src/modules`. Nếu bạn muốn, tôi sẽ:

- Scan chi tiết từng file để bổ sung `Endpoints chính` (ví dụ `GET /api/services/:id`) và `DTOs` liên quan.
- Xuất bảng này sang file markdown riêng `backend/docs/backend-file-mapping.md`.

