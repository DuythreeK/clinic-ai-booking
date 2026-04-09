import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/storage/auth_storage.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  final DioClient dioClient;
  final AuthStorage authStorage;
  final Logger logger = Logger();
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentUser => _currentUser;
  AuthService({
    required this.dioClient,
    required this.authStorage,
  }) {
    _initUser();
  }
  Future<void> _initUser() async {
    _currentUser = await authStorage.getUser();
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String full_name,
    required String phone,
    String role = 'patient',
  }) async {
    try {
      final response = await dioClient.post(
        '/auth/register',
        data: {
          'email': email,
          'phone': phone,
          'password': password,
          'full_name': full_name,
          'role': role.toLowerCase(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await authStorage.saveUser(
          (data['data'] as Map<String, dynamic>? ?? <String, dynamic>{}),
        );

        logger.i('✅ Registration successful');
        return data;
      }

      throw Exception('Registration failed');
    } on DioException catch (e) {
      logger.e('❌ Registration error: ${e.message}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dioClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final responseData =
            (data['data'] as Map<String, dynamic>? ?? <String, dynamic>{});

        await authStorage.saveTokens(
          accessToken: responseData['access_token'] as String,
          refreshToken: responseData['refresh_token'] as String,
        );
        final userMap = {
          'user_id': responseData['user_id'],
          'email': email,
          'full_name': responseData['full_name'] ?? responseData['user']?['full_name'],
        };
        await authStorage.saveUser(userMap);
        _currentUser = userMap;

        logger.i('✅ Login successful');
        return data;
      }

      throw Exception('Login failed');
    } on DioException catch (e) {
      logger.e('❌ Login error: ${e.message}');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await dioClient.post('/auth/logout');

      await authStorage.clear();
      logger.i('✅ Logout successful');
    } catch (e) {
      logger.e('❌ Logout error: $e');
      // Clear local data anyway
      await authStorage.clear();
    }
  }

  Future<bool> isAuthenticated() async {
    return await authStorage.isAuthenticated();
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await authStorage.getUser();
  }

  Future<String?> getCurrentUserRole() async {
    final user = await authStorage.getUser();
    final existingRole = user?['role']?.toString();
    if (existingRole != null && existingRole.isNotEmpty) {
      return existingRole;
    }

    final token = await authStorage.getAccessToken();
    final role = _extractRoleFromJwt(token);
    if (role != null) {
      await authStorage.saveUser({
        ...(user ?? <String, dynamic>{}),
        'role': role,
      });
    }
    return role;
  }

  String? _extractRoleFromJwt(String? token) {
    if (token == null || token.trim().isEmpty) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload);
      if (map is Map<String, dynamic>) {
        final role = map['role']?.toString();
        if (role != null && role.isNotEmpty) {
          return role;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
