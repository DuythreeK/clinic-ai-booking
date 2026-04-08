# Mobile App - Clinic AI Booking

Ứng dụng Flutter cho hệ thống đặt lịch khám bệnh hỗ trợ bởi AI.

## 📱 Tính Năng

### Tính năng hiện tại:
- ✅ Xác thực người dùng (Đăng nhập/Đăng ký)
- ✅ Trang chủ với các tùy chọn nhanh
- ✅ Tìm kiếm và lọc bác sĩ
- ✅ Đặt lịch khám
- ✅ Quản lý lịch hẹn
- ✅ Hồ sơ bệnh nhân
- ✅ AI Triage (Lọc triệu chứng AI)

### Tính năng sắp tới:
- 🔄 Thông báo theo thời gian thực (Firebase FCM)
- 🔄 Cổng bác sĩ (Doctor Portal)
- 🔄 Cổng quản lý (Admin Portal)
- 🔄 Chat tư vấn với bác sĩ
- 🔄 Hỗ trợ offline
- 🔄 Định vị địa điểm phòng khám

## 🛠 Cài Đặt

### Yêu cầu:
- Flutter 3.1+ 
- Dart 3.0+
- iOS 11.0+ hoặc Android 5.0+

### Bước 1: Cài đặt dependencies
```bash
cd mobile
flutter pub get
```

### Bước 2: Cấu hình API
Chỉnh sửa `lib/core/config/api_config.dart`:
```dart
const String baseUrl = 'http://your-backend-url/api';
```

### Bước 3: Chạy ứng dụng
```bash
flutter run
```

## 📁 Cấu trúc Dự Án

```
lib/
├── main.dart                 # Điểm khởi động ứng dụng
├── router.dart              # Cấu hình định tuyến GoRouter
├── core/
│   ├── api/
│   │   ├── dio_client.dart      # HTTP client với interceptors
│   │   └── api_config.dart      # Cấu hình API
│   ├── config/
│   │   └── api_config.dart      # API endpoints
│   ├── models/
│   │   └── models.dart          # Data models (10 classes)
│   └── storage/
│       └── auth_storage.dart    # Local storage cho tokens
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── login_screen.dart      # Đăng nhập
│   │   │   └── register_screen.dart   # Đăng ký
│   │   ├── services/
│   │   │   └── auth_service.dart      # Authentication logic
│   │   └── providers/                 # Riverpod providers (TBD)
│   ├── booking/
│   │   ├── screens/
│   │   │   ├── home_screen.dart            # Trang chủ + Bottom Nav
│   │   │   └── doctor_search_screen.dart   # Tìm bác sĩ & Chi tiết
│   │   └── services/
│   │       ├── appointment_service.dart    # Appointment CRUD
│   │       ├── doctor_service.dart         # Doctor search
│   │       ├── slot_service.dart           # Slot management
│   │       └── specialty_service.dart      # Specialty catalog
│   ├── ai_triage/
│   │   └── screens/
│   │       └── triage_screen.dart          # AI triaging
│   ├── doctor_portal/                      # TBD
│   └── admin_portal/                       # TBD
└── pubspec.yaml            # Dependencies

```

## 🔧 Cấu Hình Chính

### API Configuration (api_config.dart)
```dart
const String baseUrl = 'http://localhost:3000/api';
```

### Endpoints được sử dụng:
- `POST /auth/login` - Đăng nhập
- `POST /auth/register` - Đăng ký
- `POST /auth/refresh` - Làm mới token
- `GET /doctors` - Danh sách bác sĩ
- `GET /specialties` - Chuyên khoa
- `GET /slots` - Khung giờ
- `POST /appointments` - Đặt lịch
- `GET /appointments/my` - Lịch hẹn của tôi
- `PATCH /patients/profile` - Cập nhật hồ sơ
- `POST /ai/triage` - AI triaging

## 📦 Packages Chính

