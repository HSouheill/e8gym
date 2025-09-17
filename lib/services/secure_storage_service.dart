import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_models.dart';
import '../utils/secure_logger.dart';

class SecureStorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Initialize the secure storage service
  static Future<void> init() async {
    try {
      // Test secure storage availability
      await _secureStorage.containsKey(key: 'test_key');
      SecureLogger.debug('Secure storage initialized successfully');
    } catch (e) {
      SecureLogger.error('Failed to initialize secure storage', error: e);
      rethrow;
    }
  }

  /// Save authentication tokens securely
  static Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      await _secureStorage.write(key: _isLoggedInKey, value: 'true');
      
      SecureLogger.debug('Auth tokens saved securely', data: {
        'access_token_length': accessToken.length,
        'refresh_token_length': refreshToken.length,
      });
    } catch (e) {
      SecureLogger.error('Failed to save auth tokens', error: e);
      rethrow;
    }
  }

  /// Get access token securely
  static Future<String?> getAccessToken() async {
    try {
      final token = await _secureStorage.read(key: _accessTokenKey);
      SecureLogger.debug('Access token retrieved', data: {'has_token': token != null});
      return token;
    } catch (e) {
      SecureLogger.error('Failed to get access token', error: e);
      return null;
    }
  }

  /// Get refresh token securely
  static Future<String?> getRefreshToken() async {
    try {
      final token = await _secureStorage.read(key: _refreshTokenKey);
      SecureLogger.debug('Refresh token retrieved', data: {'has_token': token != null});
      return token;
    } catch (e) {
      SecureLogger.error('Failed to get refresh token', error: e);
      return null;
    }
  }

  /// Save user data securely
  static Future<void> saveUserData(UserResponse user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _secureStorage.write(key: _userDataKey, value: userJson);
      
      SecureLogger.debug('User data saved securely', data: {
        'user_id': user.id,
        'email': user.email,
      });
    } catch (e) {
      SecureLogger.error('Failed to save user data', error: e);
      rethrow;
    }
  }

  /// Get user data securely
  static Future<UserResponse?> getUserData() async {
    try {
      final userJson = await _secureStorage.read(key: _userDataKey);
      
      if (userJson != null) {
        try {
          final userMap = jsonDecode(userJson) as Map<String, dynamic>;
          final user = UserResponse.fromJson(userMap);
          
          SecureLogger.debug('User data retrieved securely', data: {
            'user_id': user.id,
            'email': user.email,
          });
          
          return user;
        } catch (e) {
          SecureLogger.error('Failed to parse user data', error: e);
          // Remove corrupted data
          await _secureStorage.delete(key: _userDataKey);
          return null;
        }
      }
      
      SecureLogger.debug('No user data found');
      return null;
    } catch (e) {
      SecureLogger.error('Failed to get user data', error: e);
      return null;
    }
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final isLoggedIn = await _secureStorage.read(key: _isLoggedInKey);
      return isLoggedIn == 'true';
    } catch (e) {
      SecureLogger.error('Failed to check login status', error: e);
      return false;
    }
  }

  /// Clear all authentication data securely
  static Future<void> clearAuthData() async {
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userDataKey);
      await _secureStorage.delete(key: _isLoggedInKey);
      
      SecureLogger.debug('Auth data cleared securely');
    } catch (e) {
      SecureLogger.error('Failed to clear auth data', error: e);
      rethrow;
    }
  }

  /// Update access token securely (for refresh token flow)
  static Future<void> updateAccessToken(String newAccessToken) async {
    try {
      await _secureStorage.write(key: _accessTokenKey, value: newAccessToken);
      SecureLogger.debug('Access token updated securely');
    } catch (e) {
      SecureLogger.error('Failed to update access token', error: e);
      rethrow;
    }
  }

  /// Store any secure data
  static Future<void> storeSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      SecureLogger.debug('Secure data stored', data: {'key': key});
    } catch (e) {
      SecureLogger.error('Failed to store secure data', error: e);
      rethrow;
    }
  }

  /// Retrieve any secure data
  static Future<String?> getSecureData(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      SecureLogger.debug('Secure data retrieved', data: {'key': key, 'has_value': value != null});
      return value;
    } catch (e) {
      SecureLogger.error('Failed to get secure data', error: e);
      return null;
    }
  }

  /// Delete any secure data
  static Future<void> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
      SecureLogger.debug('Secure data deleted', data: {'key': key});
    } catch (e) {
      SecureLogger.error('Failed to delete secure data', error: e);
      rethrow;
    }
  }

  /// Check if secure data exists
  static Future<bool> containsKey(String key) async {
    try {
      return await _secureStorage.containsKey(key: key);
    } catch (e) {
      SecureLogger.error('Failed to check key existence', error: e);
      return false;
    }
  }

  /// Get all stored keys (for debugging purposes only)
  static Future<Map<String, String>> getAllKeys() async {
    try {
      return await _secureStorage.readAll();
    } catch (e) {
      SecureLogger.error('Failed to get all keys', error: e);
      return {};
    }
  }
}
