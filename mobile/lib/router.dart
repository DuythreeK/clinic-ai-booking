import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/ai/screens/ai_triage_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/booking/screens/booking_flow_screen.dart';
import 'features/booking/screens/doctor_detail_screen.dart';
import 'features/booking/screens/doctor_hub_models.dart';
import 'features/booking/screens/home_screen.dart';
import 'features/profile/screens/personal_info_screen.dart';
import 'features/booking/screens/appointment_history_screen.dart';

GoRouter createAppRouter({
  required AuthService authService,
}) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) {
          final qp = state.uri.queryParameters;
          final requestedTab = int.tryParse(qp['tab'] ?? '') ?? 0;
          final initialTab = requestedTab.clamp(0, 2);
          final specialty = qp['specialty'];

          return HomeScreen(
            authService: authService,
            initialTab: initialTab,
            prefilledSpecialty: specialty,
          );
        },
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginScreen(authService: authService),
      ),
      GoRoute(
        path: '/home',
        name: 'home-root',
        builder: (context, state) => HomeScreen(
          authService: authService,
          initialTab: 0,
        ),
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

          if (doctor == null) {
            return const Scaffold(
              body: Center(child: Text('Doctor not found')),
            );
          }

          return DoctorDetailScreen(
            doctor: doctor,
            authService: authService,
          );
        },
      ),
      GoRoute(
        path: '/booking',
        name: 'booking',
        builder: (context, state) {
          final doctorId =
              int.tryParse(state.uri.queryParameters['doctorId'] ?? '');
          return BookingFlowScreen(
            authService: authService,
            initialDoctorId: doctorId,
          );
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'profile-edit',
        builder: (context, state) => const EditPersonalInfoScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => AppointmentHistoryScreen(
          dioClient: authService.dioClient,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
}
