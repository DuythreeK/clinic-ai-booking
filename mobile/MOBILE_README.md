# Mobile App - Clinic AI Booking

Flutter application for an AI-powered clinic appointment booking system.

## 📱 Features

### Current Features:
- ✅ User Authentication (Login/Register)
- ✅ Home Screen with quick actions
- ✅ Doctor search and filtering
- ✅ Appointment booking
- ✅ Appointment management
- ✅ Patient profile
- ✅ AI Symptom Triage

### Coming Soon:
- 🔄 Real-time Notifications (Firebase FCM)
- 🔄 Doctor Portal
- 🔄 Admin Portal
- 🔄 Doctor consultation chat
- 🔄 Offline support
- 🔄 Clinic location finder

## 🛠 Installation

### Requirements:
- Flutter 3.1+ 
- Dart 3.0+
- iOS 11.0+ or Android 5.0+

### Step 1: Install dependencies
```bash
cd mobile
flutter pub get
```

### Step 2: Configure API
Edit `lib/core/config/api_config.dart`:
```dart
const String baseUrl = 'http://your-backend-url/api';
```

### Step 3: Run application
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── router.dart              # GoRouter configuration
├── core/
│   ├── api/
│   │   ├── dio_client.dart      # HTTP client with interceptors
│   │   └── api_config.dart      # API configuration
│   ├── config/
│   │   └── api_config.dart      # API endpoints
│   ├── models/
│   │   └── models.dart          # Data models (10 classes)
│   └── storage/
│       └── auth_storage.dart    # Token local storage
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── login_screen.dart      # Login
│   │   │   └── register_screen.dart   # Register
│   │   ├── services/
│   │   │   └── auth_service.dart      # Auth logic
│   │   └── providers/                 # Riverpod providers (TBD)
│   ├── booking/
│   │   ├── screens/
│   │   │   ├── home_screen.dart            # Home + Bottom Nav
│   │   │   └── doctor_search_screen.dart   # Doctor search & Details
│   │   └── services/
│   │       ├── appointment_service.dart    # Appointment CRUD
│   │       ├── doctor_service.dart         # Doctor operations
│   │       ├── slot_service.dart           # Slot management
│   │       └── specialty_service.dart      # Specialty catalog
│   ├── ai_triage/
│   │   └── screens/
│   │       └── triage_screen.dart          # AI triaging
│   ├── doctor_portal/                      # TBD
│   └── admin_portal/                       # TBD
└── pubspec.yaml            # Dependencies

```

## 🔧 Main Configuration

### API Configuration (api_config.dart)
```dart
const String baseUrl = 'http://localhost:3000/api';
```

### API Endpoints Used:
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/refresh` - Token refresh
- `GET /doctors` - Get doctors list
- `GET /specialties` - Get specialties
- `GET /slots` - Get available slots
- `POST /appointments` - Create appointment
- `GET /appointments/my` - Get my appointments
- `PATCH /patients/profile` - Update patient profile
- `POST /ai/triage` - AI triaging

## 📦 Main Packages

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

## 🚀 Running the Application

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

1. **Login/Register**: Send credentials to backend
2. **Token Storage**: Access and refresh tokens stored in Secure Storage
3. **Token Interceptor**: All requests automatically add Authorization header
4. **Token Refresh**: If token expires, interceptor automatically refreshes it
5. **Logout**: Remove tokens from storage

## 📲 Screens

### Authentication Screens:
- **LoginScreen**: Email/password login
- **RegisterScreen**: Create new account

### Booking Screens:
- **HomeScreen**: 
  - Tab 1: Home (Quick actions, Upcoming appointments)
  - Tab 2: Book (Specialty list)
  - Tab 3: Appointments (My appointments)
  - Tab 4: Account (Profile)
  
- **DoctorSearchScreen**: Search doctors by specialty
- **DoctorDetailScreen**: Doctor details, book appointment

### AI Triage:
- **TriageScreen**: Select symptoms, get AI recommendation

## 🔄 API Integration

All services use `DioClient`:

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

App uses Material 3 design system:

```dart
ThemeData(
  primarySwatch: Colors.blue,
  useMaterial3: true,
  brightness: Brightness.light,
)
```

## 📝 Models & DTOs

All models support JSON serialization:

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
All API requests/responses are automatically logged via TokenInterceptor.

## 📚 Additional Resources

- [Flutter Docs](https://flutter.dev/docs)
- [GoRouter Docs](https://pub.dev/packages/go_router)
- [Dio Docs](https://pub.dev/packages/dio)
- [Riverpod Docs](https://riverpod.dev)

## 🤝 Contributing

When adding new features:
1. Create service class for API calls
2. Create screen/widget to display data
3. Add route to `router.dart`
4. Update README

## 📄 License

MIT License - see LICENSE file

## 📞 Support

Contact via email or create an issue on the repository.

---

**Last Updated**: 2024
**Status**: In Development 🚀
