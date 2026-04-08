# 🚀 Hướng Dẫn Khởi Động Nhanh - Phát Triển Di Động

## 🎯 Trạng Thái Hiện Tại

Ứng dụng di động **hoạt động đầy đủ với dữ liệu placeholder**. Tất cả các màn hình đã hoàn chỉnh và sẵn sàng cho tích hợp API.

## 📋 Những Gì Sẵn Sàng

### ✅ Màn Hình Hoàn Chỉnh (6)
1. **LoginScreen** - Đăng nhập email/mật khẩu với xác thực
2. **RegisterScreen** - Quy trình đăng ký đầy đủ với điều khoản
3. **HomeScreen** - Điều hướng dưới cùng 4 tab
4. **DoctorSearchScreen** - Danh sách bác sĩ với bộ lọc
5. **DoctorDetailScreen** - Hồ sơ bác sĩ & đặt lịch
6. **TriageScreen** - Lựa chọn triệu chứng AI

### ✅ Dịch Vụ Hoàn Chỉnh (6)
- AppointmentService
- DoctorService
- SlotService
- SpecialtyService
- PatientService
- AiService

### ✅ Hạ Tầng Hoàn Chỉnh
- DioClient với token interceptors
- Lưu trữ token an toàn
- Điều hướng GoRouter
- 10 mô hình dữ liệu
- Cấu hình API

## 🏃 Bắt Đầu Trong 5 Phút

### Bước 1: Điều Hướng Đến Di Động
```bash
cd mobile
```

### Bước 2: Cài Đặt Dependencies
```bash
flutter pub get
```

### Bước 3: Cấu Hình URL Backend
Chỉnh sửa `lib/core/config/api_config.dart`:
```dart
const String baseUrl = 'http://localhost:3000/api';
```

### Bước 4: Chạy Ứng Dụng
```bash
flutter run
```

### Bước 5: Kiểm Tra Luồng
1. **LoginScreen** → Sử dụng bất kỳ email/mật khẩu nào
2. **HomeScreen** → Xem tất cả 4 tab hoạt động
3. **DoctorSearchScreen** → Lọc theo chuyên khoa
4. **TriageScreen** → Chọn triệu chứng, xem gợi ý AI

## 🧪 Các Kịch Bản Kiểm Tra

### Kiểm Tra 1: Luồng Xác Thực
```
1. Nhấp Register trên LoginScreen
2. Điền tất cả các trường (xác thực biểu mẫu)
3. Chọn Điều Khoản & Điều Kiện
4. Nhấp Register → Nên thấy snackbar thành công
5. Quay lại LoginScreen
6. Nhập email/mật khẩu → Nên đăng nhập thành công
```

### Kiểm Tra 2: Tìm Kiếm Bác Sĩ
```
1. Từ HomeScreen, nhấp tab "Đặt lịch"
2. Nhấp thẻ "Đặt lịch mới"
3. Tìm kiếm bác sĩ → Xem kết quả được lọc
4. Chọn chuyên khoa từ chip
5. Nhấp thẻ bác sĩ → Xem chi tiết bác sĩ
```

### Kiểm Tra 3: Chi Tiết & Đặt Lịch Bác Sĩ
```
1. Trên DoctorDetailScreen
2. Chọn ngày (hiển thị 7 ngày tới)
3. Chọn khung giờ
4. Nhấp "Đặt lịch hẹn" → Nên hiển thị thành công
```

### Kiểm Tra 4: AI Lọc Triệu Chứng
```
1. Từ HomeScreen, nhấp "Lọc triệu chứng AI"
2. Chọn nhiều triệu chứng (xác thực checkbox)
3. Thêm ghi chú tùy chọn
4. Nhấp "Lọc triệu chứng" → Xem bác sĩ được gợi ý
5. Nhấp "Đặt lịch" để đặt với gợi ý
```

### Kiểm Tra 5: Điều Hướng
```
1. Kiểm tra tất cả tab điều hướng dưới chuyển đúng cách
2. Nhấp nút quay lại hoạt động
3. Luồng điều hướng mượt mà
4. Không có vòng lặp hoặc trạng thái bị kẹt
```

## 🔌 Kết Nối Với Backend Thực Tế

