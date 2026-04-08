# Mobile - Clinic AI Booking (Flutter)

Cross-platform mobile app (iOS/Android) cho Clinic AI Booking system.

## Setup & Installation

### Prerequisites

- Flutter 3.10+
- Dart 3.15+
- Xcode 14+ (iOS)
- Android Studio (Android)
- VS Code / Android Studio / Xcode

### 1. Install Dependencies

```bash
cd mobile
flutter pub get
```

### 2. Configure Backend URL

Edit `lib/core/config/api_config.dart`:

```dart
const String baseUrl = 'http://192.168.1.100:3000'; // Your backend URL
```

For local testing:
- iOS simulator: `http://localhost:3000`
- Android emulator: `http://10.0.2.2:3000`
- Physical device: `http://<your-machine-ip>:3000`

### 3. Run App

**iOS**:
```bash
flutter run -d ios
# or
flutter run -d "iPhone 15"
```

**Android**:
```bash
flutter run -d android
# or
flutter run -d emulator-5554
```

**Web** (experimental):
```bash
flutter run -d web
```

## Folder Structure

```
mobile/
├── lib/
│   ├── main.dart                      # Entry point
│   ├── router.dart                    # Go Router configuration
│   ├── core/
│   │   ├── api/
│   │   │   └── dio_client.dart        # HTTP client + token interceptor
│   │   ├── config/
│   │   │   └── api_config.dart        # API endpoints
│   │   ├── storage/
│   │   │   └── auth_storage.dart      # Secure token storage
│   │   └── models/
│   │       └── (API models)
│   ├── features/
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   │   └── login_screen.dart
│   │   │   └── services/
│   │   │       └── auth_service.dart
│   │   ├── booking/
│   │   │   ├── screens/
│   │   │   │   └── home_screen.dart
│   │   │   └── services/
│   │   ├── appointments/
│   │   ├── ai_triage/
│   │   ├── doctor_portal/
│   │   └── admin_portal/
│   └── shared/
│       ├── widgets/
│       └── utils/
├── test/                              # Unit & widget tests
├── ios/                               # iOS native code
├── android/                           # Android native code
├── web/                               # Web build files
├── pubspec.yaml                       # Dependencies
├── analysis_options.yaml              # Lint rules
└── README.md
```

## Features Implemented

### Auth Module ✅
- Login screen with validation
- Auto token refresh flow
- Secure storage (Keychain/Keystore)
- Logout with token cleanup

### Booking ✅
- Home screen with 3 tabs
- Search doctors (placeholder UI)
- View appointments (placeholder)
- User profile (placeholder)

### AI Triage 🔲
- Symptom input form
- AI analysis result display
- Save to appointment

### Doctor Portal 🔲
- View assigned appointments
- Update appointment status
- Add notes & prescription

### Admin Portal 🔲
- Doctor CRUD
- Slot management
- Clinic management

## Architecture

### State Management
- **Provider** for simple state
- **Riverpod** ready (convert as needed)
- **GetIt** for dependency injection

### HTTP Client (Dio)
```dart
// Auto token injection
dio.get('/appointments/my')
  // Authorization: Bearer <accessToken> added automatically

// Auto token refresh
// If 401 → call /auth/refresh → retry request
```

### Secure Storage
```dart
// Tokens stored securely
await authStorage.saveTokens(
  accessToken: token,
  refreshToken: refreshToken,
);

// Retrieve
final token = await authStorage.getAccessToken();
```

## API Integration

### Example: Login

```dart
// Service
final result = await authService.login(
  email: 'patient@clinic.local',
  password: 'patient123',
);

// Tokens + user data automatically saved
// Can now make authenticated requests
```

### Example: Create Appointment

```dart
// Service
final appointment = await appointmentService.create(
  slot_id: 'slot-123',
  reason: 'Check up',
);

// Sent with Authorization header automatically
```

## Routing (Go Router)

```dart
// Navigate
context.pushNamed('home');
context.push('/login');

// Replace
context.replaceNamed('home');

// Pop
context.pop();
```

## Models & Serialization

Example model structure:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

Generate:
```bash
flutter pub run build_runner build
```

## Firebase Cloud Messaging (FCM) Setup

### iOS
1. Create Firebase project: https://console.firebase.google.com
2. Add iOS app
3. Download `GoogleService-Info.plist`
4. Add to Xcode project

### Android
1. Add Android app to Firebase project
2. Download `google-services.json`
3. Place in `android/app/`

### Code
```dart
// Request permission
await FirebaseMessaging.instance.requestPermission();

// Get token
final token = await FirebaseMessaging.instance.getToken();

// Save to backend
await authService.saveFcmToken(token);

// Listen to messages
FirebaseMessaging.onMessage.listen((message) {
  // Handle foreground notification
});
```

## Development

### Hot Reload
- Edit `.dart` file and press `r` in terminal
- Fast iteration during development

### Debug Mode
```bash
flutter run
# Default runs in debug mode
```

### Profile Mode
```bash
flutter run --profile
# Performance profiling
```

### Release Mode
```bash
flutter run --release
# Optimized build
```

### Logging
```dart
import 'package:logger/logger.dart';

final logger = Logger();

logger.i('Info message');
logger.e('Error message');
logger.w('Warning message');
```

## Testing

### Unit Tests
```bash
# Run all tests
flutter test

# Watch mode
flutter test --watch

# Coverage
flutter test --coverage
```

Example:
```dart
test('LoginScreen loads', () {
  expect(find.byType(LoginScreen), findsOneWidget);
});
```

### Widget Tests
```dart
testWidgets('Login button works', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
});
```

## Build & Release

### iOS

```bash
# Build for iOS
flutter build ios

# Release to App Store
# (Requires Apple Developer account)
open ios/Runner.xcworkspace
# Build from Xcode
```

### Android

```bash
# Build APK
flutter build apk

# Build App Bundle (for Play Store)
flutter build appbundle

# Release to Play Store
# (Use Play Console or fastlane)
```

### Version Management

Update in `pubspec.yaml`:
```yaml
version: 1.0.0+1
# 1.0.0 = version
# +1 = build number
```

## Performance Tips

1. Use `const` constructors
2. Avoid rebuilds with `const` widgets
3. Use lazy loading for lists
4. Cache API responses
5. Compress images
6. Use `SizedBox` instead of `Container` when possible

## Common Issues

### "Connection refused" error
- Check backend is running on correct URL
- Check firewall settings
- For iOS simulator: use `localhost:3000`
- For Android emulator: use `10.0.2.2:3000`

### "Plugin not found" error
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build
```

### "Image not found" error
- Check image paths in `pubspec.yaml`
- Run `flutter clean` and `flutter pub get`

## Dependencies

- **dio** (5.3.1): HTTP client with interceptors
- **flutter_secure_storage** (9.0.0): Secure token storage
- **go_router** (12.0.0): Navigation
- **logger** (2.0.2): Logging
- **firebase_messaging** (14.6.0): FCM notifications
- **json_serializable** (6.7.0): JSON parsing

## Contributing

1. Create feature branch
2. Follow Dart style guide
3. Run tests before push
4. Create pull request

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Dio Package](https://pub.dev/packages/dio)
- [Go Router](https://pub.dev/packages/go_router)
- [Firebase Messaging](https://pub.dev/packages/firebase_messaging)

## License

MIT
