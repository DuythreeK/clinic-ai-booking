import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/booking/screens/home_screen.dart';
import '../features/clinics/screens/clinic_list_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/', // Mặc định mở Home

  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login-root',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/clinics',
      builder: (context, state) => const ClinicListScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Text('Route not found: ${state.uri.toString()}'),
    ),
  ),
);
