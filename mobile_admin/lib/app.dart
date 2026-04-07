import 'package:flutter/material.dart';

import 'features/auth/data/admin_auth_service.dart';
import 'features/auth/domain/admin_session_user.dart';
import 'features/auth/presentation/admin_login_screen.dart';
import 'features/home/presentation/admin_patients_root_shell.dart';
import 'theme/admin_app_theme.dart';

class MobileAdminApp extends StatefulWidget {
  const MobileAdminApp({super.key});

  @override
  State<MobileAdminApp> createState() => _MobileAdminAppState();
}

class _MobileAdminAppState extends State<MobileAdminApp> {
  late final AdminAuthService _authService;
  AdminSessionUser? _currentUser;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _authService = AdminAuthService();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final user = await _authService.restoreSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _currentUser = user;
      _isCheckingSession = false;
    });
  }

  void _handleLoggedIn(AdminSessionUser user) {
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isCheckingSession = true;
    });

    await _authService.logout();
    if (!mounted) {
      return;
    }

    setState(() {
      _currentUser = null;
      _isCheckingSession = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminAppTheme.light(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        child: _buildHome(),
      ),
    );
  }

  Widget _buildHome() {
    if (_isCheckingSession) {
      return const _AdminLaunchScreen(key: ValueKey('admin-launch'));
    }

    if (_currentUser == null) {
      return AdminLoginScreen(
        key: const ValueKey('admin-login'),
        authService: _authService,
        onLoggedIn: _handleLoggedIn,
      );
    }

    return AdminPatientsRootShell(
      key: const ValueKey('admin-shell'),
      currentUser: _currentUser!,
      onLogout: _handleLogout,
      initialIndex: 0,
    );
  }
}

class _AdminLaunchScreen extends StatelessWidget {
  const _AdminLaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: Center(child: CircularProgressIndicator())),
    );
  }
}
