import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/ai/screens/ai_triage_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/booking/screens/doctor_detail_screen.dart';
import 'features/booking/screens/doctor_hub_models.dart';
import 'features/booking/screens/home_screen.dart';
import 'features/profile/screens/personal_info_screen.dart';
// Import các file phòng khám của bạn
import 'features/clinics/screens/clinic_list_screen.dart';
import 'features/clinics/screens/clinic_detail_screen.dart';

GoRouter createAppRouter({
  required AuthService authService,
  required bool isAuthenticated,
}) {
  return GoRouter(
    initialLocation: isAuthenticated ? '/' : '/login',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) {
          final qp = state.uri.queryParameters;
          final requestedTab = int.tryParse(qp['tab'] ?? '') ?? 0;
          final specialty = qp['specialty'];
          return HomeScreen(
            authService: authService,
            initialTab: requestedTab.clamp(0, 3),
            prefilledSpecialty: specialty,
          );
        },
      ),
      // --- THÊM CÁC ROUTE PHÒNG KHÁM ---
      GoRoute(
        path: '/clinics',
        name: 'clinics',
        builder: (context, state) => const ClinicListScreen(),
      ),
      GoRoute(
        path: '/clinic-detail',
        name: 'clinic-detail',
        builder: (context, state) {
          final clinic = state.extra as dynamic; // Lấy dữ liệu clinic truyền qua extra
          return ClinicDetailScreen(clinic: clinic);
        },
      ),
      // --------------------------------
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginScreen(authService: authService),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => RegisterScreen(authService: authService),
      ),
      GoRoute(
        path: '/ai-triage',
        name: 'ai-triage',
        builder: (context, state) => AiTriageScreen(authService: authService),
      ),
      GoRoute(
        path: '/doctor/:id',
        name: 'doctor-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final doctor = DoctorCatalog.instance.findById(id);
          if (doctor == null) return const Scaffold(body: Center(child: Text('Doctor not found')));
          return DoctorDetailScreen(doctor: doctor);
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const PersonalInfoScreen(),
      ),
    ],
  );
}