### Cho AppointmentService:
1. Backend nên có: `POST /appointments`
2. Nội dung yêu cầu:
```json
{
  "doctor_id": "doctor-uuid",
  "slot_id": "slot-uuid"
}
```
3. Phản hồi nên là mô hình Appointment

### Cho DoctorService:
1. Backend nên có: `GET /doctors`
2. Tham số tùy chọn: `specialty`, `search`, `availabilityFilter`
3. Phản hồi: Danh sách mô hình Doctor

### Cho Xác Thực:
1. Backend nên có: `POST /auth/login`
2. Yêu cầu: `{email, password}`
3. Phản hồi: `{accessToken, refreshToken, user}`

**Lưu Ý**: Tokens được xử lý tự động bởi DioClient interceptors

## 🔧 Các Nhiệm Vụ Thường Gặp

### Thêm Màn Hình Mới
```dart
// 1. Tạo tập tin: lib/features/module/screens/my_screen.dart
class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);
  
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Màn Hình Của Tôi')),
      body: Center(child: Text('Xin chào')),
    );
  }
}

// 2. Thêm vào router.dart
GoRoute(
  path: '/my-screen',
  name: 'my-screen',
  builder: (context, state) => const MyScreen(),
),

// 3. Điều hướng từ các màn hình khác
context.go('/my-screen');
```

### Thêm Dịch Vụ Mới
```dart
// 1. Tạo tập tin: lib/features/module/services/my_service.dart
class MyService {
  final DioClient dioClient;
  
  MyService({required this.dioClient});
  
  Future<MyModel> getMyData() async {
    final response = await dioClient.get('/my-endpoint');
    return MyModel.fromJson(response.data);
  }
}

// 2. Sử dụng trong màn hình
final service = MyService(dioClient: dioClient);
final data = await service.getMyData();
```

### Cập Nhật Models
```dart
// Models trong: lib/core/models/models.dart
// Tất cả hỗ trợ JSON serialization:
@JsonSerializable()
class MyModel {
  final String id;
  final String name;
  
  MyModel({required this.id, required this.name});
  
  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$MyModelToJson(this);
}
```

## 🐛 Mẹo Gỡ Lỗi

### Kiểm Tra Nhật Ký Mạng
Tất cả các API calls được ghi nhật ký tự động. Xem trong bảng điều khiển Flutter:
```
🔹 API Request: GET /doctors
🔹 API Response: 200
```

### Các Lỗi Thường Gặp

**Vấn Đề**: `DioException: Bad Certificate`
```
Giải Pháp: Thêm vào DioClient cho dev:
_dio.httpClientAdapter = HttpClientAdapter()
  ..onHttpClientCreate = (client) {
    client.badCertificateCallback = (_, __, ___) => true;
    return client;
  };
```

**Vấn Đề**: Token không được đưa vào yêu cầu
```
Giải Pháp: Kiểm tra AuthStorage có tokens:
final token = await authStorage.getAccessToken();
print('Token: $token');
```

**Vấn Đề**: Điều hướng không hoạt động
```
Giải Pháp: Đảm bảo GoRouter được thiết lập đúng cách trong main.dart
và tất cả các route tồn tại trong router.dart
```

## 📊 Thống Kê Dự Án

| Chỉ Số | Giá Trị |
|--------|--------|
| Tổng Màn Hình | 6 |
| Tổng Dịch Vụ | 6 |
| Tổng Models | 10 |
| Dòng Mã | ~3,500+ |
| Tài Liệu | 2 tập tin |

## 🎨 Ghi Chú UI/UX

- Tất cả các màn hình sử dụng nhãn Tiếng Việt (có thể thay đổi trong mã)
- Hệ thống thiết kế Material 3
- Điều hướng dưới cùng cho ứng dụng chính
- Bố cục dựa trên thẻ
- Xác thực biểu mẫu trên đầu vào
- Trạng thái tải (tiến trình tròn)
- Trạng thái lỗi (thông báo snackbar)
- Trạng thái trống (biểu tượng + văn bản)

## 🚦 Quy Trình Phát Triển

