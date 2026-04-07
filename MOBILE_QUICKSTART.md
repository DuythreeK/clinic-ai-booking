# 🚀 Quick Start Guide - Mobile Development

## 🎯 Current State

The mobile app is **fully functional with placeholder data**. All screens are complete and ready for API integration.

## 📋 What's Ready

### ✅ Complete Screens (6)
1. **LoginScreen** - Email/password login with validation
2. **RegisterScreen** - Full registration flow with terms
3. **HomeScreen** - 4-tab bottom navigation
4. **DoctorSearchScreen** - Doctor list with filtering
5. **DoctorDetailScreen** - Doctor profile & booking
6. **TriageScreen** - AI symptom selection

### ✅ Complete Services (6)
- AppointmentService
- DoctorService
- SlotService
- SpecialtyService
- PatientService
- AiService

### ✅ Complete Infrastructure
- DioClient with token interceptors
- Secure token storage
- GoRouter navigation
- 10 data models
- API configuration

## 🏃 Getting Started in 5 Minutes

### Step 1: Navigate to Mobile
```bash
cd mobile
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Configure Backend URL
Edit `lib/core/config/api_config.dart`:
```dart
const String baseUrl = 'http://localhost:3000/api';
```

### Step 4: Run the App
```bash
flutter run
```

### Step 5: Test the Flow
1. **LoginScreen** → Use any email/password
2. **HomeScreen** → See all 4 tabs functional
3. **DoctorSearchScreen** → Filter by specialty
4. **TriageScreen** → Select symptoms, see AI recommendations

## 🧪 Testing Scenarios

### Test 1: Authentication Flow
```
1. Tap Register on LoginScreen
2. Fill in all fields (form validates)
3. Check Terms & Conditions
4. Tap Register → Should see success snackbar
5. Return to LoginScreen
6. Enter email/password → Should login successfully
```

### Test 2: Doctor Search
```
1. From HomeScreen, tap "Booking" tab
2. Click "Đặt lịch mới" card
3. Search for doctor → See filtered results
4. Select specialty from chips
5. Tap a doctor card → See doctor details
```

### Test 3: Doctor Details & Booking
```
1. On DoctorDetailScreen
2. Select a date (shows 7 days ahead)
3. Select a time slot
4. Tap "Đặt lịch hẹn" → Should show success
```

### Test 4: AI Triage
```
1. From HomeScreen, click "Lọc triệu chứng AI" card
2. Select multiple symptoms (checkbox validation)
3. Add optional notes
4. Tap "Lọc triệu chứng" → See recommended doctors
5. Tap "Đặt lịch" to book with recommendation
```

### Test 5: Navigation
```
1. Test all bottom nav tabs switch correctly
2. Tap back buttons work properly
3. Navigation flow is smooth
4. No navigation loops or stuck states
```

## 🔌 Connecting to Real Backend

### For AppointmentService:
1. Backend should have: `POST /appointments`
2. Request body:
```json
{
  "doctorId": "doctor-uuid",
  "slotId": "slot-uuid"
}
```
3. Response should be Appointment model

### For DoctorService:
1. Backend should have: `GET /doctors`
2. Optional params: `specialty`, `search`, `availabilityFilter`
3. Response: List of Doctor models

### For Auth:
1. Backend should have: `POST /auth/login`
2. Request: `{email, password}`
3. Response: `{accessToken, refreshToken, user}`

**Note**: Tokens are automatically handled by DioClient interceptors

## 🔧 Common Tasks

### Add a New Screen
```dart
// 1. Create file: lib/features/module/screens/my_screen.dart
class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);
  
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: Center(child: Text('Hello')),
    );
  }
}

// 2. Add to router.dart
GoRoute(
  path: '/my-screen',
  name: 'my-screen',
  builder: (context, state) => const MyScreen(),
),

// 3. Navigate from other screens
context.go('/my-screen');
```

### Add a New Service
```dart
// 1. Create file: lib/features/module/services/my_service.dart
class MyService {
  final DioClient dioClient;
  
