import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/storage/auth_storage.dart';

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
    required String fullName,
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
          'full_name': fullName,
          'role': role,
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
        await authStorage.saveUser({
          'user_id': responseData['user_id'],
          'email': email,
        });

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
}
