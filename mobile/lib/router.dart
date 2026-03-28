import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/auth/services/auth_service.dart';
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
        builder: (context, state) => HomeScreen(authService: authService),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginScreen(authService: authService),
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
