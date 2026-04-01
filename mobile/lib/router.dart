import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/ai/screens/ai_triage_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/booking/screens/doctor_detail_screen.dart';
import 'features/booking/screens/doctor_hub_models.dart';
import 'features/booking/screens/home_screen.dart';

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

          return DoctorDetailScreen(doctor: doctor);
        },
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