1. **Thực hiện thay đổi cho màn hình**: Kiểm tra trong hot reload Flutter
2. **Kết nối với API**: Cập nhật cuộc gọi dịch vụ
3. **Thêm quản lý trạng thái**: Tạo provider Riverpod
4. **Commit công việc**: Sử dụng các thông báo commit có ý nghĩa
5. **Tài liệu thay đổi**: Cập nhật README nếu cần

## 📱 Bản Đồ Điều Hướng Màn Hình

```
LoginScreen
    ↓
RegisterScreen ← Liên kết đăng ký
    ↓
HomeScreen (4 tab)
    ├── Tab 1: Trang chủ (hành động nhanh)
    │   ├── → "Đặt lịch mới" → DoctorSearchScreen
    │   └── → "Lọc triệu chứng AI" → TriageScreen
    ├── Tab 2: Trang đặt lịch (chuyên khoa)
    │   └── → DoctorSearchScreen
    ├── Tab 3: Trang lịch hẹn (danh sách)
    │   └── → Chi tiết lịch hẹn (TBD)
    └── Tab 4: Trang hồ sơ (cài đặt)
        └── → Chỉnh sửa hồ sơ (TBD)

DoctorSearchScreen
    ↓
DoctorDetailScreen (chọn ngày/giờ)
    ↓
Đặt lịch hẹn

TriageScreen
    ↓
Kết quả lọc
    ↓
Đặt lịch với gợi ý
```

## ✅ Sẵn Sàng Cho Giai Đoạn Tiếp Theo

Tất cả các thành phần đều sẵn sàng cho **Giai Đoạn 2: Tích Hợp API**

### Những gì cần làm tiếp theo:
1. **Thiết Lập Quản Lý Trạng Thái**
   - Tạo providers Riverpod
   - Thêm trạng thái tải/lỗi

2. **Tích Hợp Với Backend**
   - Cập nhật cuộc gọi dịch vụ
   - Xử lý phản hồi API thực tế

3. **Thêm Xử Lý Lỗi**
   - Hộp thoại lỗi mạng
   - Phản hồi xác thực biểu mẫu

4. **Cải Thiện UX**
   - Skeleton loading
   - Animations tốt hơn

## 📚 Tài Nguyên

- [Tài Liệu Flutter](https://flutter.dev/docs)
- [Tài Liệu Dio](https://pub.dev/packages/dio)
- [Tài Liệu GoRouter](https://pub.dev/packages/go_router)
- [Tài Liệu Riverpod](https://riverpod.dev)

## 💡 Mẹo Pro

1. Sử dụng `flutter pub upgrade` để giữ dependencies cập nhật
2. Chạy `flutter analyze` để kiểm tra vấn đề mã
3. Sử dụng `flutter format .` để định dạng mã
4. Bật debug banners: `debugShowCheckedModeBanner: false` trong main.dart
5. Sử dụng Flutter DevTools để lập hồ sơ hiệu năng

## 🎓 Học Tập Tiếp Theo

Sau khi hoàn thành giai đoạn này:
1. Tìm hiểu quản lý trạng thái Riverpod
2. Triển khai các mẫu provider
3. Thêm ranh giới lỗi
4. Tạo các widget tùy chỉnh
5. Tối ưu hóa hiệu năng

---

**Sẵn sàng để xây dựng! 🚀**

Đối với các câu hỏi hoặc vấn đề, hãy kiểm tra các tập tin README hoặc tham khảo tài liệu Flutter.
## HUONG DAN CACH CHAY (CAP NHAT)

### Buoc 1: Cai Flutter SDK
1. Cai Flutter theo huong dan: https://docs.flutter.dev/get-started/install/windows
2. Them `flutter/bin` vao PATH (vi du `D:\Admin\flutter\bin`)
3. Mo terminal moi va kiem tra:
```bash
flutter --version
flutter doctor
```

### Buoc 2: Cai dependencies
```bash
cd clinic-ai-booking/mobile
flutter pub get
```

### Buoc 3: Cau hinh backend URL
Mo `lib/core/config/api_config.dart` va sua:
```dart
const String baseUrl = 'http://localhost:3000';
```

### Buoc 4: Chay app
```bash
flutter run
```

### Buoc 5: Kiem tra nhanh
- Dang nhap / dang ky
- Vao man AI Triage va gui trieu chung
