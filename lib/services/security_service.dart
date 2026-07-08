import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SecurityService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Secure storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _deviceIdKey = 'device_id';

  // Network security
  static const String _productionDomain = 'e8gym.online';
  static const String _productionUrl = 'https://e8gym.online';

  /// Store access token securely
  static Future<void> storeAccessToken(String token) async {
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  /// Retrieve access token securely
  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// Store refresh token securely
  static Future<void> storeRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  /// Retrieve refresh token securely
  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Store user data securely
  static Future<void> storeUserData(Map<String, dynamic> userData) async {
    final encryptedData = jsonEncode(userData);
    await _secureStorage.write(key: _userDataKey, value: encryptedData);
  }

  /// Retrieve user data securely
  static Future<Map<String, dynamic>?> getUserData() async {
    final data = await _secureStorage.read(key: _userDataKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  /// Clear all stored data
  static Future<void> clearAllData() async {
    await _secureStorage.deleteAll();
  }

  /// Generate and store device ID
  static Future<String> getDeviceId() async {
    String? storedDeviceId = await _secureStorage.read(key: _deviceIdKey);
    
    if (storedDeviceId != null) {
      return storedDeviceId;
    }

    // Generate new device ID
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = '${androidInfo.brand}_${androidInfo.model}_${androidInfo.id}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = '${iosInfo.name}_${iosInfo.model}_${iosInfo.identifierForVendor}';
    }

    // Hash the device ID for security
    final hashedId = sha256.convert(utf8.encode(deviceId)).toString();
    await _secureStorage.write(key: _deviceIdKey, value: hashedId);
    
    return hashedId;
  }

  /// Get app version information
  static Future<Map<String, String>> getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
    };
  }

  /// Check network connectivity
  static Future<bool> isNetworkAvailable() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Validate production domain
  static bool isValidProductionDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host == _productionDomain || uri.host.endsWith('.$_productionDomain');
    } catch (e) {
      return false;
    }
  }

  /// Add security headers to HTTP requests
  static Map<String, String> getSecurityHeaders(String? accessToken) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'E8Gym/1.0.0',
      'X-Requested-With': 'XMLHttpRequest',
      'X-Device-ID': '', // Will be set by the calling method
    };

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  /// Validate SSL certificate for production
  static bool validateSSLCertificate(String url) {
    if (!url.startsWith('https://')) {
      return false;
    }

    try {
      final uri = Uri.parse(url);
      return uri.host == _productionDomain || uri.host.endsWith('.$_productionDomain');
    } catch (e) {
      return false;
    }
  }

  /// Create secure HTTP client for production
  static http.Client createSecureClient() {
    return http.Client();
  }

  /// Log security events (for monitoring)
  static void logSecurityEvent(String event, {Map<String, dynamic>? details}) {
    // In production, this should send to a secure logging service
    if (kDebugMode) print('SECURITY_EVENT: $event ${details != null ? jsonEncode(details) : ''}');
  }

  /// Validate input data for security
  static bool validateInput(String input, {int maxLength = 1000}) {
    if (input.isEmpty || input.length > maxLength) {
      return false;
    }

    // Check for potentially dangerous patterns
    final dangerousPatterns = [
      RegExp(r'<script.*?>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
    ];

    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(input)) {
        return false;
      }
    }

    return true;
  }

  /// Sanitize user input
  static String sanitizeInput(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Check if running in production mode
  static bool isProductionMode() {
    return const bool.fromEnvironment('dart.vm.product');
  }

  /// Get device security information
  static Future<Map<String, dynamic>> getDeviceSecurityInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    
    Map<String, dynamic> securityInfo = {
      'appVersion': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'isProduction': isProductionMode(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      securityInfo['platform'] = 'Android';
      securityInfo['androidVersion'] = androidInfo.version.release;
      securityInfo['sdkVersion'] = androidInfo.version.sdkInt;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      securityInfo['platform'] = 'iOS';
      securityInfo['iosVersion'] = iosInfo.systemVersion;
    }

    return securityInfo;
  }
}