```yaml
# HTTP & Networking
dio: ^5.3.1
flutter_secure_storage: ^9.0.0

# State Management
provider: ^6.0.0
riverpod: ^2.4.0

# Navigation
go_router: ^12.0.0

# JSON Serialization
json_annotation: ^4.8.1

# Logging
logger: ^2.0.0

# UI
flutter_animate: ^4.2.0
cached_network_image: ^3.3.1

# Utilities
intl: ^0.18.0
```

## 🚀 Chạy Ứng Dụng

### Debug Mode:
```bash
flutter run
```

### Release Mode:
```bash
flutter run --release
```

### Build APK:
```bash
flutter build apk --release
```

### Build iOS:
```bash
flutter build ios --release
```

## 🔐 Authentication Flow

1. **Đăng nhập/Đăng ký**: Gửi credentials tới backend
2. **Token Storage**: Access token và Refresh token được lưu trong Secure Storage
3. **Token Interceptor**: Tất cả requests đều tự động thêm Authorization header
4. **Token Refresh**: Nếu token hết hạn, interceptor tự động làm mới
5. **Logout**: Xóa tokens từ storage

## 📲 Screens

### Authentication Screens:
- **LoginScreen**: Đăng nhập với email/password
- **RegisterScreen**: Tạo tài khoản mới

### Booking Screens:
- **HomeScreen**: 
  - Tab 1: Trang chủ (Quick actions, Upcoming appointments)
  - Tab 2: Đặt lịch (Specialty list)
  - Tab 3: Lịch hẹn (Appointments list)
  - Tab 4: Tài khoản (Profile)
  
- **DoctorSearchScreen**: Tìm kiếm bác sĩ theo chuyên khoa
- **DoctorDetailScreen**: Chi tiết bác sĩ, đặt lịch

### AI Triage:
- **TriageScreen**: Chọn triệu chứng, AI gợi ý bác sĩ

## 🔄 API Integration

Tất cả services đều sử dụng `DioClient`:

```dart
class AppointmentService {
  final DioClient dioClient;
  
  AppointmentService({required this.dioClient});
  
  Future<Appointment> createAppointment(
    String doctor_id,
    String slot_id,
  ) async {
    final response = await dioClient.post(
      '/appointments',
      data: {'doctor_id': doctor_id, 'slot_id': slot_id},
    );
    return Appointment.fromJson(response.data);
  }
}
```

## 🎨 Themes

App sử dụng Material 3 design system:

```dart
ThemeData(
  primarySwatch: Colors.blue,
  useMaterial3: true,
  brightness: Brightness.light,
)
```

## 📝 Models & DTOs

Tất cả models hỗ trợ JSON serialization:

```dart
@JsonSerializable()
class Doctor {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  
  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
  });
  
  factory Doctor.fromJson(Map<String, dynamic> json) =>
      _$DoctorFromJson(json);
  
  Map<String, dynamic> toJson() => _$DoctorToJson(this);
}
```

## 🧪 Testing (TBD)

```bash
flutter test
```

## 🐛 Debugging

### Logs:
```dart
final logger = Logger();
logger.i('Info message');
logger.e('Error message');
```

### Network Logs:
Tất cả API requests/responses được logged tự động thông qua TokenInterceptor.

## 📚 Tài Liệu Thêm

- [Flutter Docs](https://flutter.dev/docs)
- [GoRouter Docs](https://pub.dev/packages/go_router)
- [Dio Docs](https://pub.dev/packages/dio)
- [Riverpod Docs](https://riverpod.dev)

## 🤝 Đóng Góp

Khi thêm feature mới:
1. Tạo service class nếu cần call API
2. Tạo screen/widget hiển thị data
3. Thêm route vào `router.dart`
4. Cập nhật README

## 📄 License

MIT License - xem LICENSE file

## 📞 Support

Liên hệ qua email hoặc tạo issue trên repository.

---

**Last Updated**: 2024
**Status**: In Development 🚀
