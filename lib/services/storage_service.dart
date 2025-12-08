import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import '../utils/secure_logger.dart';
import 'secure_storage_service.dart';

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
    await SecureStorageService.init();
    SecureLogger.debug('Storage service initialized with both secure and shared preferences');
  }

  /// Save authentication tokens (uses secure storage)
  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    // Use secure storage for sensitive data
    await SecureStorageService.saveAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    
    // Keep non-sensitive login status in shared preferences for quick access
    await _prefs.setBool(_isLoggedInKey, true);
  }

  /// Get access token (from secure storage)
  Future<String?> getAccessToken() async {
    return await SecureStorageService.getAccessToken();
  }

  /// Get refresh token (from secure storage)
  Future<String?> getRefreshToken() async {
    return await SecureStorageService.getRefreshToken();
  }

  /// Save user data (uses secure storage)
  Future<void> saveUserData(UserResponse user) async {
    await SecureStorageService.saveUserData(user);
  }

  /// Get user data (from secure storage)
  Future<UserResponse?> getUserData() async {
    return await SecureStorageService.getUserData();
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Clear all authentication data (from both secure and shared storage)
  Future<void> clearAuthData() async {
    await SecureStorageService.clearAuthData();
    await _prefs.setBool(_isLoggedInKey, false);
  }

  /// Update access token (for refresh token flow) - uses secure storage
  Future<void> updateAccessToken(String newAccessToken) async {
    await SecureStorageService.updateAccessToken(newAccessToken);
  }
}
