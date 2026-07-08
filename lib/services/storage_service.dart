import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import '../utils/secure_logger.dart';
import 'secure_storage_service.dart';
import 'auth_service.dart';

class StorageService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _tokenExpiryKey = 'token_expiry';

  // How long before the recorded expiry we proactively refresh the token.
  static const Duration _refreshBuffer = Duration(seconds: 30);

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
    int? expiresIn,
  }) async {
    // Use secure storage for sensitive data
    await SecureStorageService.saveAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    // Keep non-sensitive login status in shared preferences for quick access
    await _prefs.setBool(_isLoggedInKey, true);
    await _saveTokenExpiry(expiresIn);
  }

  Future<void> _saveTokenExpiry(int? expiresIn) async {
    if (expiresIn == null) {
      await _prefs.remove(_tokenExpiryKey);
      return;
    }
    final expiry = DateTime.now().add(Duration(seconds: expiresIn));
    await _prefs.setString(_tokenExpiryKey, expiry.toIso8601String());
  }

  /// Get access token (from secure storage), refreshing it first if it has
  /// expired or is about to expire. Falls back to the (possibly stale)
  /// cached token if a refresh isn't possible or fails, so callers can still
  /// surface the resulting 401 to the user instead of getting stuck with no
  /// token at all.
  Future<String?> getAccessToken() async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null) return null;

    final expiryString = _prefs.getString(_tokenExpiryKey);
    if (expiryString == null) return token;

    final expiry = DateTime.tryParse(expiryString);
    if (expiry == null || DateTime.now().isBefore(expiry.subtract(_refreshBuffer))) {
      return token;
    }

    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return token;

    try {
      final refreshed = await AuthService().refreshToken(refreshToken);
      await updateAccessToken(refreshed.accessToken, expiresIn: refreshed.expiresIn);
      SecureLogger.debug('Access token proactively refreshed');
      return refreshed.accessToken;
    } catch (e) {
      SecureLogger.error('Proactive token refresh failed', error: e);
      return token;
    }
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
    await _prefs.remove(_tokenExpiryKey);
  }

  /// Update access token (for refresh token flow) - uses secure storage
  Future<void> updateAccessToken(String newAccessToken, {int? expiresIn}) async {
    await SecureStorageService.updateAccessToken(newAccessToken);
    await _saveTokenExpiry(expiresIn);
  }
}
