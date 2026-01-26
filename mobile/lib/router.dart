import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/booking/screens/home_screen.dart';
import 'features/booking/screens/doctor_search_screen.dart';
import 'features/ai_triage/screens/triage_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // Authentication Routes
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    
    // Home and Main Routes
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    
    // Booking Routes
    GoRoute(
      path: '/doctors',
      name: 'doctors',
      builder: (context, state) => const DoctorSearchScreen(),
    ),
    GoRoute(
      path: '/triage',
      name: 'triage',
      builder: (context, state) => const TriageScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Route not found: ${state.location}'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Go to Home'),
          ),
        ],
      ),
    ),
  ),
  redirect: (context, state) {
    // Handle authentication redirects if needed
    return null;
  },
);

