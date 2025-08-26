import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

class StorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  /// Initialize the storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save authentication tokens
  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    await _prefs.setBool(_isLoggedInKey, true);
  }

  /// Get access token
  String? getAccessToken() {
    return _prefs.getString(_accessTokenKey);
  }

  /// Get refresh token
  String? getRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  /// Save user data
  Future<void> saveUserData(UserResponse user) async {
    try {
      final userJson = jsonEncode(user);
      print('Saving user data: $userJson'); // Debug log
      await _prefs.setString(_userDataKey, userJson);
      print('User data saved successfully'); // Debug log
    } catch (e) {
      print('Error saving user data: $e'); // Debug log
      rethrow;
    }
  }

  /// Get user data
  UserResponse? getUserData() {
    try {
      final userJson = _prefs.getString(_userDataKey);
      print('Retrieved user data JSON: $userJson'); // Debug log
      
      if (userJson != null) {
        try {
          final userMap = jsonDecode(userJson) as Map<String, dynamic>;
          print('Parsed user map: $userMap'); // Debug log
          return UserResponse.fromJson(userMap);
        } catch (e) {
          print('Error parsing user data: $e'); // Debug log
          // If parsing fails, remove the corrupted data
          _prefs.remove(_userDataKey);
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e'); // Debug log
      return null;
    }
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Clear all authentication data
  Future<void> clearAuthData() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userDataKey);
    await _prefs.setBool(_isLoggedInKey, false);
  }

  /// Update access token (for refresh token flow)
  Future<void> updateAccessToken(String newAccessToken) async {
    await _prefs.setString(_accessTokenKey, newAccessToken);
  }
}
