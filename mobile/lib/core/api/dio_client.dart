import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class TokenInterceptor extends Interceptor {
  final FlutterSecureStorage secureStorage;
  final Dio dio;
  final Logger logger = Logger();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  TokenInterceptor({
    required this.secureStorage,
    required this.dio,
  });

  Future<String?> _readToken(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
    return secureStorage.read(key: key);
  }

  Future<void> _writeToken(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      return;
    }
    await secureStorage.write(key: key, value: value);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Keep requests relative so Dio preserves `/api` from baseUrl.
    if (!options.path.startsWith('http')) {
      options.path = options.path.replaceFirst(RegExp(r'^/+'), '');
    }

    final accessToken = await _readToken(_accessTokenKey);

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    logger.i('🔹 API Request: ${options.method} ${options.uri}');
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestPath = err.requestOptions.path.toLowerCase();
    final isAuthEndpoint = requestPath.contains('/auth/login') ||
        requestPath.contains('/auth/register') ||
        requestPath.contains('/auth/refresh');
    final hadAccessToken = (err.requestOptions.headers['Authorization']
                ?.toString()
                .isNotEmpty ??
            false) ||
        ((await _readToken(_accessTokenKey))?.isNotEmpty ?? false);

    if (err.response?.statusCode == 401 && !isAuthEndpoint && hadAccessToken) {
      logger.w('🔄 Token expired, attempting refresh...');

      try {
        final refreshToken = await _readToken(_refreshTokenKey);

        if (refreshToken == null) {
          logger.e('❌ No refresh token available');
          return handler.next(err);
        }

        final refreshResponse = await dio.post(
          '$baseUrl/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        if (refreshResponse.statusCode == 200) {
          final responseData =
              refreshResponse.data['data'] as Map<String, dynamic>?;
          final newAccessToken = responseData?['access_token'] as String?;

          if (newAccessToken == null || newAccessToken.isEmpty) {
            return handler.next(err);
          }

          await _writeToken(_accessTokenKey, newAccessToken);
          logger.i('✅ Token refreshed successfully');

          // Retry original request with new token
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await dio.request<dynamic>(
            opts.path,
            data: opts.data,
            queryParameters: opts.queryParameters,
            options: Options(
              method: opts.method,
              headers: opts.headers,
            ),
          );

          return handler.resolve(Response(
            data: retryResponse.data,
            statusCode: retryResponse.statusCode,
            requestOptions: opts,
            headers: retryResponse.headers,
          ));
        }
      } catch (e) {
        logger.e('❌ Token refresh failed: $e');
      }
    }

    logger.e(
      '❌ API Error [${err.response?.statusCode ?? 'no-status'}] '
      '${err.requestOptions.method} ${err.requestOptions.uri} - ${err.message}',
    );
    return handler.next(err);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    logger.i('🔹 API Response: ${response.statusCode}');
    return handler.next(response);
  }
}

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage secureStorage;

  String _normalizePath(String path) {
    if (path.startsWith('/')) {
      return path.substring(1);
    }
    return path;
  }

  DioClient({FlutterSecureStorage? secureStorage})
      : secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '$baseUrl/',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    // Add interceptors
    _dio.interceptors.add(TokenInterceptor(
      secureStorage: this.secureStorage,
      dio: _dio,
    ));

    // Retry interceptor
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
        logPrint: print,
      ),
    );
  }

  Dio get dio => _dio;

  // Helper methods
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      _normalizePath(path),
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      _normalizePath(path),
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.put<T>(
      _normalizePath(path),
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.patch<T>(
      _normalizePath(path),
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      _normalizePath(path),
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