  MyService({required this.dioClient});
  
  Future<MyModel> getMyData() async {
    final response = await dioClient.get('/my-endpoint');
    return MyModel.fromJson(response.data);
  }
}

// 2. Use in screens
final service = MyService(dioClient: dioClient);
final data = await service.getMyData();
```

### Update Models
```dart
// Models are in: lib/core/models/models.dart
// All support JSON serialization:
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

## 🐛 Debugging Tips

### Check Network Logs
All API calls are logged automatically. Look in Flutter console:
```
🔹 API Request: GET /doctors
🔹 API Response: 200
```

### Common Errors

**Issue**: `DioException: Bad Certificate`
```
Solution: Add to DioClient for dev:
_dio.httpClientAdapter = HttpClientAdapter()
  ..onHttpClientCreate = (client) {
    client.badCertificateCallback = (_, __, ___) => true;
    return client;
  };
```

**Issue**: Token not included in requests
```
Solution: Check AuthStorage has tokens:
final token = await authStorage.getAccessToken();
print('Token: $token');
```

**Issue**: Navigation not working
```
Solution: Ensure GoRouter is properly set up in main.dart
and all routes exist in router.dart
```

## 📊 Project Statistics

| Metric | Value |
|--------|-------|
| Total Screens | 6 |
| Total Services | 6 |
| Total Models | 10 |
| Lines of Code | ~3,500+ |
| Documentation | 2 files |

## 🎨 UI/UX Notes

- All screens use Vietnamese labels (可 change in code)
- Material 3 design system
- Bottom navigation for main app
- Card-based layouts
- Form validation on input
- Loading states (circular progress)
- Error states (snackbar messages)
- Empty states (icon + text)

## 🚦 Development Workflow

1. **Make changes to a screen**: Test in Flutter hot reload
2. **Connect to API**: Update service call
3. **Add state management**: Create Riverpod provider
4. **Commit work**: Use meaningful commit messages
5. **Document changes**: Update README if needed

## 📱 Screen Navigation Map

```
LoginScreen
    ↓
RegisterScreen ← Register link
    ↓
HomeScreen (4 tabs)
    ├── Tab 1: Home view (quick actions)
    │   ├── → "Đặt lịch mới" → DoctorSearchScreen
    │   └── → "Lọc triệu chứng AI" → TriageScreen
    ├── Tab 2: Booking view (specialties)
    │   └── → DoctorSearchScreen
    ├── Tab 3: Appointments view (list)
    │   └── → Appointment details (TBD)
    └── Tab 4: Profile view (settings)
        └── → Profile edit (TBD)

DoctorSearchScreen
    ↓
DoctorDetailScreen (date/time selection)
    ↓
Book appointment

TriageScreen
    ↓
Triage results
    ↓
Book with recommendation
```

## ✅ Ready for Next Phase

All components are ready for **Phase 2: API Integration**

### What to do next:
1. **Setup State Management**
   - Create Riverpod providers
   - Add loading/error states

2. **Integrate with Backend**
   - Update service calls
   - Handle real API responses

3. **Add Error Handling**
   - Network error dialogs
   - Form validation feedback

4. **Improve UX**
   - Loading skeletons
   - Better animations

## 📚 Resources

- [Flutter Docs](https://flutter.dev/docs)
- [Dio Docs](https://pub.dev/packages/dio)
- [GoRouter Docs](https://pub.dev/packages/go_router)
- [Riverpod Docs](https://riverpod.dev)

## 💡 Pro Tips

1. Use `flutter pub upgrade` to keep dependencies updated
2. Run `flutter analyze` to check for code issues
3. Use `flutter format .` to format code
4. Enable debug banners: `debugShowCheckedModeBanner: false` in main.dart
5. Use Flutter DevTools for performance profiling

## 🎓 Next Learning

After completing this phase:
1. Learn Riverpod state management
2. Implement provider patterns
3. Add error boundaries
4. Create custom widgets
5. Optimize performance

---

**Ready to build! 🚀**

For questions or issues, check the README files or refer to the Flutter documentation.
