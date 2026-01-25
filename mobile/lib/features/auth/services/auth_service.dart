import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../../core/api/dio_client.dart';
import '../../core/storage/auth_storage.dart';

class AuthService {
  final DioClient dioClient;
  final AuthStorage authStorage;
  final Logger logger = Logger();

  AuthService({
    required this.dioClient,
    required this.authStorage,
  });

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      final response = await dioClient.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        await authStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        await authStorage.saveUser(data['user']);

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
        final data = response.data;
        await authStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        await authStorage.saveUser(data['user']);

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
      final refreshToken = await authStorage.getRefreshToken();

      if (refreshToken != null) {
        await dioClient.post(
          '/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      }

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
}
