import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      final prefs = await _prefs();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      return;
    }

    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await _prefs();
      return prefs.getString(_accessTokenKey);
    }
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await _prefs();
      return prefs.getString(_refreshTokenKey);
    }
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final encoded = jsonEncode(user);
    if (kIsWeb) {
      final prefs = await _prefs();
      await prefs.setString(_userKey, encoded);
      return;
    }
    await _secureStorage.write(key: _userKey, value: encoded);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final userJson = kIsWeb
        ? (await _prefs()).getString(_userKey)
        : await _secureStorage.read(key: _userKey);
    if (userJson == null) return null;
    return jsonDecode(userJson) as Map<String, dynamic>;
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await _prefs();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userKey);
      return;
    }

    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _userKey),
    ]);
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
